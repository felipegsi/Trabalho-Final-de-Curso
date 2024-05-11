import 'package:projeto_proj/models/vehicle.dart';

class Driver {
  final String name;
  final String email;
  final String password; // Be careful with including sensitive data like passwords
  final String phoneNumber;
  final int taxPayerNumber;
  final String street;
  final String city;
  final int postalCode;
  final double salary;
  final bool isOnline;
  final Vehicle? vehicle; // Ensure the Vehicle class also has a fromJson constructor if needed
  final String location;
  final String birthdate;

  Driver({
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.taxPayerNumber,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.salary,
    this.isOnline = false,
    required this.vehicle,
    required this.location,
    required this.birthdate,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      name: json['name'] as String? ?? 'Default Name',
      email: json['email'] as String? ?? 'default@example.com',
      password: json['password'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? 'No Phone',
      taxPayerNumber: json['taxPayerNumber'] as int? ?? 0,
      street: json['street'] as String? ?? 'No Street',
      city: json['city'] as String? ?? 'No City',
      postalCode: json['postalCode'] as int? ?? 0,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['isOnline'] as bool? ?? false,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>) : null,
      location: json['location'] as String? ?? 'No Location',
      birthdate: json['birthdate'] as String? ?? 'No Birthdate',
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
      'postalCode': postalCode,
      'salary': salary,
      'isOnline': isOnline,
      'vehicle': vehicle?.toJson(),
      'location': location,
      'birthdate': birthdate,
    };
  }

}
