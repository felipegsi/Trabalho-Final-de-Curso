import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/driver.dart';

class ProfileApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  Driver? _driver;
  bool _isLoading = false;
  String? _errorMessage;

  Driver? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  Future<void> fetchProfile() async {
    try {
      _isLoading = true;
      notifyListeners();
      String? token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token found');
      }
      final url = Uri.parse('$baseUrl/viewProfile');
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        _driver = Driver.fromJsonViewProfile(json.decode(response.body));
        _errorMessage = null;
      } else {
        _driver = null;
        _errorMessage = 'Failed to fetch profile: ${response.body}';
      }
    } catch (e) {
      _driver = null;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
