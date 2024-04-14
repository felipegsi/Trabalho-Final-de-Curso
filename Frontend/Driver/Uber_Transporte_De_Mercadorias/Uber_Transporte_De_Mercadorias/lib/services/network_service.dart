import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/driver.dart';
import '../models/order.dart';

class NetworkService {
  //link para conexão com o backend
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  Future<bool> registerDriver(Map<String, dynamic> clientData) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(url,
        body: json.encode(clientData),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      print(Driver.fromJson(json.decode(response.body)));
      return true;
    } else {
      print('Erro ao registrar motorista: ${response.body}');
      return false;
    }
  } 

  Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final response = await http.post(url,
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      // Salva o token no SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.body);
      // Imprime o token
      print('Token: ${response.body}');
      return response.body; // Assume this is the token
    } else {
      print('Erro ao fazer login: ${response.body}');
      return null;
    }
  }

  Future<Client?> viewProfile() async {
    // Recupera o token do SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      print('No token found');
      return null;
    }

    final url = Uri.parse('$baseUrl/viewProfile');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Adicione 'Bearer ' antes do token
    });
    if (response.statusCode == 200) {
      return Client.fromJson(json.decode(response.body));
    } else if (response.statusCode == 401) {
      print('Invalid token');
      return null;
    } else {
      print('Error: ${response.statusCode}');
      return null;
    }
  }

  Future<List<Order>> getOrderHistory() async {
    // Recupera o token do SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      print('No token found');
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/orderHistory');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token', // Adicione 'Bearer ' antes do token
    });

    if (response.statusCode == 200) {
      List<dynamic> ordersJson = json.decode(response.body);
      List<Order> orders =
      ordersJson.map((json) => Order.fromJson(json)).toList();
      return orders;
    } else {
      // Trate diferentes status codes ou erros aqui
      throw Exception('Failed to load order history');
    }
  }


}
