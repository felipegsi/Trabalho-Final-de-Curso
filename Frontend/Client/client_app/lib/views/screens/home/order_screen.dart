import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  StompClient? stompClient;
  String receivedMessage = "";
  final String myUserId = "senha123"; // Identificador do usuário


  @override
  void initState() {
    super.initState();
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
      ),
    );
    stompClient?.activate();
  }

  void onConnect(StompFrame frame) {
    stompClient?.subscribe(
      destination: '/queue/driver/reply-$myUserId',
      callback: (frame) {
        setState(() {
          receivedMessage = frame.body ?? '';
        });
      },
    );
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
        title: Text('Mensagens para $myUserId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
