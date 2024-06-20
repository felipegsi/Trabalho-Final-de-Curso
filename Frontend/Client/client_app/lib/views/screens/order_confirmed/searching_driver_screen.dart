// searching_driver_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../api/location_api.dart';
import '../../../api/order_api.dart';
import '../../../models/driver.dart';
import '../../../models/order.dart';

class SearchingDriverScreen extends StatefulWidget {
  final Order order;

  const SearchingDriverScreen({Key? key, required this.order}) : super(key: key);

  @override
  _SearchingDriverScreenState createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  late GoogleMapController mapController;
  Driver? assignedDriver;
  bool isLoading = true;

  late LatLng initialLocation;
  double? _distance;

  @override
  void initState() {
    super.initState();
    initialLocation = _convertToLatLng(widget.order.origin);
    _assignOrderToDriver();
  }

  Future<void> _assignOrderToDriver() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    final locationService = Provider.of<LocationApi>(context, listen: false);
    try {
      setState(() {
        isLoading = true;
      });

      Driver driver = await orderApi.assignOrderToDriver(widget.order.id!);

      // Fetch distance in a separate method to ensure it's executed asynchronously
      await _fetchDistanceAndUpdateUI(driver);

      _moveCameraToDriver(driver);

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

  Future<void> _fetchDistanceAndUpdateUI(Driver driver) async {
    final locationService = Provider.of<LocationApi>(context, listen: false);
    double distance = await locationService.fetchDistance(
      _convertToLatLng(widget.order.origin),
      _convertToLatLng(driver.location),
    );
    setState(() {
      _distance = distance;
    });
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

  LatLng _convertToLatLng(String coordinates) {
    List<String> coords = coordinates.split(',');
    return LatLng(double.parse(coords[0]), double.parse(coords[1]));
  }

  void _moveCameraToDriver(Driver driver) {
    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          _convertToLatLng(driver.location),
          15.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Searching Driver'),
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
        position: _convertToLatLng(assignedDriver!.location),
        infoWindow: InfoWindow(
          title: 'Driver: ${assignedDriver!.name}',
          snippet: 'Vehicle: ${assignedDriver!.vehicle}',
        ),
      ));
    }

    // Add other markers if needed

    return markers;
  }

  Widget _buildDriverInfo() {
    return Positioned(
      bottom: 30.0,
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
            Text('Vehicle: ${assignedDriver!.vehicle.model} ${assignedDriver!.vehicle.brand}', style: TextStyle(fontSize: 14)),
            Text('Plate: ${assignedDriver!.vehicle.plate}', style: TextStyle(fontSize: 14)),
            if (_distance != null)
              Text('Distance: ${_distance!.toStringAsFixed(2)} km', style: TextStyle(fontSize: 14)), // Mostre a distância calculada
          ],
        ),
      ),
    );
  }
}
