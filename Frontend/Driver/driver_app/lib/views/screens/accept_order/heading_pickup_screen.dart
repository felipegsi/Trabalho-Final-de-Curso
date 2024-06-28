import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_proj/views/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../api/order_api.dart';
import '../../../models/order.dart';
import '../../../services/location_service.dart';
import 'delivery_confirmation_screen.dart';

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
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _lastKnownLocation;
  Marker? destinationMarker;
  double distance = 0.0;
  late StreamSubscription<Position> _positionStream;
  Order? orderHere;
  String duration = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _determinePosition();
    if (_currentLocation != null) {
      final orderApi = Provider.of<OrderApi>(context, listen: false);
      await orderApi.getOrderById(widget.orderId);
      orderHere = orderApi.order;

      if (orderHere != null) {
        _initializeMapMarkers(orderHere!);
        await _getRouteToOrigin();
      }
    }
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 30,
      ),
    ).listen((Position position) {
      _updateCurrentLocation(position);
    });
  }

  void _updateCurrentLocation(Position position) async {
    if (position.accuracy < 30) {
      _currentLocation = LatLng(position.latitude, position.longitude);
      final newLocation = LatLng(position.latitude, position.longitude);

      if (_lastKnownLocation == null ||
          _hasMovedSignificantly(_lastKnownLocation!, newLocation)) {
        _lastKnownLocation = newLocation;
        mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));

        if (orderHere?.origin != null) {
          points.clear();
          setState(() {});
          final orderApi = Provider.of<OrderApi>(context, listen: false);
          orderApi.sendLocationToServer(
              '${position.latitude}, ${position.longitude}');
          await _getRouteToOrigin();
        }
      }
    }
  }

  bool _hasMovedSignificantly(LatLng oldLocation, LatLng newLocation) {
    return Geolocator.distanceBetween(
          oldLocation.latitude,
          oldLocation.longitude,
          newLocation.latitude,
          newLocation.longitude,
        ) >
        30;
  }

  Future<void> _determinePosition() async {
    final locationService = LocationService();
    _currentLocation = await locationService.determinePosition();
    _lastKnownLocation = _currentLocation;
    print('Localização atual: $_currentLocation \n\n');
  }

  void _initializeMapMarkers(Order order) {
    if (_currentLocation == null) return;

    final origin = _parseLatLng(order.origin);
    final destination = _parseLatLng(order.destination);

    if (order.status == 'ACCEPTED')
      destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: origin,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    else
      destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

    setState(() {});
  }

  LatLng _parseLatLng(String coordinate) {
    final coords = coordinate.split(',').map(double.parse).toList();
    return LatLng(coords[0], coords[1]);
  }

  // ligar para o cliente
  void _makePhoneCall(String phoneNumber) async {
    var url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _sendSMS(String phoneNumber, String message) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': Uri.encodeComponent(message),
      },
    );
    if (await canLaunchUrlString(launchUri.toString())) {
      await launchUrlString(launchUri.toString());
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> _getRouteToOrigin() async {
    if (_currentLocation == null) return;

    setState(() => isLoading = true);

    const apiKey = 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik';
    final origin = _parseLatLng(orderHere!.origin);
    final destination = _parseLatLng(orderHere!.destination);
    final url;
    if (orderHere!.status == 'ACCEPTED') {
      url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
          '&destination=${origin.latitude},${origin.longitude}&key=$apiKey';
    } else {
      url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
          '&destination=${destination.latitude},${destination.longitude}&key=$apiKey';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final routes = jsonResponse['routes'];
        if (routes.isEmpty) throw Exception('No routes found');

        final encodedPolyline = routes[0]['overview_polyline']['points'];
        final polylinePoints = PolylinePoints().decodePolyline(encodedPolyline);

        distance = routes[0]['legs'][0]['distance']['value'] / 1000;
        duration = routes[0]['legs'][0]['duration']['text'];

        setState(() {
          points = polylinePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print(e);
    }
  }

  void _adjustRouteMode() {
    if (mapController != null && points.isNotEmpty) {
      LatLngBounds bounds = _calculateLatLngBounds(points);
      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _calculateLatLngBounds(List<LatLng> points) {
    if (points.length == 1) {
      final singlePoint = points.first;
      return LatLngBounds(
        southwest:
            LatLng(singlePoint.latitude - 0.01, singlePoint.longitude - 0.01),
        northeast:
            LatLng(singlePoint.latitude + 0.01, singlePoint.longitude + 0.01),
      );
    } else {
      return LatLngBounds(
        southwest: LatLng(
          points.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
          points.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          points.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
          points.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Route',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // Remove a sombra da AppBar
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildMap(),
                Positioned(
                  // Colocar o botão de navegação um pouco abaixo da metade do mapa
                  bottom: MediaQuery.of(context).size.height * 0.41,
                  right: 20.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_currentLocation != null)
                        mapController?.animateCamera(
                          CameraUpdate.newLatLng(_currentLocation!),
                        );
                    },
                    backgroundColor: Colors.white,
                    child: Icon(Icons.my_location, color: Colors.black),
                  ),
                ),
                Positioned(
                  // Colocar o botão de navegação um pouco abaixo da metade do mapa
                  bottom: MediaQuery.of(context).size.height * 0.33,
                  right: 20.0,
                  child: _navigateButton(),
                ),
                if (orderHere != null) _buildMenu(orderHere!),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        orderHere?.status ?? 'Order Status',
                        style: TextStyle(
                          color: _colorFunction(orderHere?.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),

              ],
            ),
    );
  }

  Color _colorFunction(String? status) {
    if (status == 'ACCEPTED') {
      return Colors.blue;
    } else if (status == 'PICKED_UP') {
      return Colors.orange;
    } else if (status == 'DELIVERED') {
      return Colors.green;
    } else {
      return Colors.black;
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
        _adjustRouteMode();
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation ?? const LatLng(38.758072, -9.153414),
        zoom: 16.0,
      ),
      markers: {
        if (destinationMarker != null) destinationMarker!,
      },
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      polylines: {
        if (points.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.black87,
            width: 4,
          ),
      },
    );
  }

  Widget _buildMenu(Order order) {
    return Positioned(
      bottom: 30.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0), // Cantos arredondados
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 25,
                  child: Text(
                    '${order.client?.name[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.client?.name ?? 'Client Name'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.route,
                            color: Colors.black87, size: 16),
                        Text(' ${duration} - ${distance.toStringAsFixed(2)} km',
                            style: TextStyle(
                                fontSize: 15, color: Colors.grey[700])),
                      ],
                    ),
                    if (order.weight != null &&
                        order.width != null &&
                        order.height != null &&
                        order.length != null)
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.cube,
                              color: Colors.black87, size: 16),
                          Text(
                              ' ${order.weight} kg - ${order.width}x${order.height}x${order.length} cm',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700])),
                        ],
                      ),
                    if (order.plate != null &&
                        order.brand != null &&
                        order.model != null)
                      Row(
                        children: [
                          Icon(FontAwesomeIcons.car,
                              color: Colors.black87, size: 16),
                          Text(
                              ' ${order.plate} - ${order.brand} ${order.model}',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700])),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.call, color: Colors.black),
                      onPressed: () {
                        _makePhoneCall(order.client?.phoneNumber ?? '000');
                      },
                    ),
                    Text('Call'),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.chat, color: Colors.black),
                      onPressed: () {
                        _sendSMS(order.client?.phoneNumber ?? '000', 'Hello!');
                      },
                    ),
                    Text('Chat'),
                  ],
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.cancel, color: Colors.black),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Cancel Order'),
                              content: const Text(
                                  'Are you sure you want to cancel this order?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await Provider.of<OrderApi>(context,
                                            listen: false)
                                        .cancelledOrderStatus(widget.orderId);
                                    // navegar para a Home
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) => HomeScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Confirm'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Text('Cancel'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            // Mostrar o botão "Arrive" apenas se a distância for menor que 0.5 km (500 metros)
            if (distance < 0.5)
              if (order.status == 'ACCEPTED')
                pickupButton()
              else
                deliveredButton(),
          ],
        ),
      ),
    );
  }

  Widget _navigateButton() {
    return FloatingActionButton(
      onPressed: _launchGoogleMaps,
      backgroundColor: Colors.white,
      child: const Icon(FontAwesomeIcons.map, color: Colors.black),
    );
  }

  Widget pickupButton() {
    return ElevatedButton(
      onPressed: _changeOrderStatus,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        'Pickup',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget deliveredButton() {
    return ElevatedButton(
      onPressed: _changeOrderStatus,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      child: Text(
        'Delivered',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _changeOrderStatus() async {
    final orderApi = Provider.of<OrderApi>(context, listen: false);

    if (orderHere!.status == 'ACCEPTED') {
      orderHere!.status = 'PICKED_UP';
      await orderApi.pickupOrderStatus(widget.orderId);
      // Recalculate the route after changing the status
      _initializeMapMarkers(orderHere!);
      await _getRouteToOrigin();
    } else {
      orderHere!.status = 'DELIVERED';
      await orderApi.deliverOrderStatus(widget.orderId);
      // Navegar para a tela de confirmação de entrega
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DeliveryConfirmationScreen(),
        ),
      );
    }
    setState(() {});
  }

  void _launchGoogleMaps() async {
    if (_currentLocation == null || destinationMarker == null) return;

    final destination = destinationMarker!.position;
    final googleMapsUrl =
        'google.navigation:q=${destination.latitude},${destination.longitude}&mode=d';

    if (await canLaunchUrlString(googleMapsUrl)) {
      await launchUrlString(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }
}
