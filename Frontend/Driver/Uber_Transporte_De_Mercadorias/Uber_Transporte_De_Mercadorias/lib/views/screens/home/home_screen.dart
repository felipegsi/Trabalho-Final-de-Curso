import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../services/network_service.dart';
import 'menu_drawer.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LatLng defaultPoint = const LatLng(38.758072, -9.153414);
  bool isOnline = false; // Estado para gerenciar o status online/offline
  final NetworkService _networkService = NetworkService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<String> _getCurrentLocation() async {
    try {
      // Solicita permissão para acessar a localização do dispositivo
      LocationPermission permission = await Geolocator.requestPermission();

      // Verifica se a permissão foi concedida
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }

      // Obtém a localização atual
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Retorna a localização como uma string (latitude, longitude)
      return "${position.latitude},${position.longitude}";
    } catch (e) {
      print('Failed to get location: $e');
      throw e; // Lança uma exceção se houver um erro ao obter a localização
    }
  }

  void _toggleOnlineStatus() async {
    if (isOnline) {
      bool success = await _networkService.setDriverOffline();
      setState(() {
        isOnline = !success;  // Muda o estado apenas se a operação falhar.
        _showSnackBar(success ? 'You are now offline.' : 'Failed to go offline.');
      });
    } else {
      String location = await _getCurrentLocation();
      if (location.isNotEmpty) {
        bool success = await _networkService.setDriverOnline(location);
        setState(() {
          isOnline = success;  // Muda o estado apenas se a operação for bem-sucedida.
          _showSnackBar(success ? 'You are now online.' : 'Failed to go online.');
        });
      }
    }
  }


  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: defaultPoint,
              zoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.driverapp',
              ),
            ],
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
                      title: Text(isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                              color: isOnline ? Colors.green : Colors.red)),
                      value: isOnline,
                      onChanged: (bool value) {
                        _toggleOnlineStatus();
                      },
                      secondary: Icon(
                          isOnline ? Icons.cloud_done : Icons.cloud_off,
                          color: isOnline ? Colors.green : Colors.red),
                    ),
                    Text(isOnline
                        ? 'You are online. Ready to accept rides!'
                        : 'You are offline. Tap to go online.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: MenuDrawer(),
    );
  }
}
