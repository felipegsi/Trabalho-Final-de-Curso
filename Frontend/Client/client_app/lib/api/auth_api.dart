// auth_api.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final String baseUrl = 'http://192.168.31.1:8080/client';

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      await storage.write(key: 'token', value: response.body);
      return response.body;
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  Future<bool> isValidToken() async {
    String? token = await storage.read(key: 'token');
    if (token == null) return false;

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
      return true;
    } else {
      print('Error deleting account: ${response.body}');
      return false;
    }
  }
}
