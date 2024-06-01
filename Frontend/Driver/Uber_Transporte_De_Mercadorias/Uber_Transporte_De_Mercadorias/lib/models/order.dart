import 'package:intl/intl.dart';

class Order {
  final int id;
  final String origin;
  final String destination;
  final double value; // Usando double aqui, Dart não tem BigDecimal
  final String status; // Usando String para representar o enum, pode ser convertido conforme necessário
  final DateTime dateTime; // Combinando date e time em um único campo DateTime
  final String description;
  final String feedback;
  final int clientId; // Supondo que você armazene apenas o ID do cliente
  final String category; // Usando String para representar o enum Category
  final int driverId; // Supondo que você armazene apenas o ID do motorista

  Order({
    required this.id,
    required this.origin,
    required this.destination,
    required this.value,
    required this.status,
    required this.dateTime,
    this.description = '',
    this.feedback = '',
    required this.clientId,
    required this.category,
    required this.driverId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      origin: json['origin'],
      destination: json['destination'],
      value: json['value'].toDouble(), // Converte de BigDecimal para double
      status: json['status'],
      dateTime: DateTime.parse(json['date'] + "T" + json['time']), // Combina date e time
      description: json['description'] ?? '',
      feedback: json['feedback'] ?? '',
      clientId: json['client']['id'], // Supondo que o cliente é retornado como um objeto
      category: json['category'],
      driverId: json['driver']['id'], // Supondo que o motorista é retornado como um objeto
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'value': value,
      'status': status,
      'date': DateFormat('yyyy-MM-dd').format(dateTime),
      'time': DateFormat('HH:mm:ss').format(dateTime),
      'description': description,
      'feedback': feedback,
      'client': {'id': clientId},
      'category': category,
      'driver': {'id': driverId},
    };
  }
}
