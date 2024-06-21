// order_api.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_proj/models/order.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class OrderApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  bool _isOnline = false;
  StompClient? _stompClient;
  String? _driverId;
  String? _currentOrderId;
  Function(String)? onNewOrder; // Callback para novas mensagens

  bool get isOnline => _isOnline;
  String? get currentOrderId => _currentOrderId;

  // Método para definir o estado online e notificar os ouvintes
  void setOnlineStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }

  Future<Order> getOrderById(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/getOrder/$orderId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return Order.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to load order');
    }
  }


  Future<void> _loadDriverId() async {
    _driverId = await storage.read(key: 'driverId');
    if (_driverId == null) throw Exception('Driver ID not found');
  }

  Future<bool> fetchDriverStatus() async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/checkDriverStatus');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      final isOnline = json.decode(response.body) as bool;
      setOnlineStatus(isOnline); // Atualiza o estado
      return isOnline;
    } else {
      throw Exception('Failed to fetch driver status');
    }
  }

  Future<bool> setDriverOnline(String location) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/online');
    final response = await http.put(url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'location': location}));

    if (response.statusCode == 200) {
      await _loadDriverId(); // Carrega o ID do motorista
      setOnlineStatus(true);
      connectStompClient(); // Conecta ao WebSocket
      return true;
    } else {
      return false;
    }
  }

  Future<bool> setDriverOffline() async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/offline');
    final response = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      setOnlineStatus(false);
      disconnectStompClient(); // Desconecta do WebSocket
      return true;
    } else {
      return false;
    }
  }

  void connectStompClient() {
    if (_driverId == null) throw Exception('Driver ID is not loaded');

    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws-endpoint/websocket',
        onConnect: (StompFrame frame) {
          _stompClient?.subscribe(
            destination: '/queue/driver/reply-$_driverId',
            callback: (frame) {
              _currentOrderId = frame.headers['orderId']; // Atualiza o ID do pedido atual
              _showOrderNotification(frame.body ?? '');
            },
          );
        },
        onStompError: (StompFrame frame) {
          print('STOMP Error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket Error: $error');
        },
        onDisconnect: (frame) {
          print('STOMP Disconnected');
        },
      ),
    );
    _stompClient?.activate();
  }

  void disconnectStompClient() {
    _stompClient?.deactivate();
    _stompClient = null;
    _currentOrderId = null; // Limpa o ID do pedido atual quando desconecta
  }

  void _showOrderNotification(String message) {
    if (message.isNotEmpty && onNewOrder != null) {
      onNewOrder!(message);
    }
  }

  void sendResponse(String response) {
    if (_stompClient != null && _currentOrderId != null && _currentOrderId!.isNotEmpty) {
      _stompClient!.send(
        destination: '/app/driver/reply-$_driverId',
        body: json.encode({
          'orderId': _currentOrderId,
          'response': response,
        }),
        headers: {
          'content-type': 'application/json',
        },
      );
    } else {
      print("Erro: StompClient ou currentOrderId é nulo.");
    }
  }
}
