import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'dart:convert';

import '../../../api/auth_api.dart';

class WaitingOrderScreen extends StatefulWidget {
  const WaitingOrderScreen({super.key});

  @override
  State<WaitingOrderScreen> createState() => _WaitingOrderScreenState();
}

class _WaitingOrderScreenState extends State<WaitingOrderScreen> {
  StompClient? stompClient;
  String receivedMessage = "";
  String? currentOrderId;
  late String myUserId;

  Future<void> _loadDriverId() async {
    final authApi = Provider.of<AuthApi>(context, listen: false);
    myUserId = (await authApi.getDriverId()) ?? "";
    setState(() {}); // Atualiza o widget após a inicialização
    _connectStompClient(); // Conecta ao WebSocket após obter o ID do motorista
  }

  void _connectStompClient() {
    stompClient = StompClient(
      config: StompConfig(
        url: 'ws://10.0.2.2:8080/ws-endpoint/websocket',
        onConnect: onConnect,
        onStompError: (frame) {
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
    stompClient?.activate();
  }

  void onConnect(StompFrame frame) {
    stompClient?.subscribe(
      destination: '/queue/driver/reply-$myUserId',
      callback: (frame) {
        print("Recebendo mensagem: ${frame.body} com headers: ${frame.headers}");
        setState(() {
          currentOrderId = frame.headers['orderId'];
          receivedMessage = frame.body ?? '';
          print("Atualizando currentOrderId: $currentOrderId");
          _showPopup(receivedMessage);
        });
      },
    );
  }

  void _showPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nova Mensagem'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                sendDriverResponse('sim');
                Navigator.of(context).pop();
              },
              child: const Text('Aceitar'),
            ),
            TextButton(
              onPressed: () {
                sendDriverResponse('não');
                Navigator.of(context).pop();
              },
              child: const Text('Rejeitar'),
            ),
          ],
        );
      },
    );
  }

  void sendDriverResponse(String response) {
    if (stompClient != null && currentOrderId != null && currentOrderId!.isNotEmpty) {
      stompClient!.send(
        destination: '/app/driver/reply-$myUserId',
        body: json.encode({
          'orderId': currentOrderId,
          'response': response
        }),
        headers: {
          'content-type': 'application/json',
        },
      );
      setState(() {
        receivedMessage = "";
        currentOrderId = null;
      });
    } else {
      print("Erro: stompClient ou currentOrderId é nulo.");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDriverId();
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esperando Pedidos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Mensagem recebida:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(receivedMessage.isNotEmpty ? receivedMessage : 'Nenhuma mensagem recebida.'),
          ],
        ),
      ),
    );
  }
}
