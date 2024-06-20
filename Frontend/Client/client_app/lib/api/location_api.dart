import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationApi with ChangeNotifier {
  Future<double> fetchDistance(LatLng origin, LatLng destination) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/distancematrix/json', {
      'origins': '${origin.latitude},${origin.longitude}',
      'destinations': '${destination.latitude},${destination.longitude}',
      'key': 'AIzaSyDWkqwPVu8yCPdeR3ynYX-a8VHco5kS-Ik', // Use sua chave API aqui
    });

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final distanceInMeters = data['rows'][0]['elements'][0]['distance']['value'];
      return distanceInMeters / 1000; // Converter para quilômetros
    } else {
      throw Exception('Failed to fetch distance: ${response.body}');
    }
  }
}
