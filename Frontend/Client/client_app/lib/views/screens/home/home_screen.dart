import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teste_2/views/screens/profile/order_history_screen.dart';
import 'package:teste_2/views/screens/request_order/search_route_drawer.dart';
import 'package:teste_2/views/screens/home/menu_drawer.dart';
import '../../../themes/app_theme.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
// TODO : COLOCAR MARCADORES DOS DRIVERS A VOLTA
class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      LatLng position = await _determinePosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _moveCameraToCurrentPosition();
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao obter localização: $error');
    }
  }

  Future<LatLng> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desativado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente');
    }

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  void _moveCameraToCurrentPosition() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Erro'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawerEnableOpenDragGesture: false,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentPosition == null
              ? const Center(child: Text('Localização não disponível'))
              : GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _moveCameraToCurrentPosition();
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(38.758072, -9.153414), // Valor padrão inicial
              zoom: 15,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          _buildTopButton(context),
          _buildBottomCard(context),
        ],
      ),
      drawer: const MenuDrawer(),
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
      child: SizedBox(
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
                const SizedBox(height: 10),
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
          builder: (context) => const FractionallySizedBox(
            heightFactor: 0.95,
            child: SearchRoute(),
          ),
        );
      },
      child: SizedBox(
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
                  shape: const StadiumBorder(),
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
    return SizedBox(
      height: kToolbarHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildIconHistoryButton(Icons.history, 0),
          const SizedBox(width: 30),
          _buildIconButton(Icons.star, 0),
          const SizedBox(width: 30),
          _buildIconButton(Icons.notifications, 1),
          const SizedBox(width: 30),
          _buildIconProfileButton(Icons.person, 2),
          const SizedBox(width: 30),
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

  Widget _buildIconProfileButton(IconData icon, int index) {
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
      ),
    );
  }

  Widget _buildIconHistoryButton(IconData icon, int index) {
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
          );
        },
      ),
    );
  }



}
