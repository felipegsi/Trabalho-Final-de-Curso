// Dentro de /lib/models/order.dart
import 'dart:ffi';

import 'package:decimal/decimal.dart';

class Order {
  final Long? id; // pode ser nulo quando ainda estiver fazendo o pedido
  final String origin;
  final String destination;
  final String? description;
  final String? feedback;

  final String category; // Supondo que a categoria seja uma string
  // fields to non-motorized category
  final int? width;
  final int? height;
  final int? length;
  final double? weight;
  // fields to motorized category
  final String? plate;
  final String? model;
  final String? brand;

  final Decimal? value; // Supondo que o valor seja um BigDecimal
  final String? status; // Adicionei um status para o pedido
  final DateTime? data; // Adicionei a data combinada com o time


  Order({
    this.id,
    required this.origin,
    required this.destination,
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
    this.value,
    this.status,
    this.data,
  });



  // Adiciona o método toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'description': description,
      'feedback': feedback,
      'category': category, // Converte o enum em String
      'width': width,
      'height': height,
      'length': length,
      'weight': weight,
      'value': value,
      'status': status,
      'data': data,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      origin: json['origin'],
      destination: json['destination'],
      description: json['description'],
      feedback: json['feedback'],
      category: json['category'],
      width: json['width'] as int?,
      height: json['height'] as int?,
      length: json['length'] as int?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      value: json['value'] != null ? Decimal.parse(json['value'].toString()) : null,
      status: json['status'],
      data: json['data'] != null ? DateTime.parse(json['data']) : null,
    );
  }

}
