class Vehicle {
  int year;
  String plate;
  String brand;
  String model;
  double capacity;
  String vehicleType;

  Vehicle({
    required this.year,
    required this.plate,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.vehicleType,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      year: json['year'],
      plate: json['plate'],
      brand: json['brand'],
      model: json['model'],
      capacity: json['capacity'],
      vehicleType: json['vehicleType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'plate': plate,
      'brand': brand,
      'model': model,
      'capacity': capacity,
      'vehicleType': vehicleType,
    };
  }
}