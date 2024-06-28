import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/client.dart';
import '../models/driver.dart';
import '../models/order.dart';
import '../models/travel_information.dart';
import 'package:decimal/decimal.dart';

import '../views/screens/auth/login_screen.dart';

class NetworkService {
  // Cria uma instância do FlutterSecureStorage para armazenar e recuperar o token de forma segura
  final storage = const FlutterSecureStorage();

  // URL base para todas as requisições
  final String baseUrl = 'http://192.168.31.1:8080/client'; //10.0.2.2

  // Função para verificar se o token é válido
  Future<bool> isValidToken() async {
    // Recupera o token do armazenamento segurodsff
    String? token = await storage.read(key: 'token');
    // Se o token for nulo, retorna false
    if (token == null) {

      return false;
    }

    // Cria a URL para a rota de verificação de validade do token
    final url = Uri.parse('$baseUrl/isValidToken');
    // Envia uma requisição GET para a URL com o token no cabeçalho de autorização
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    // Se o código de status da resposta for 200, retorna true, caso contrário, retorna false
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // Função para registrar um novo cliente
  Future<bool> registerClient(Map<String, dynamic> clientData) async {
    // Cria a URL para a rota de registro
    final url = Uri.parse('$baseUrl/register');
    // Envia uma requisição POST para a URL com os dados do cliente no corpo da requisição
    final response = await http.post(url,
        body: json.encode(clientData),
        headers: {'Content-Type': 'application/json'});
    // Se o código de status da resposta for 200, imprime o cliente e retorna true
    if (response.statusCode == 200) {
      print(Client.fromJson(json.decode(response.body)));
      return true;
    } else {
      // Se o código de status da resposta não for 200, imprime o corpo da resposta e retorna false
      print('Erro ao registrar cliente: ${response.body}');
      return false;
    }
  }

  // Função para fazer login
  Future<String?> login(String email, String password) async {
    // Cria a URL para a rota de login
    final url = Uri.parse('$baseUrl/login');
    // Envia uma requisição POST para a URL com o e-mail e a senha no corpo da requisição
    final response = await http.post(url,
        body: json.encode({'email': email, 'password': password}),
        headers: {'Content-Type': 'application/json'});
    // Se o código de status da resposta for 200, salva o token no armazenamento seguro e retorna o token
    if (response.statusCode == 200) {
      await storage.write(key: 'token', value: response.body);
      print('Token: ${response.body}');
      return response.body; // Assume this is the token
    } else {
      // Se o código de status da resposta não for 200, imprime o corpo da resposta e retorna null
      print('Erro ao fazer login: ${response.body}');
      return null;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }
  void showExpiredSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // O usuário não pode fechar o diálogo tocando fora dele
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sessão Expirada'),
          content: const Text('Sua sessão expirou. Por favor, faça login novamente.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                // Fecha o diálogo
                Navigator.of(dialogContext).pop();
                // Redireciona para a página de login
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }
  Future<Client?> viewProfile(BuildContext context) async {
    // Recupera o token do FlutterSecureStorage
    String? token = await storage.read(key: 'token');

    // Se o token for nulo, exibe um diálogo de sessão expirada e retorna nulo
    if (token == null) {
      showExpiredSessionDialog(context);
      return null;
    }

    final url = Uri.parse('$baseUrl/viewProfile');
    final response = await http.get(
        url,
        headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Adicione 'Bearer ' antes do token
    });
    if (response.statusCode == 200) {
      return Client.fromJson(json.decode(response.body));
    }else {
      print('Invalid token');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return null;
    }
  }

  Future<List<Order>> getOrderHistory() async {
    String? token = await storage.read(key: 'token');
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



  Future<List<Decimal>> estimateAllCategoryOrderCost(TravelInformation location) async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No token found');
    }

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
      return responseBody.map((cost) => Decimal.parse(cost.toString())).toList();
    } else {
      throw Exception('Failed to estimate order cost: ${response.body}');
    }
  }
  Future<Order?> createOrder(Order order, BuildContext context) async {
    String? token = await storage.read(key: 'token');
    // Se o token for nulo, exibe um diálogo de sessão expirada e retorna nulo
    if (token == null) {
      showExpiredSessionDialog(context);
      return null;
    }
    // Converte o objeto Order para um mapa e depois para uma string JSON
    String orderJson = jsonEncode(order.toJson());

    print('Order JSON(createOrder): $orderJson');

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

  Future<Decimal> estimateOrderCost(Order order, BuildContext context) async {
    // Recupera o token do armazenamento seguro
    String? token = await storage.read(key: 'token');

    // Se o token for nulo, exibe um diálogo de sessão expirada e retorna nulo
    if (token == null) {
      showExpiredSessionDialog(context);
      return Decimal.zero;
    }

    // Cria a URL para a rota de estimativa de custo do pedido
    final url = Uri.parse('$baseUrl/estimateOrderCost');

    // Converte o objeto Order para um mapa e depois para uma string JSON
    String orderJson = jsonEncode(order.toJson());

    // Envia uma requisição POST para a URL com o objeto Order no corpo da requisição e o token no cabeçalho de autorização
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: orderJson,
    );

    // Se o código de status da resposta for 200, converte o corpo da resposta para Decimal e retorna
    if (response.statusCode == 200) {
      return Decimal.parse(response.body);
    } else {
      // Se o código de status da resposta não for 200, lança uma exceção com a mensagem de erro
      throw Exception('Failed to estimate order cost: ${response.body}');
    }
  }

//deleta uma conta
// Na classe NetworkService
  Future<bool> deleteAccount(BuildContext context) async {
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
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return true;
    } else {
      print('Erro ao deletar conta: ${response.body}');
      return false;
    }
  }

  void sendMessage(String message) async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return;
    }
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/notifications'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: message,
    );

    if (response.statusCode == 200) {
      print('Mensagem enviada com sucesso');
    } else {
      print('Falha ao enviar mensagem: ${response.statusCode}');
    }
  }


  // Função para atribuir um pedido a um motorista
  Future<Driver> assignOrderToDriver(Long? orderId, BuildContext context) async {
    // Recupera o token do armazenamento seguro
    String? token = await storage.read(key: 'token');

    // Se o token for nulo, exibe um diálogo de sessão expirada e retorna nulo
    if (token == null) {
      showExpiredSessionDialog(context);
      throw Exception('No token found');
    }

    // Cria a URL para a rota de atribuição de pedido a motorista
    final url = Uri.parse('$baseUrl/assignOrderToDriver');

    // Envia uma requisição POST para a URL com o orderId no corpo da requisição e o token no cabeçalho de autorização
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'orderId': orderId}),
    );

    // Se o código de status da resposta for 200, converte o corpo da resposta para Driver e retorna
    if (response.statusCode == 200) {
      return Driver.fromJson(jsonDecode(response.body));
    } else {
      // Se o código de status da resposta não for 200, lança uma exceção com a mensagem de erro
      throw Exception('Failed to assign order to driver: ${response.body}');
    }
  }


}


