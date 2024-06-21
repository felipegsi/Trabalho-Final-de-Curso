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
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

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

  void sendMessageToUser(String userId, String message) {
    if (stompClient != null && stompClient!.connected) {
      stompClient!.send(
        destination: '/app/user-message-$userId',
        body: message,
      );
    }
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    userIdController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter WebSocket STOMP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Mensagem de algum outro usuário é: $receivedMessage'),
            const SizedBox(height: 20),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: 'ID do usuário destinatário'),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: 'Mensagem'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sendMessageToUser(userIdController.text, messageController.text),
              child: const Text('Enviar mensagem ao usuário'),
            ),
          ],
        ),
      ),
    );
  }
}
