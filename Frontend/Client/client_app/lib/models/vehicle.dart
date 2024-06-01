class VehicleDto {
  int year;
  String plate;
  String brand;
  String model;
  double capacity;
  String vehicleType;

  VehicleDto({
    required this.year,
    required this.plate,
    required this.brand,
    required this.model,
    required this.capacity,
    required this.vehicleType,
  });

  factory VehicleDto.fromJson(Map<String, dynamic> json) {
    return VehicleDto(
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