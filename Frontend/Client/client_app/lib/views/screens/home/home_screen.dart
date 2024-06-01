import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teste_2/views/screens/request_order/search_route_drawer.dart';
import 'package:teste_2/views/screens/home/menu_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../themes/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng _currentPosition = LatLng(38.758072, -9.153414);
  final MapController _mapController = MapController();
  double _backgroundIconSize = 60;
  double _iconSize = 30;
  double _spaceBetweenIcons = 30;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // TODO: implementar a permissão de localização, mostrando o icone de localização no mapa
    _determinePosition();
  }

  // metodo para determinar a posição atual do dispositivo
  Future<LatLng?> _determinePosition() async {
    try {
      print('---2---_determinePosition');

      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      Position position = await Geolocator.getCurrentPosition(); // Obtém a posição atual do dispositivo
      _currentPosition = LatLng(position.latitude, position.longitude);
    } catch (e) {}

    return _currentPosition;
  }

  Marker _buildCurrentLocationMarker(LatLng currentLocation) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: currentLocation,
      child: Icon(Icons.location_on, color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopButton(context),
          _buildBottomCard(context),
        ],
      ),
      drawer: const MenuDrawer(),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: 16,

      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        MarkerLayer(
          markers: [_buildCurrentLocationMarker(_currentPosition)],
        ),
      ],
    );
  }

  Widget _buildTopButton(BuildContext context) {
    return Positioned(
      top: 35,
      left: 15,
      child: FloatingActionButton(
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        backgroundColor: backgroundColor,
        child: const Icon(Icons.menu, color: iconColor),
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context) {
    return Positioned(
      bottom: 35,
      left: 0,
      right: 0,
      child: Container(
        height: 130,
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchField(context),
                SizedBox(height: 10),
                _buildIconRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.95,
            child: SearchRoute(),
          ),
        );
      },
      child: Container(
        height: 40,
        width: double.infinity,
        child: Stack(
          children: [
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Where to?',
                prefixIcon: const Icon(Icons.search, color: iconColor),
                filled: true,
                fillColor: iconBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Positioned(
              right: 5,
              top: 5,
              bottom: 5,
              left: 220,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 5.0),
                  shape: StadiumBorder(),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_filled, size: 16, color: iconColor),
                    SizedBox(width: 10),
                    Text('Now', style: TextStyle(color: textColor)),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 18, color: iconColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow() {
    return Container(
      height: kToolbarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildIconButton(Icons.history, 0),
          SizedBox(width: _spaceBetweenIcons),
          _buildIconButton(Icons.star, 0),
          SizedBox(width: _spaceBetweenIcons),
          _buildIconButton(Icons.notifications, 1),
          SizedBox(width: _spaceBetweenIcons),
          _buildIconButton(Icons.person, 2),
          SizedBox(width: _spaceBetweenIcons),
          _buildIconButton(Icons.help_outline, 3),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, int index) {
    return Container(
      width: _backgroundIconSize,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        iconSize: _iconSize,
        icon: Icon(icon),
        color: iconColor,
        onPressed: () {},
      ),
    );
  }
}
