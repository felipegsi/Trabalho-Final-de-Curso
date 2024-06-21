import 'package:projeto_proj/models/vehicle.dart';

class Driver {
  final String name;
  final String email;
  final String? password; // Be careful with including sensitive data like passwords
  final String birthdate;
  final String phoneNumber;
  final int taxPayerNumber;
  final String street;
  final String city;
  final String postalCode; // Update type to String
  final double? salary;
  final bool? isOnline; // Ensure nullable type
  final bool? isBusy; // New attribute
  final Vehicle? vehicle; // Ensure the Vehicle class also has a fromJson constructor if needed
  final String? location;

  Driver({
    required this.name,
    required this.email,
    this.password,
    required this.birthdate,
    required this.phoneNumber,
    required this.taxPayerNumber,
    required this.street,
    required this.city,
    required this.postalCode,
    this.salary,
    this.isOnline = false,
    this.isBusy = false, // Default to false
    required this.vehicle,
    this.location,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      phoneNumber: json['phoneNumber'],
      taxPayerNumber: json['taxPayerNumber'] ,
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'], // Update type to String
      salary: json['salary'],
      isOnline: json['isOnline'],
      isBusy: json['isBusy'], // New attribute
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) : null,
      location: json['location'],
      birthdate: json['birthdate'],
    );
  }

  factory Driver.fromJsonViewProfile(Map<String, dynamic> json) {
    return Driver(
      name: json['name'],
      email: json['email'],
      birthdate: json['birthdate'],
      phoneNumber: json['phoneNumber'],
      taxPayerNumber: json['taxPayerNumber'] ,
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'], // Update type to String
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'taxPayerNumber': taxPayerNumber,
      'street': street,
      'city': city,
      'postalCode': postalCode, // Update type to String
      'salary': salary,
      'isOnline': isOnline,
      'isBusy': isBusy, // New attribute
      'vehicle': vehicle?.toJson(),
      'location': location,
      'birthdate': birthdate,
    };
  }
}
