import 'package:teste_2/models/vehicle.dart';

class Driver {
  final String name;
  final String email;
  final String birthdate;
  final String phoneNumber;
  final int taxPayerNumber;
  final String street;
  final String city;
  final int postalCode;
  final VehicleDto vehicleDto;

  Driver({
    required this.name,
    required this.email,
    required this.birthdate,
    required this.phoneNumber,
    required this.taxPayerNumber,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.vehicleDto,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      name: json['name'],
      email: json['email'],
      birthdate: json['birthdate'],
      phoneNumber: json['phoneNumber'],
      taxPayerNumber: json['taxPayerNumber'],
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'],
      vehicleDto: VehicleDto.fromJson(json['vehicleDto']),
    );
  }
}