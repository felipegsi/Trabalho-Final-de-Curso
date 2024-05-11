import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? channel;

  void connect(String url) {
    channel = WebSocketChannel.connect(Uri.parse(url));
    channel!.stream.listen((message) {
      print('New message: $message');
      // Aqui você pode adicionar lógica para manipular mensagens recebidas
    }, onDone: () {
      print('WebSocket connection closed');
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  void sendMessage(String message) {
    if (channel != null) {
      channel!.sink.add(message);
    } else {
      print("WebSocket not connected.");
    }
  }

  void close() {
    if (channel != null) {
      channel!.sink.close();
    }
  }
}
