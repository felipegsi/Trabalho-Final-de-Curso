// order_cost_screen.dart
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';
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
    Key? key,
    required this.origin,
    required this.destination,
    required this.categoryType,
    required this.attributes,
  }) : super(key: key);

  @override
  _OrderCostScreenState createState() => _OrderCostScreenState();
}

class _OrderCostScreenState extends State<OrderCostScreen> {
  List<LatLng> points = [];
  List<Marker> markers = [];
  final MapController mapController = MapController();
  bool isLoading = false;
  Decimal orderCost = Decimal.zero;

  @override
  void initState() {
    super.initState();
    initializeMapMarkers();
    getRoute();
    estimateCost();
  }

  void initializeMapMarkers() {
    markers.addAll([
      Marker(
        point: widget.origin,
        child: const Icon(Icons.location_on, color: Colors.red),
      ),
      Marker(
        point: widget.destination,
        child: const Icon(Icons.location_on, color: Colors.blue),
      ),
    ]);
  }

  Future<void> getRoute() async {
    setState(() => isLoading = true);

    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf6248b8fc3d76941643ee9de00a23820316b7',
    );

    final List<ORSCoordinate> routeCoordinates = await client.directionsRouteCoordsGet(
      startCoordinate: ORSCoordinate(
        latitude: widget.origin.latitude,
        longitude: widget.origin.longitude,
      ),
      endCoordinate: ORSCoordinate(
        latitude: widget.destination.latitude,
        longitude: widget.destination.longitude,
      ),
      profileOverride: ORSProfile.drivingCar,
    );

    setState(() {
      points = routeCoordinates
          .map((coord) => LatLng(coord.latitude, coord.longitude))
          .toList();
      isLoading = false;
      adjustMapZoom();
    });
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
    if (markers.length == 2) {
      LatLngBounds bounds = LatLngBounds.fromPoints([widget.origin, widget.destination]);
      mapController.fitBounds(bounds, options: FitBoundsOptions(padding: EdgeInsets.all(50.0)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Screen'),
      ),
      body: Stack(
        children: [
          buildMap(),
          if (isLoading) Center(child: CircularProgressIndicator()),
          buildBottomMenu(),
        ],
      ),
    );
  }

  Widget buildMap() {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: widget.origin, initialZoom: 13.0),
      children: [
        TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'YourAppName/1.0'),
        MarkerLayer(markers: markers),
        PolylineLayer(polylines: [
          Polyline(points: points, strokeWidth: 4.0, color: Colors.blue)
        ]),
      ],
    );
  }

  Widget buildBottomMenu() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: EdgeInsets.all(20.0),
        padding: EdgeInsets.symmetric(vertical: 20.0),
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
              title: Text(widget.categoryType, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Example Description'),
              trailing: Text(
                '\u20AC${orderCost.toDouble().toStringAsFixed(2)}', // u20AC é o símbolo do Euro
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
              ),
            ),
            SizedBox(height: 10), // Add some spacing
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black, // cor do botão
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // bordas arredondadas
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                try {
                  final orderApi = Provider.of<OrderApi>(context, listen: false);
                  Order? newOrder = await orderApi.createOrder(createOrder());
                  if (newOrder != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SearchingDriverScreen(order: newOrder),                      ),
                    );
                  } else {
                    _showErrorDialog('Não foi possível confirmar seu pedido. Tente novamente.');
                  }
                } catch (error) {
                  _showErrorDialog('Erro ao criar pedido: $error');
                }
              },
              child: Text('Confirm Order'),
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
        return Icon(FontAwesomeIcons.trailer, size: 34.0);
      case "SMALL":
        return Icon(FontAwesomeIcons.motorcycle, size: 34.0);
      case "MEDIUM":
        return Icon(FontAwesomeIcons.car, size: 34.0);
      case "LARGE":
        return Icon(FontAwesomeIcons.caravan, size: 34.0);
      default:
        return Icon(FontAwesomeIcons.question, size: 34.0);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Erro'),
          content: Text(message),
          actions: <Widget>[
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
}
