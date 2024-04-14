import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:decimal/decimal.dart';

class NetworkService {
  //link para conexão com o backend
  final String baseUrl = 'http://10.0.2.2:8080/client';

  Future<bool> registerClient(Map<String, dynamic> clientData) async {
    final url = Uri.parse('$baseUrl/register');
    final response = await http.post(url,
        body: json.encode(clientData),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      print(Client.fromJson(json.decode(response.body)));
      return true;
    } else {
      print('Erro ao registrar cliente: ${response.body}');
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/orderHistory');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      Iterable json = jsonDecode(response.body);
      return json.map((orderJson) => Order.fromJson(orderJson)).toList();
    } else {
      // Handle different status codes and errors here
      throw Exception('Failed to load order history: ${response.body}');
    }
  }


  Future<Decimal> estimateOrderCost(Order order) async {

    // Recupera o token do SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) {
      print('No token found');
      throw Exception('No token found');
    }

    final url = Uri.parse('$baseUrl/estimateOrderCost');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(order.toJson()),
    );

    if (response.statusCode == 200) {
      // Converte a resposta para BigDecimal ou o tipo que você estiver usando
      return Decimal.parse(response.body);
    } else {
      throw Exception('Failed to estimate order cost: ${response.body}');
    }
  }



}


