// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../accept_order/heading_pickup_screen.dart';
import 'menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng defaultPoint = const LatLng(38.758072, -9.153414);
  bool isLoading = false; // Estado para gerenciar o carregamento
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(38.758072, -9.153414); // Inicialmente definida como defaultPoint

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initializeOnlineStatus(); // Inicializa o estado online/offline
    _setupWebSocket();
  }

  Future<void> _initializeOnlineStatus() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    setState(() {
      isLoading = true; // Inicia o carregamento
    });
    try {
      bool isOnline = await orderApi.fetchDriverStatus(); // Verifica o status online do motorista
      orderApi.setOnlineStatus(isOnline);
      if (isOnline) {
        orderApi.connectStompClient(); // Conecta ao WebSocket se estiver online
      }
    } catch (e) {
      _showSnackBar('Failed to fetch online status: $e');
    } finally {
      setState(() {
        isLoading = false; // Conclui o carregamento
      });
    }
  }

  void _setupWebSocket() {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    orderApi.onNewOrder = (message) {
      _showOrderPopup(message);
    };
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          _showSnackBar('Location permissions are denied.');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 15),
      );
    } catch (e) {
      _showSnackBar('Failed to get location: $e');
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    setState(() {
      isLoading = true; // Inicia o carregamento
    });

    try {
      if (orderApi.isOnline) {
        bool success = await orderApi.setDriverOffline();
        _showSnackBar(success ? 'You are now offline.' : 'Failed to go offline.');
        if (success) {
          orderApi.disconnectStompClient(); // Desconecta do WebSocket
        }
      } else {
        String location = "${_currentLocation.latitude},${_currentLocation.longitude}";
        bool success = await orderApi.setDriverOnline(location);
        _showSnackBar(success ? 'You are now online.' : 'Failed to go online.');
        if (success) {
          orderApi.connectStompClient(); // Conecta ao WebSocket
        }
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        isLoading = false; // Conclui o carregamento
      });
    }
  }

  void _showOrderPopup(String message) {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    final orderId = orderApi.currentOrderId; // Obtém o ID do pedido

    if (!mounted) return;

    if (ModalRoute.of(context)?.isCurrent == true && orderId != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Nova Mensagem'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  await _respondToOrder('sim');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HeadingPickupScreen(orderId: int.parse(orderId)), // Passa o ID do pedido
                    ),
                  );
                },
                child: const Text('Aceitar'),
              ),
              TextButton(
                onPressed: () async {
                  await _respondToOrder('não');
                  Navigator.of(context).pop();
                },
                child: const Text('Rejeitar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _respondToOrder(String response) async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    orderApi.sendResponse(response);
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderApi>(context);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != defaultPoint) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation, 15),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: FloatingActionButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              backgroundColor: Colors.black,
              child: const Icon(Icons.menu, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(orderProvider.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                              color: orderProvider.isOnline ? Colors.green : Colors.red)),
                      value: orderProvider.isOnline,
                      onChanged: isLoading ? null : (bool value) {
                        _toggleOnlineStatus();
                      },
                      secondary: Icon(
                          orderProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: orderProvider.isOnline ? Colors.green : Colors.red),
                    ),
                    Text(orderProvider.isOnline
                        ? 'You are online. Ready to accept rides!'
                        : 'You are offline. Tap to go online.'),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading) // Indicador de carregamento
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      drawer: const MenuDrawer(),
    );
  }

  @override
  void dispose() {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    orderApi.disconnectStompClient();
    super.dispose();
  }
}
