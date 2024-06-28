import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:teste_2/views/screens/order_confirmed/canceled_order_screen.dart';
import 'package:teste_2/views/screens/order_confirmed/delivered_order_screen.dart';
import '../../../api/location_api.dart';
import '../../../api/order_api.dart';
import '../../../models/driver.dart';
import '../../../models/order.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../home/home_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  final Order order;

  const SearchingDriverScreen({super.key, required this.order});

  @override
  _SearchingDriverScreenState createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen> {
  GoogleMapController? mapController;
  Driver? assignedDriver;
  bool isLoading = true;
  bool _hasCalledAssignOrderToDriver = false;
  late LatLng initialLocation;
  ValueNotifier<double?> distanceNotifier = ValueNotifier(null);
  StreamSubscription? _locationUpdateSubscription;
  final _debounceDuration = const Duration(seconds: 10);
  Timer? _debounceTimer;
  late Order orderUpdate;

  @override
  void initState() {
    super.initState();
    orderUpdate = widget.order;
    initialLocation = _convertToLatLng(widget.order.origin);
  }

  @override
  void dispose() {
    _locationUpdateSubscription?.cancel();
    distanceNotifier.dispose();
    _debounceTimer?.cancel();
    super.dispose();
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

  Future<void> _assignOrderToDriver(OrderApi orderApi) async {
    setState(() {
      isLoading = true;
    });

    try {
      Driver driver = await orderApi.assignOrderToDriver(widget.order.id!);
      print('Driver assigned: ${driver.id}');

      _moveCameraToDriver(driver);

      assignedDriver = driver;
      isLoading = false;

      _startLocationUpdates(orderApi, driver, orderUpdate.id);
    } catch (error) {
      isLoading = false;
      _showErrorDialog('Failed to assign order to driver: $error');
    }
  }

  void _startLocationUpdates(OrderApi orderApi, Driver driver, int? orderId) {
    _locationUpdateSubscription = Stream.periodic(_debounceDuration)
        .asyncMap((_) => orderApi.getTravelInformation(driver.id, orderId!))
        .listen((travelInformation) {
      driver.location = travelInformation.driverLocation;
      _updateDriverMarker(driver);
      _updateOrderStatus(travelInformation.orderStatus);
    }, onError: (error) {
      print('Failed to update driver location: $error');
    });
  }
  void _updateOrderStatus(String status) {
    if(status == 'ACCEPTED') {
      orderUpdate.status = 'ACCEPTED';
    } else if (status == 'PICKED_UP') {
      orderUpdate.status = 'PICKED_UP';
    } else if (status == 'DELIVERED') {
      orderUpdate.status = 'DELIVERED';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DeliveredOrderScreen(),
        ),
      );
    } else if (status == 'CANCELLED') {
      orderUpdate.status = 'CANCELLED';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CanceledOrderScreen(),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
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

  Future<void> _onMapCreated(GoogleMapController controller,
      OrderApi orderApi) async {
    mapController = controller;
    await Future.delayed(const Duration(seconds: 3));

    if (!_hasCalledAssignOrderToDriver) {
      _hasCalledAssignOrderToDriver = true;
      await _assignOrderToDriver(orderApi);
    }
  }

  LatLng _convertToLatLng(String coordinates) {
    List<String> coords = coordinates.split(',');
    return LatLng(double.parse(coords[0]), double.parse(coords[1]));
  }

  void _moveCameraToDriver(Driver driver) {
    if (mapController != null) {
      mapController?.moveCamera(
        CameraUpdate.newLatLngZoom(
          _convertToLatLng(driver.location),
          17.0,
        ),
      );
    }
  }

  void _updateDriverMarker(Driver driver) {
    if (mapController != null) {
      setState(() {
        // Atualiza o marcador do motorista com a nova localização
      });
      mapController?.moveCamera(
        CameraUpdate.newLatLng(
          _convertToLatLng(driver.location),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: Stack(
        children: [
          Consumer<OrderApi>(
            builder: (context, orderApi, _) {
              return GoogleMap(
                onMapCreated: (controller) async =>
                await _onMapCreated(controller, orderApi),
                initialCameraPosition: CameraPosition(
                  target: initialLocation,
                  zoom: 17.0,
                ),
                markers: _buildMarkers(),
                zoomControlsEnabled: false,
              );
            },
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (assignedDriver != null) _buildDriverInfo(),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    if (assignedDriver != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _convertToLatLng(assignedDriver!.location),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(
          title: 'Driver: ${assignedDriver!.name}',
          snippet: 'Vehicle: ${assignedDriver!.vehicle}',
        ),
      ));
    }

    return markers;
  }


  Widget _buildDriverInfo() {
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
                    '${assignedDriver?.name[0]}',
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
                      '${assignedDriver?.name ?? 'Client Name'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(FontAwesomeIcons.info,
                            color: Colors.black87, size: 16),
                        Text('${assignedDriver!.vehicle.plate} - ${assignedDriver!.vehicle.brand} ${assignedDriver!.vehicle.model}',
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
                        _makePhoneCall(assignedDriver?.phoneNumber ?? '000');
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
                        _sendSMS(assignedDriver?.phoneNumber ?? '000', 'Hello!');
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
          ],
        ),
      ),
    );
  }

}
