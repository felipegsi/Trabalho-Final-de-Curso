import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teste_2/views/screens/request_order/search_route_drawer.dart';
import 'package:teste_2/views/screens/home/menu_drawer.dart';
import '../../../themes/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<LatLng> _currentPositionFuture;

  @override
  void initState() {
    super.initState();
    _currentPositionFuture = _determinePosition();
  }

  //TODO: COLOCAR MARCADORES DOS DRIVERS QUE ESTAO DISPONIVEIS
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          FutureBuilder<LatLng>(
            future: _currentPositionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Erro ao obter localização'));
              } else if (!snapshot.hasData) {
                return Center(child: Text('Localização não disponível'));
              } else {
                LatLng _currentPosition = snapshot.data!;
                return GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_currentPosition),
                    );
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(0, 0), // Valor padrão inicial
                    zoom: 12,
                  ),
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                );
              }
            },
          ),
          _buildTopButton(context),
          _buildBottomCard(context),
        ],
      ),
      drawer: const MenuDrawer(),
    );
  }

  Future<LatLng> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LatLng(0, 0);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LatLng(0, 0);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LatLng(0, 0);
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
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
          SizedBox(width: 30),
          _buildIconButton(Icons.star, 0),
          SizedBox(width: 30),
          _buildIconButton(Icons.notifications, 1),
          SizedBox(width: 30),
          _buildIconButton(Icons.person, 2),
          SizedBox(width: 30),
          _buildIconButton(Icons.help_outline, 3),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, int index) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        iconSize: 30,
        icon: Icon(icon),
        color: iconColor,
        onPressed: () {},
      ),
    );
  }
}
