import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:projeto_proj/models/order.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
//import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class OrderApi with ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String baseUrl = 'http://10.0.2.2:8080/driver';
  bool _isOnline = false;
  StompClient? _stompClient;
  String? _driverId;
  String? _orderId;
  Function(String)? onNewOrder;
  LatLng? _currentLocation;
  Order? _order;
  bool _isTogglingStatus = false;
  Completer<void>? _connectionCompleter;

  bool get isOnline => _isOnline;

  String? get orderId => _orderId;

  LatLng? get currentLocation => _currentLocation;

  Order? get order => _order;

  bool get isTogglingStatus => _isTogglingStatus;

  void setOnlineStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }

  //TODO: nao preciso sempre ir buscar o token,  tentar criar uma variavel global para o token e armazenar ele

  Future<void> getOrderById(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/getOrder/$orderId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      _order = Order.fromJson(jsonResponse);
     // print('\n\n\n\nOrder fetched: ${_order!.client?.name}');
      notifyListeners();
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
      setOnlineStatus(isOnline);
      return isOnline;
    } else {
      throw Exception('Failed to fetch driver status');
    }
  }

  Future<bool> pickupOrderStatus(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/pick-up/$orderId');
    final response = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      print('Order status updated');
      return true;
    } else {
      throw Exception('Failed to fetch order status');
    }
  }

  Future<bool> deliverOrderStatus(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/deliver/$orderId');
    final response = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      print('Order status updated');
      return true;
    } else {
      throw Exception('Failed to fetch order status');
    }
  }

  Future<bool> cancelledOrderStatus(int orderId) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('$baseUrl/cancelled/$orderId');
    final response = await http.put(url, headers: {
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      print('Order status updated');
      return true;
    } else {
      throw Exception('Failed to fetch order status');
    }
  }

  Future<bool> setDriverOnline(String location) async {
    if (_isOnline || _isTogglingStatus) return true; // Evita duplicação
    _isTogglingStatus = true;

    try {
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
        await _loadDriverId();
        _isOnline = true;
        notifyListeners();
        await _connectStompDriver();
        return true;
      } else {
        return false;
      }
    } finally {
      _isTogglingStatus = false;
    }
  }

  Future<bool> setDriverOffline() async {
    if (!_isOnline || _isTogglingStatus) return true; // Evita duplicação
    _isTogglingStatus = true;

    try {
      String? token = await storage.read(key: 'token');
      if (token == null) throw Exception('No token found');

      final url = Uri.parse('$baseUrl/offline');
      final response = await http.put(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        _isOnline = false;
        notifyListeners();
        await _disconnectStompDriver();
        return true;
      } else {
        return false;
      }
    } finally {
      _isTogglingStatus = false;
    }
  }

  //pode mandar a localização do motorista para o servidor de forma assíncrona, ou seja, sem bloquear a execução do código
  void sendLocationToServer(String location) async {
    String? token = await storage.read(key: 'token');
    if (token == null) throw Exception('No token found');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/setCurrentLocation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: location,
      );

      if (response.statusCode == 200) {
        print('\n\nLocalização enviada com sucesso: ' + '$location' + '\n\n');
      } else {
        print('\n\nFalha ao enviar localização: ${response.statusCode}');
      }
    } catch (e) {
      print('\n\nErro ao enviar localização: $e');
    }
  }

  Future<void> _connectStompDriver() async {
    if (_driverId == null) throw Exception('Driver ID is not loaded');
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      return _connectionCompleter!
          .future; // Returns the existing connection future
    }
    _connectionCompleter = Completer();
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws-endpoint/websocket',
        onConnect: (StompFrame frame) {
          _stompClient?.subscribe(
            destination: '/queue/driver/reply-$_driverId',
            callback: (frame) {
              _orderId = frame.headers['orderId'];
              _showOrderNotification(frame.body ?? '');
            },
          );
          _connectionCompleter?.complete(); // Marks the connection as complete
        },
        onStompError: (StompFrame frame) {
          _connectionCompleter
              ?.completeError(Exception('STOMP Error: ${frame.body}'));
          print('STOMP Error: ${frame.body}');
        },
        onWebSocketError: (dynamic error) {
          _connectionCompleter
              ?.completeError(Exception('WebSocket Error: $error'));
          print('WebSocket Error: $error');
        },
        onDisconnect: (frame) {
          print('STOMP Disconnected');
        },
      ),
    );
    _stompClient?.activate();
  }

  Future<void> _disconnectStompDriver() async {
    if (_stompClient != null) {
      _stompClient?.deactivate();
      _stompClient = null;
      _orderId = null;
      _connectionCompleter = null;
    }
  }

  void _showOrderNotification(String message) {
    if (message.isNotEmpty && onNewOrder != null) {
      onNewOrder!(message);
    }
  }

  void sendResponse(String response) {
    if (_stompClient != null && _orderId != null && _orderId!.isNotEmpty) {
      _stompClient!.send(
        destination: '/app/driver/reply-$_driverId',
        body: json.encode({
          'orderId': _orderId,
          'response': response,
        }),
        headers: {
          'content-type': 'application/json',
        },
      );

      /*if (response == 'sim') {
        disconnectStompClient();
      }*/
    } else {
      print("Erro: StompClient ou currentOrderId é nulo.");
    }
  }
}
