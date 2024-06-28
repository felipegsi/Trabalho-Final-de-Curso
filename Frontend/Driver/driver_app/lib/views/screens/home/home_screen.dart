import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../../../api/profile_api.dart';
import '../accept_order/heading_pickup_screen.dart';
import 'menu_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final LatLng defaultPoint = const LatLng(38.758072, -9.153414);
  bool isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(38.758072, -9.153414);
  Future<String>? _driverSalaryFuture;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initializeOnlineStatus();
    _setupWebSocket();
    _driverSalaryFuture = getDriverSalary();
  }

  Future<void> _initializeOnlineStatus() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    try {
      bool isOnline = await orderApi.fetchDriverStatus();
      orderApi.setOnlineStatus(isOnline);
      if (isOnline) {
        String location = "${_currentLocation.latitude},${_currentLocation.longitude}";
        orderApi.setDriverOnline(location);
      }
    } catch (e) {
      _showSnackBar('Failed to fetch online status: $e');
    } finally {
      setState(() {
        isLoading = false;
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
      isLoading = true;
    });

    try {
      if (orderApi.isTogglingStatus) {
        _showSnackBar('Operation in progress. Please wait.');
        return;
      }

      if (orderApi.isOnline) {
        bool success = await orderApi.setDriverOffline();
        await Future.delayed(const Duration(seconds: 4));
        _showSnackBar(success ? 'You are now offline.' : 'Failed to go offline.');
      } else {
        String location = "${_currentLocation.latitude},${_currentLocation.longitude}";
        bool success = await orderApi.setDriverOnline(location);
        await Future.delayed(const Duration(seconds: 4));
        _showSnackBar(success ? 'You are now online.' : 'Failed to go online.');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> _getAddressFromLatLng(String coordinates) async {
    final apiKey = 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$coordinates&key=$apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return data['results'][0]['formatted_address'];
      } else {
        return 'No results found';
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  Widget _getCategoryIcon(String? category) {
    switch (category) {
      case 'SMALL':
        return Icon(Icons.motorcycle, color: Colors.white);
      case 'MEDIUM':
        return Icon(Icons.directions_car, color: Colors.white);
      case 'LARGE':
        return Icon(Icons.local_shipping, color: Colors.white);
      case 'MOTORIZED':
        return Icon(Icons.train_outlined, color: Colors.white);
      default:
        return Icon(Icons.help_outline, color: Colors.white);
    }
  }

  void _showOrderPopup(String message) async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    final orderId = orderApi.orderId;
    await orderApi.getOrderById(int.parse(orderId!));
    final order = orderApi.order;
    String address = 'Fetching address...';

    if (order?.origin != null) {
      address = await _getAddressFromLatLng(order!.origin!);
    }

    if (!mounted) return;

    if (ModalRoute.of(context)?.isCurrent == true) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: _getCategoryIcon(order?.category),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Order',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${order?.category} - ${order?.status}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Text(
                          '4.78',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'Pickup from',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  address,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await _respondToOrder('sim');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeadingPickupScreen(orderId: int.parse(orderId)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('ACCEPT', style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _respondToOrder('não');
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('REJECT', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
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

  Future<String> getDriverSalary() async {
    final profileApi = Provider.of<ProfileApi>(context, listen: false);
    return await profileApi.getDriverSalary();
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
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: FloatingActionButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              backgroundColor: Colors.white,
              child: const Icon(Icons.menu, color: Colors.black),
            ),
          ),
          Positioned(
            // Colocar o botão de navegação um pouco abaixo da metade do mapa
            bottom: MediaQuery.of(context).size.height * 0.17,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: () {
                _determinePosition();
              },
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.03,
            left: 20,
            right: 20,
            child: Card(
              color: Colors.white,
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        orderProvider.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: orderProvider.isOnline ? Colors.green : Colors.red,
                        ),
                      ),
                      value: orderProvider.isOnline,
                      onChanged: isLoading ? null : (bool value) {
                        _toggleOnlineStatus();
                      },
                      secondary: Icon(
                        orderProvider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: orderProvider.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      orderProvider.isOnline
                          ? 'You are online. Ready to accept rides!'
                          : 'You are offline. Tap to go online.',
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: FutureBuilder<String>(
                future: _driverSalaryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    double salary = double.tryParse(snapshot.data ?? '0') ?? 0;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '€${salary.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      drawer: const MenuDrawer(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
