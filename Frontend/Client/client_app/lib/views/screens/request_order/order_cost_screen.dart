import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_route_service/open_route_service.dart';
import '../../../models/order.dart';
import '../../../services/network_service.dart';
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
  final NetworkService _networkService = NetworkService();
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
  }

  void initializeMapMarkers() {
    markers.addAll([
      Marker(
        point: widget.origin,
        child: Icon(Icons.location_on, color: Colors.red),
      ),
      Marker(
        point: widget.destination,
        child: Icon(Icons.location_on, color: Colors.blue),
      ),
    ]);
  }

  Future<void> getRoute() async {
    setState(() => isLoading = true);

    final OpenRouteService client = OpenRouteService(
      apiKey: '5b3ce3597851110001cf6248b8fc3d76941643ee9de00a23820316b7',
    );

    final List<ORSCoordinate> routeCoordinates =
        await client.directionsRouteCoordsGet(
      startCoordinate: ORSCoordinate(
          latitude: widget.origin.latitude, longitude: widget.origin.longitude
      ),
      endCoordinate: ORSCoordinate(
          latitude: widget.destination.latitude,
          longitude: widget.destination.longitude
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

  void adjustMapZoom() {
    if (markers.length == 2) {
      LatLngBounds bounds =
          LatLngBounds.fromPoints([widget.origin, widget.destination]);
      mapController.fitBounds(bounds,
          options: FitBoundsOptions(padding: EdgeInsets.all(50.0)));
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
                offset: Offset(0.0, 0.0))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use min to fit content
          children: <Widget>[
            FutureBuilder<Decimal>(
              future: _networkService.estimateOrderCost(createOrder(), context),
              builder: (context, snapshot) {
                print("snapshot.data: ");
                print(snapshot.data);

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  orderCost = snapshot.data!;
                  return buildMenuItem(
                      context,
                      widget.categoryType,
                      'Example Description',

                      '\u20AC${orderCost.toDouble().toStringAsFixed(2)}'); // u20AC é o simbolo do Euro
                } else {
                  return Text('No data');
                }
              },
            ),
            SizedBox(height: 10),  // Add some spacing
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
                  Order? newOrder = await _networkService.createOrder(createOrder(), context);
                  if (newOrder != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SearchingDriverScreen(
                          //orderId: newOrder.id,
                        ),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Erro"),
                          content: Text("Não foi possível confirmar seu pedido. Tente novamente."),
                          actions: <Widget>[
                            TextButton(
                              child: Text("Tentar Novamente"),
                              onPressed: () {
                                Navigator.of(context).pop(); // Fecha o diálogo
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }
                } catch (error) {
                  // Trate o erro aqui
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
        category: widget.categoryType.toUpperCase(),
        plate: widget.attributes['Plate'] ?? 'Unknown Plate',
        model: widget.attributes['Model'] ?? 'Unknown Model',
        brand: widget.attributes['Brand'] ?? 'Unknown Brand',
      );
    } else {
      return Order(
        origin: '${widget.origin.latitude},${widget.origin.longitude}',
        destination: '${widget.destination.latitude},${widget.destination.longitude}',
        category: widget.categoryType.toUpperCase(),
        width: int.tryParse(widget.attributes['Width']!.toString()) ?? 0, // Default value if parsing fails
        height: int.tryParse(widget.attributes['Height']!.toString()) ?? 0,
        length: int.tryParse(widget.attributes['Length']!.toString()) ?? 0,
        weight: double.tryParse(widget.attributes['Weight']!.toString()) ?? 0.0,
      );
    }
  }

  Widget buildMenuItem(BuildContext context, String category, String example,
      String price) {

    IconData selectedIcon;

    if (category.toUpperCase() == "MOTORIZED") {
      selectedIcon = FontAwesomeIcons.trailer;
    } else if (category.toUpperCase() == "SMALL") {
      selectedIcon = FontAwesomeIcons.motorcycle;
    } else if (category.toUpperCase() == "MEDIUM") {
      selectedIcon = FontAwesomeIcons.car;
    } else if (category.toUpperCase() == "LARGE") {
      selectedIcon = FontAwesomeIcons.caravan;
    } else {
      selectedIcon = FontAwesomeIcons.question;
    }

    return ListTile(
        leading: Icon(selectedIcon, size: 34.0),
        title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(example),
        trailing: Text(price,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black)),
        onTap: () {
        }
    );
  }

}
