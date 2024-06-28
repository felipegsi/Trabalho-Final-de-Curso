// Dentro de /lib/models/order.dart
import 'package:decimal/decimal.dart';
import 'client.dart';
import 'driver.dart';

class Order {
  final int? id; // pode ser nulo quando ainda estiver fazendo o pedido
  final String origin;
  final String destination;
  final Decimal? value; // Supondo que o valor seja um BigDecimal
  String? status; // Adicionei um status para o pedido
  final String? description;
  final String? feedback; // inicialmente é nulo quando o utilizador ainda nao efetuou o pedido
  final String category; // Supondo que a categoria seja uma string
  // fields for non-motorized category
  final int? width; // podem ser nulos quando a categoria for motorizada
  final int? height;
  final int? length;
  final double? weight;
  // fields for motorized category
  final String? plate; // podem ser nulos quando a categoria não for motorizada
  final String? model;
  final String? brand;

  final String? date;
  final String? time;
  final Client? client;
  final Driver? driver;

  Order({
    this.id,
    required this.origin,
    required this.destination,
    this.value,
    this.status,
    this.description,
    this.feedback,
    required this.category,
    this.width,
    this.height,
    this.length,
    this.weight,
    this.plate,
    this.model,
    this.brand,
    this.date,
    this.time,
    this.client,
    this.driver,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'value': value?.toString(),
      'status': status,
      'description': description,
      'feedback': feedback,
      'category': category,
      'width': width,
      'height': height,
      'length': length,
      'weight': weight,
      'plate': plate,
      'model': model,
      'brand': brand,
      'date': date,
      'time': time,
      'client': client?.toJson(),
      'driver': driver?.toJson(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] != null ? json['id'] as int : null,
      origin: json['origin'] as String? ?? 'Unknown Origin',
      destination: json['destination'] as String? ?? 'Unknown Destination',
      value: json['value'] != null ? Decimal.tryParse(json['value'].toString()) : null,
      status: json['status'] as String?,
      description: json['description'] as String?,
      feedback: json['feedback'] as String?,
      category: json['category'] as String? ?? 'Unknown Category',
      width: json['width'] != null ? json['width'] as int : null,
      height: json['height'] != null ? json['height'] as int : null,
      length: json['length'] != null ? json['length'] as int : null,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      plate: json['plate'] as String?,
      model: json['model'] as String?,
      brand: json['brand'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      client: json['client'] != null ? Client.fromJson(json['client'] as Map<String, dynamic>) : null,
      driver: json['driver'] != null ? Driver.fromJson(json['driver'] as Map<String, dynamic>) : null,
    );
  }

}
