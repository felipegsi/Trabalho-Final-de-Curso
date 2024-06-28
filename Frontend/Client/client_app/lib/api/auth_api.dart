import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/client';

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(url,
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      await storage.write(key: 'token', value: response.body);
      notifyListeners();
      return response.body;
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    notifyListeners();
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

  Future<bool> deleteAccount() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return false;
    }

    final url = Uri.parse('$baseUrl/deleteClient');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      await logout(); // Logout após a exclusão da conta
      notifyListeners(); // Notificar ouvintes após a exclusão da conta
      return true;
    } else {
      print('Error deleting account: ${response.body}');
      return false;
    }
  }

  Future<bool> registerClient(Map<String, dynamic> clientData) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(
      url,
      body: json.encode(clientData),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}
