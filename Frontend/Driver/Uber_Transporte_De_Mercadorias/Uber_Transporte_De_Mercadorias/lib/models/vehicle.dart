class Vehicle {
  final int year;
  final String plate;
  final String brand;
  final String model;
  final String vehicleType;
  final double capacity;

  Vehicle({
    required this.year,
    required this.plate,
    required this.brand,
    required this.model,
    required this.vehicleType,
    required this.capacity,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      year: json['year'],
      plate: json['plate'],
      brand: json['brand'],
      model: json['model'],
      vehicleType: json['vehicleType'],
      capacity: (json['capacity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'plate': plate,
      'brand': brand,
      'model': model,
      'vehicleType': vehicleType,
      'capacity': capacity,
    };
  }

  static defaultVehicle() {}
}
