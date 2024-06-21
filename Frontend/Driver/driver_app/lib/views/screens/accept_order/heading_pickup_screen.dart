// heading_pickup_screen.dart
import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_proj/services/location_service.dart';
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../../../models/order.dart';

class HeadingPickupScreen extends StatefulWidget {
  final int orderId;

  const HeadingPickupScreen({
    super.key,
    required this.orderId,
  });

  @override
  _HeadingPickupScreenState createState() => _HeadingPickupScreenState();
}

class _HeadingPickupScreenState extends State<HeadingPickupScreen> {
  GoogleMapController? mapController;
  List<LatLng> points = [];
  bool isLoading = false;
  LatLng? _currentLocation;
  Marker? originMarker;
  Marker? destinationMarker;
  double distance = 0.0; // To hold the distance value

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _determinePosition();
    if (_currentLocation != null) {
      final order = await _loadOrder(widget.orderId);
      _initializeMapMarkers(order);
      await getRoute(parseLatLng(order.origin));
    }
  }

  Future<void> _determinePosition() async {
    LocationService location = LocationService();
    _currentLocation = await location.determinePosition();
  }

  LatLng parseLatLng(String coordinate) {
    List<String> coordinates = coordinate.split(',');
    double latitude = double.parse(coordinates[0]);
    double longitude = double.parse(coordinates[1]);
    return LatLng(latitude, longitude);
  }

  Future<void> getRoute(LatLng origin) async {
    if (_currentLocation == null) return;

    setState(() => isLoading = true);

    final String apiKey = 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik'; // Substitua pela sua chave de API do Google
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${origin.latitude},${origin.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['routes'].isEmpty) {
        throw Exception('No routes found');
      }

      final String encodedPolyline =
      jsonResponse['routes'][0]['overview_polyline']['points'];

      // Decodifica a polilinha para uma lista de coordenadas
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> decodedPoints =
      polylinePoints.decodePolyline(encodedPolyline);

      // Calcula a distância
      distance = jsonResponse['routes'][0]['legs'][0]['distance']['value'] / 1000;

      setState(() {
        points = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        isLoading = false;
        //adjustMapZoom();
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  void adjustMapZoom() {
    if (mapController != null && points.isNotEmpty) {
      LatLngBounds bounds;
      if (points.length == 1) {
        bounds = LatLngBounds(
          southwest: LatLng(
              points.first.latitude - 0.01, points.first.longitude - 0.01),
          northeast: LatLng(
              points.first.latitude + 0.01, points.first.longitude + 0.01),
        );
      } else {
        bounds = LatLngBounds(
          southwest: points.reduce((a, b) => LatLng(
              a.latitude < b.latitude ? a.latitude : b.latitude,
              a.longitude < b.longitude ? a.longitude : b.longitude)),
          northeast: points.reduce((a, b) => LatLng(
              a.latitude > b.latitude ? a.latitude : b.latitude,
              a.longitude > b.longitude ? a.longitude : b.longitude)),
        );
      }

      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }


  Future<Order> _loadOrder(int orderId) async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    return await orderApi.getOrderById(orderId);
  }

  void _initializeMapMarkers(Order order) {
    final origin = parseLatLng(order.origin);

    originMarker = Marker(
      markerId: const MarkerId('origin'),
      position: _currentLocation!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: origin,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heading to Pickup'),
      ),
      body: FutureBuilder<Order>(
        future: _loadOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Order not found.'));
          } else {
            final order = snapshot.data!;
            return Stack(
              children: [
                buildMap(),
                buildMenu(order),
                buildButton(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildButton(){
    return ElevatedButton(
      onPressed: () {
        adjustMapZoom();
      },
      child: const Text('Zoom'),
    );
  }

  Widget buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
        //adjustMapZoom();
      },
      //TODO: MOSTRAR PARA A BETA OS EFEITOS SE AUMENTAR OU DIMINUIR O ZOOM
      initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(0, 0), zoom: 17.0),
      markers: {if (destinationMarker != null) destinationMarker!},
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      polylines: {
        if (points.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 4,
          ),
      },
    );
  }

  Widget buildMenu(Order order) {
    return Positioned(
      bottom: 30.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child:Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            /*ListTile(  TODO: AQUI PODERIA COLOCAR UMA MENSAGEM TOAST INDICANDO O VALOR DA ENTREGA
              leading: getCategoryIcon(order.category),
              title: Text(order.category,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(order.description ?? 'No description provided'),
              trailing: Text(
                order.value != null
                    ? '\u20AC${order.value!.toDouble().toStringAsFixed(2)}'
                    : 'Value unknown',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black),
              ),
            ),*/
            const SizedBox(height: 10),
            Text(
              'Distance to pickup: ${distance.toStringAsFixed(2)} km',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            buildOrderDetails(order),
          ],
        ),
      ),
    );
  }

  Widget buildOrderDetails(Order order) {
    return Column(
      children: [
        if (order.weight != null)
          Text('Weight: ${order.weight} kg',
              style: const TextStyle(fontSize: 14)),
        if (order.width != null && order.height != null && order.length != null)
          Text(
              'Dimensions: ${order.width} x ${order.height} x ${order.length} cm',
              style: const TextStyle(fontSize: 14)),
        if (order.plate != null)
          Text('Vehicle Plate: ${order.plate}',
              style: const TextStyle(fontSize: 14)),
        if (order.model != null)
          Text('Vehicle Model: ${order.model}',
              style: const TextStyle(fontSize: 14)),
        if (order.brand != null)
          Text('Vehicle Brand: ${order.brand}',
              style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Icon getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case "MOTORIZED":
        return const Icon(FontAwesomeIcons.trailer, size: 34.0);
      case "SMALL":
        return const Icon(FontAwesomeIcons.motorcycle, size: 34.0);
      case "MEDIUM":
        return const Icon(FontAwesomeIcons.car, size: 34.0);
      case "LARGE":
        return const Icon(FontAwesomeIcons.caravan, size: 34.0);
      default:
        return const Icon(FontAwesomeIcons.question, size: 34.0);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
