import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapSample extends StatefulWidget {
  @override
  _MapSampleState createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<LatLng> _routePoints = [];
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    _initializeRoute(); // Initialize the predefined route
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        LatLng newPosition = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPosition;
        });
        _updateCameraPosition(newPosition);
        _addCurrentPositionToRoute(newPosition);
      });
    } else {
      print("Permissão de localização negada");
    }
  }

  void _initializeRoute() {
    // Exemplo de pontos de uma rota predefinida
    _routePoints = [
      LatLng(-23.561684, -46.625378),
      LatLng(-23.563210, -46.623441),
      LatLng(-23.565014, -46.621877),
      LatLng(-23.566896, -46.620421),
      // Adicione mais pontos conforme necessário
    ];

    setState(() {
      _polylines.add(Polyline(
        polylineId: PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 5,
      ));
    });
  }

  void _updateCameraPosition(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  void _addCurrentPositionToRoute(LatLng position) {
    setState(() {
      _routePoints.add(position);
      _polylines = {
        Polyline(
          polylineId: PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Follow Route Mode"),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        polylines: _polylines,
      ),
    );
  }
}


