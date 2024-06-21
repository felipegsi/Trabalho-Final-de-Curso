import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/driver.dart';
import '../models/order.dart';
import '../views/screens/auth/login_screen.dart';

class NetworkServic {
  // Cria uma instância do FlutterSecureStorage para armazenar e recuperar o token de forma segura
  final storage = const FlutterSecureStorage();

  // URL base para todas as requisições
  final String baseUrl = 'http://10.0.2.2:8080/driver';

  // Função para verificar se o token é válido
  Future<bool> isValidToken() async {
    // Recupera o token do armazenamento seguro
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

  void sendPrivateMessage(String userId, String message) async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return;
    }
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/notifications/user?userId=$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: message,
    );

    if (response.statusCode == 200) {
      print('Mensagem privada enviada com sucesso');
    } else {
      print('Falha ao enviar mensagem privada: ${response.statusCode}');
    }
  }


  Future<String> getDriverIdFromToken() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('No token found');
    }
    final url = Uri.parse('$baseUrl/getDriverId');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Adicione 'Bearer ' antes do token
    });
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load driver id');
    }
  }

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

  Future<Driver?> viewProfile(BuildContext context) async {
    // Recupera o token do FlutterSecureStorage
    String? token = await storage.read(key: 'token');
    // Se o token for nulo, exibe um diálogo de sessão expirada e retorna nulo
    if (token == null) {
      showExpiredSessionDialog(context);
      return null;
    }

    final url = Uri.parse('$baseUrl/viewProfile');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Adicione 'Bearer ' antes do token
    });
    if (response.statusCode == 200) {
      return Driver.fromJsonViewProfile(json.decode(response.body));
    } else {
      print('Invalid token');
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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

  Future<bool> setDriverOnline(String location) async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return false;
    }
    final url = Uri.parse('$baseUrl/online');
    final response = await http.put(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'location': location
        }) // Inclui a localização no corpo da solicitação
        );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(
          'Error setting driver online: ${response.statusCode}, ${response.body}');
      return false;
    }
  }

  // Função para definir o motorista como offline
  Future<bool> setDriverOffline() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return false;
    }

    final url = Uri.parse('$baseUrl/offline');
    final response = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Error setting driver offline: ${response.statusCode}');
      return false;
    }
  }

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
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return true;
    } else {
      print('Erro ao deletar conta: ${response.body}');
      return false;
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
  }

  void showExpiredSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      // O usuário não pode fechar o diálogo tocando fora dele
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
}
