import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_proj/models/order.dart';
import '../models/driver.dart';

class ProfileApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  Driver? _driver;
  bool _isLoading = false;
  String? _errorMessage;
  List<Order> _orders = [];

  Driver? get driver => _driver;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<Order> get orders => _orders;

  // metodo para obter o salario do motorista
  Future<String> getDriverSalary() async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/getDriverSalary');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load order');
    }
  }

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

  Future<void> getOrderHistory() async {
    try {
      _isLoading = true;
      notifyListeners();
      // Leitura do token
      String? token = await storage.read(key: 'token');
      if (token == null) {
        throw Exception('No token found');
      }
      // Monta a URL
      final url = Uri.parse('$baseUrl/orderHistory');
      // Faz a requisição GET
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      // Verifica o status da resposta
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        _orders = responseData.map<Order>((order) => Order.fromJson(order)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to fetch order history: ${response.body}';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
