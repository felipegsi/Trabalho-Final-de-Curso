// order_api.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/order.dart';
import '../models/location.dart';

class OrderApi with ChangeNotifier {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final String baseUrl = 'http://192.168.31.1:8080/client';
  List<Order> _orders = [];

  List<Order> get orders => _orders;

  // Método para buscar histórico de pedidos
  Future<void> fetchOrderHistory() async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/orderHistory');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      Iterable json = jsonDecode(response.body);
      _orders = json.map((orderJson) => Order.fromJson(orderJson)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load order history: ${response.body}');
    }
  }

  // Método para criar pedido
  Future<Order?> createOrder(Order order) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/createOrder');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create order: ${response.body}');
    }
  }

  // Método para estimar custo do pedido
  Future<Decimal> estimateOrderCost(Order order) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/estimateOrderCost');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 200) {
      return Decimal.parse(response.body);
    } else {
      throw Exception('Failed to estimate order cost: ${response.body}');
    }
  }

  // Método para estimar custos de todas as categorias de pedido
  Future<List<Decimal>> estimateAllCategoryOrderCost(Location location) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/estimateAllCategoryOrderCost');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(location.toJson()),
    );

    if (response.statusCode == 200) {
      List<dynamic> responseBody = jsonDecode(response.body);
      return responseBody
          .map((cost) => Decimal.parse(cost.toString()))
          .toList();
    } else {
      throw Exception('Failed to estimate order cost: ${response.body}');
    }
  }



  Future<Driver> assignOrderToDriver(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/assignOrderToDriver/$orderId');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return Driver.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to assign order to driver: ${response.body}');
    }
  }
}
