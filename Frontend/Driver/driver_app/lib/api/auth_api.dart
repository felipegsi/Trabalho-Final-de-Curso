import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  String? _token;
  String? _driverId;

  String? get token => _token;
  String? get driverId => _driverId;

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(url,
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      _token = response.body;
      await storage.write(key: 'token', value: _token);
      await _loadDriverId(); // Load driver ID after login
      notifyListeners();
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> _loadDriverId() async {
    if (_token == null) return;

    final url = Uri.parse('$baseUrl/getDriverId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $_token',
    });
    if (response.statusCode == 200) {
      _driverId = response.body;
      await storage.write(key: 'driverId', value: _driverId);
    } else {
      throw Exception('Failed to load driver ID');
    }
  }

  Future<String?> getDriverId() async {
    _driverId ??= await storage.read(key: 'driverId');
    if (_driverId == null) {
      await _loadDriverId();
    }
    return _driverId;
  }

  Future<void> logout() async {
    _token = null;
    _driverId = null;
    await storage.deleteAll();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/deleteClient');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $_token',
    });

    if (response.statusCode == 200) {
      await logout();
    } else {
      throw Exception('Failed to delete account');
    }
  }

  Future<bool> isValidToken() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      return false;
    }
    final url = Uri.parse('$baseUrl/isValidToken');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    return response.statusCode == 200;
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
  Future<bool> registerDriver(Map<String, dynamic> driverData) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      body: json.encode(driverData),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

}
