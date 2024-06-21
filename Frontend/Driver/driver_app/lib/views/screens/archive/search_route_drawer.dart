import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'route_map_screen.dart';

class SearchRoute extends StatefulWidget {
  const SearchRoute({super.key});

  @override
  _SearchRouteState createState() => _SearchRouteState();
}

class _SearchRouteState extends State<SearchRoute> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  Map<String, double>? _selectedOriginLocation;
  Map<String, double>? _selectedDestinationLocation;

  List<dynamic> _originSuggestions = [];
  List<dynamic> _destinationSuggestions = [];
  bool _showSuggestions = false;
  bool _isOriginFocused = false;

  @override
  void initState() {
    super.initState();
    _originController.addListener(() => _onTextChanged(isOrigin: true));
    _destinationController.addListener(() => _onTextChanged(isOrigin: false));
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _onTextChanged({required bool isOrigin}) {
    if (isOrigin
        ? _originController.text.isEmpty
        : _destinationController.text.isEmpty) {
      setState(() => _showSuggestions = false);
    } else {
      fetchSuggestions(
          isOrigin ? _originController.text : _destinationController.text,
          isOrigin: isOrigin);
    }
  }

  Future<void> fetchSuggestions(String input, {required bool isOrigin}) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?'
        'q=$input&'
        'format=json&'
        'countrycodes=pt');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'YourAppName/1.0'});
      if (response.statusCode == 200) {
        setState(() {
          isOrigin
              ? _originSuggestions = json.decode(response.body)
              : _destinationSuggestions = json.decode(response.body);
          _showSuggestions = true;
        });
      } else {
        print('Failed to load suggestions');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
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
              child: TextField(
                controller: _originController,
                decoration: const InputDecoration(
                  labelText: 'Origem',
                ),
                onTap: () {
                  setState(() {
                    _isOriginFocused = true;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destino',
                ),
                onTap: () {
                  setState(() {
                    _isOriginFocused = false;
                  });
                },
              ),
            ),
            _showSuggestions
                ? Expanded(
                    child: Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListView.builder(
                        itemCount: _isOriginFocused
                            ? _originSuggestions.length
                            : _destinationSuggestions.length,
                        itemBuilder: (context, index) {
                          var suggestion = _isOriginFocused
                              ? _originSuggestions[index]
                              : _destinationSuggestions[index];
                          return ListTile(
                            title: Text(suggestion['display_name']),
                            subtitle: Text(
                                'Lat: ${suggestion['lat']}, Lon: ${suggestion['lon']}'),
                            onTap: () {
                              setState(() {
                                if (_isOriginFocused) {
                                  _originController.text =
                                      suggestion['display_name'];
                                  _selectedOriginLocation = {
                                    'latitude': double.parse(suggestion['lat']),
                                    'longitude': double.parse(suggestion['lon'])
                                  };
                                } else {
                                  _destinationController.text =
                                      suggestion['display_name'];
                                  _selectedDestinationLocation = {
                                    'latitude': double.parse(suggestion['lat']),
                                    'longitude': double.parse(suggestion['lon'])
                                  };
                                  _showSuggestions = false;
                                }
                                if (_selectedOriginLocation != null && _selectedDestinationLocation != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouteMapScreen(
                                        origin: LatLng(_selectedOriginLocation!['latitude']!, _selectedOriginLocation!['longitude']!),
                                        destination: LatLng(_selectedDestinationLocation!['latitude']!, _selectedDestinationLocation!['longitude']!),
                                      ),
                                    ),
                                  );
                                }


                              });
                            },
                          );
                        },
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
