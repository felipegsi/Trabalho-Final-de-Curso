import 'package:teste_2/models/vehicle.dart';

class Driver {
  final int id;
  final String name;
  final String email;
  final String birthdate;
  final String phoneNumber;
  final int taxPayerNumber;
  final String street;
  final String city;
  final String postalCode;
  String location;
  final Vehicle vehicle;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.birthdate,
    required this.phoneNumber,
    required this.taxPayerNumber,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.location,
    required this.vehicle,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      birthdate: json['birthdate'],
      phoneNumber: json['phoneNumber'],
      taxPayerNumber: json['taxPayerNumber'],
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'],
      location: json['location'],
      vehicle: Vehicle.fromJson(json['vehicleDto']), // tive problemas aqui, nao alterar
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'birthdate': birthdate,
      'phoneNumber': phoneNumber,
      'taxPayerNumber': taxPayerNumber,
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'location': location,
      'vehicle': vehicle.toJson(),
    };
  }
}