// search_route.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'check_measures.dart'; // Certifique-se de importar o caminho correto
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Importa o LatLng correto

class SearchRoute extends StatefulWidget {
  const SearchRoute({super.key});

  @override
  _SearchRouteState createState() => _SearchRouteState();
}

class _SearchRouteState extends State<SearchRoute> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _originFocusNode = FocusNode();

  List<dynamic> _originSuggestions = [];
  List<dynamic> _destinationSuggestions = [];
  bool _showSuggestions = false;
  bool _isOriginFocused = false;

  final String _googleApiKey = 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik'; // Substitua pela sua chave de API do Google

  @override
  void initState() {
    super.initState();
    _originController.addListener(() => _onTextChanged(isOrigin: true));
    _destinationController.addListener(() => _onTextChanged(isOrigin: false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _originFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onTextChanged({required bool isOrigin}) {
    if (isOrigin ? _originController.text.isEmpty : _destinationController.text.isEmpty) {
      setState(() => _showSuggestions = false);
    } else {
      fetchSuggestions(
          isOrigin ? _originController.text : _destinationController.text,
          isOrigin: isOrigin);
    }
  }

  Future<void> fetchSuggestions(String input, {required bool isOrigin}) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&components=country:pt';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          if (isOrigin) {
            _originSuggestions = jsonResponse['predictions'];
          } else {
            _destinationSuggestions = jsonResponse['predictions'];
          }
          _showSuggestions = true;
        });
      } else {
        print('Failed to load suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  Future<void> fetchPlaceDetails(String placeId, {required bool isOrigin}) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final location = jsonResponse['result']['geometry']['location'];
        setState(() {
          if (isOrigin) {
            _originController.text = jsonResponse['result']['formatted_address'];
            _selectedOriginLocation = LatLng(location['lat'], location['lng']);
          } else {
            _destinationController.text = jsonResponse['result']['formatted_address'];
            _selectedDestinationLocation = LatLng(location['lat'], location['lng']);
            _showSuggestions = false;
          }
          if (_selectedOriginLocation != null && _selectedDestinationLocation != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckMeasures(
                  origin: _selectedOriginLocation!,
                  destination: _selectedDestinationLocation!,
                ),
              ),
            );
          }
        });
      } else {
        print('Failed to load place details');
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Search Location')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _originController,
                    focusNode: _originFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Origin',
                      hintText: 'Enter origin address',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isOriginFocused = true;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      hintText: 'Enter destination address',
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _isOriginFocused = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            _showSuggestions
                ? Expanded(
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: _isOriginFocused ? _originSuggestions.length : _destinationSuggestions.length,
                    itemBuilder: (context, index) {
                      var suggestion = _isOriginFocused ? _originSuggestions[index] : _destinationSuggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.map),
                        title: Text(
                          suggestion['description'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          fetchPlaceDetails(suggestion['place_id'], isOrigin: _isOriginFocused);
                        },
                      );
                    },
                  ),
                )
            )
                : Container(),
          ],
        ),
      ),
    );
  }

  LatLng? _selectedOriginLocation;
  LatLng? _selectedDestinationLocation;
}
