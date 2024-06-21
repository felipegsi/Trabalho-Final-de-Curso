import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MessageApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080';

  void sendMessage(String message) async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      print('No token found');
      return;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/api/notifications'),
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
      Uri.parse('$baseUrl/api/notifications/user?userId=$userId'),
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
}
