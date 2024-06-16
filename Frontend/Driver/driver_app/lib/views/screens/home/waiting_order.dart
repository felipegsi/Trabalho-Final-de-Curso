import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import 'dart:convert';

import '../../../services/network_service.dart';

class WaitingOrderScreen extends StatefulWidget {
  const WaitingOrderScreen({super.key});

  @override
  State<WaitingOrderScreen> createState() => _WaitingOrderScreenState();
}


class _WaitingOrderScreenState extends State<WaitingOrderScreen> {
  StompClient? stompClient;
  String receivedMessage = "";
  String? currentOrderId; // Para armazenar o ID do pedido atual
  final networkService = NetworkService();
  late String myUserId;

  Future<void> _loadDriverId() async {
    myUserId = await networkService.getDriverIdFromToken();
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
      ),
    );
    stompClient?.activate();
  }

  void onConnect(StompFrame frame) {
    stompClient?.subscribe(
      destination: '/queue/driver/reply-$myUserId',
      callback: (frame) {
        print("Recebendo mensagem: ${frame.body} com headers: ${frame.headers}"); // Log adicional
        setState(() {
          currentOrderId = frame.headers?['orderId']; // Armazena o ID do pedido atual
          receivedMessage = frame.body ?? '';
          print("Atualizando currentOrderId: $currentOrderId"); // Log adicional
        });
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
        title: Text('Esperando Pedidos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mensagem recebida:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(receivedMessage.isNotEmpty ? receivedMessage : 'Nenhuma mensagem recebida.'),
            if (receivedMessage.isNotEmpty) ...[
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => sendDriverResponse('sim'),
                    child: Text('Aceitar'),
                  ),
                  ElevatedButton(
                    onPressed: () => sendDriverResponse('não'),
                    child: Text('Rejeitar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}