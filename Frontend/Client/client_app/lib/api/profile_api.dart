// profile_api.dart
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/client.dart';

class ProfileApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://192.168.31.1:8080/client';
  Client? _client;

  Client? get client => _client;

  Future<void> viewProfile() async {
    String? token = await storage.read(key: 'token');
    if (token == null) {
      _client = null; // Limpa o cliente se não houver token
      notifyListeners();
      return;
    }

    final url = Uri.parse('$baseUrl/viewProfile');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      _client = Client.fromJson(json.decode(response.body));
    } else {
      _client = null; // Limpa o cliente em caso de erro
    }
    notifyListeners();
  }
}
