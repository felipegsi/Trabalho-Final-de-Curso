// assign_driver_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../../../models/driver.dart';
import '../../../models/order.dart';

class SearchingDriverScreen extends StatefulWidget {
  final int orderId;

  const SearchingDriverScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _SearchingDriverScreenState createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  late GoogleMapController mapController;
  Driver? assignedDriver;
  bool isLoading = true;

  // Coordenadas iniciais para o mapa (substitua pelas coordenadas reais)
  final LatLng initialLocation = LatLng(-23.5505, -46.6333);

  @override
  void initState() {
    super.initState();
    _assignOrderToDriver();
  }

  Future<void> _assignOrderToDriver() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    try {
      Driver driver = await orderApi.assignOrderToDriver(widget.orderId);
      setState(() {
        assignedDriver = driver;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Failed to assign order to driver: $error');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Driver'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: initialLocation,
              zoom: 12.0,
            ),
            markers: _buildMarkers(),
          ),
          if (isLoading) Center(child: CircularProgressIndicator()),
          if (assignedDriver != null) _buildDriverInfo(),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    if (assignedDriver != null) {
      markers.add(Marker(
        markerId: MarkerId('driver'),
        position: LatLng(
          //colocar qualquer uma pois o driver nao tem latitude e longitude por enquanto
//          assignedDriver!.latitude,
//          assignedDriver!.longitude,
          -23.5505,
          -46.6333,
        ),
        infoWindow: InfoWindow(
          title: 'Driver: ${assignedDriver!.name}',
          snippet: 'Vehicle: ${assignedDriver!.vehicle}',
        ),
      ));
    }
    // Adicione outros marcadores se necessário
    return markers;
  }

  Widget _buildDriverInfo() {
    return Positioned(
      bottom: 20.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${assignedDriver!.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Vehicle: ${assignedDriver!.vehicle}', style: TextStyle(fontSize: 14)),
            Text('Distance: 5.2 km', style: TextStyle(fontSize: 14)), // Substitua pela distância real
          ],
        ),
      ),
    );
  }
}
