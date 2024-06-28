// order_cost_screen.dart
import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../api/order_api.dart';
import '../../../models/order.dart';
import '../order_confirmed/searching_driver_screen.dart';

class OrderCostScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String categoryType;
  final Map<String, dynamic> attributes;

  const OrderCostScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.categoryType,
    required this.attributes,
  });

  @override
  _OrderCostScreenState createState() => _OrderCostScreenState();
}

class _OrderCostScreenState extends State<OrderCostScreen> {
  List<LatLng> points = [];
  GoogleMapController? mapController;
  bool isLoading = false;
  Decimal orderCost = Decimal.zero;
  Marker? originMarker;
  Marker? destinationMarker;

  @override
  void initState() {
    super.initState();
    initializeMapMarkers();
    getRoute();
    estimateCost();
  }

  void initializeMapMarkers() {
    originMarker = Marker(
      markerId: const MarkerId('origin'),
      position: widget.origin,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: widget.destination,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
  }

  Future<void> getRoute() async {
    setState(() => isLoading = true);

    final String apiKey = 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik'; // Substitua pela sua chave de API do Google
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.origin.latitude},${widget.origin.longitude}&destination=${widget.destination.latitude},${widget.destination.longitude}&key=$apiKey';

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
      List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(encodedPolyline);

      setState(() {
        points = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        isLoading = false;
        adjustMapZoom();
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  Future<void> estimateCost() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);
    try {
      final cost = await orderApi.estimateOrderCost(createOrder());
      setState(() {
        orderCost = cost;
      });
    } catch (error) {
      print('Error estimating order cost: $error');
      setState(() {
        orderCost = Decimal.zero;
      });
    }
  }

  void adjustMapZoom() {
    if (mapController != null && points.isNotEmpty) {
      LatLngBounds bounds;
      if (points.length == 1) {
        bounds = LatLngBounds(
          southwest: LatLng(points.first.latitude - 0.01, points.first.longitude - 0.01),
          northeast: LatLng(points.first.latitude + 0.01, points.first.longitude + 0.01),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Screen'),
      ),
      body: Stack(
        children: [
          buildMap(),
          if (isLoading) const Center(child: CircularProgressIndicator()),
          buildBottomMenu(),
        ],
      ),
    );
  }

  Widget buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
        adjustMapZoom();
      },
      zoomControlsEnabled: false,
      initialCameraPosition: CameraPosition(target: widget.origin, zoom: 5.0),
      markers: {originMarker!, destinationMarker!},
      polylines: {
        if (points.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.black,
            width: 4,
          ),
      },
    );
  }

  Widget buildBottomMenu() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(20.0),
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              spreadRadius: 1.0,
              offset: Offset(0.0, 0.0),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: getCategoryIcon(widget.categoryType),
              title: Text(widget.categoryType, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Best option for your delivery'),
              trailing: Text(
                '\u20AC${orderCost.toDouble().toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
              ),
            ),
            const SizedBox(height: 10), // Add some spacing
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black, // cor do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // bordas arredondadas
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                try {
                  final orderApi = Provider.of<OrderApi>(context, listen: false);
                  Order? newOrder = await orderApi.createOrder(createOrder());
                  if (newOrder != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SearchingDriverScreen(order: newOrder),
                      ),
                    );
                  } else {
                    _showErrorDialog('We were unable to confirm your order. Try again.');
                  }
                } catch (error) {
                  _showErrorDialog('Error creating order: $error');
                }
              },
              child: const Text('Confirm Order'),
            ),
          ],
        ),
      ),
    );
  }

  Order createOrder() {
    if (widget.categoryType.toUpperCase() == "MOTORIZED") {
      return Order(
        origin: '${widget.origin.latitude},${widget.origin.longitude}',
        destination: '${widget.destination.latitude},${widget.destination.longitude}',
        description: widget.attributes['Description'] ?? 'Unknown Description',
        category: widget.categoryType.toUpperCase(),
        plate: widget.attributes['Plate'] ?? 'Unknown Plate',
        model: widget.attributes['Model'] ?? 'Unknown Model',
        brand: widget.attributes['Brand'] ?? 'Unknown Brand',
      );
    } else {
      return Order(
        origin: '${widget.origin.latitude},${widget.origin.longitude}',
        destination: '${widget.destination.latitude},${widget.destination.longitude}',
        description: widget.attributes['Description'] ?? 'Unknown Description',
        category: widget.categoryType.toUpperCase(),
        width: int.tryParse(widget.attributes['Width']!.toString()) ?? 0, // Default value if parsing fails
        height: int.tryParse(widget.attributes['Height']!.toString()) ?? 0,
        length: int.tryParse(widget.attributes['Length']!.toString()) ?? 0,
        weight: double.tryParse(widget.attributes['Weight']!.toString()) ?? 0.0,
      );
    }
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
