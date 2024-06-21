class Client {
  final String name;
  final String email;
  //final String? password;// nao deve aparecer em todos os lugares
  final String birthdate;
  final String phoneNumber;
  final int taxPayerNumber;
  final String street;
  final String city;
  final String postalCode;

  Client({
    required this.name,
    required this.email,
   // this.password,
    required this.birthdate,
    required this.phoneNumber,
    required this.taxPayerNumber,
    required this.street,
    required this.city,
    required this.postalCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      //'password': password,
      'birthdate': birthdate,
      'phoneNumber': phoneNumber,
      'taxPayerNumber': taxPayerNumber,
      'street': street,
      'city': city,
      'postalCode': postalCode,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      name: json['name'],
      email: json['email'],
      birthdate: json['birthdate'],
      phoneNumber: json['phoneNumber'],
      taxPayerNumber: json['taxPayerNumber'],
      street: json['street'],
      city: json['city'],
      postalCode: json['postalCode'],
    );
  }
}
