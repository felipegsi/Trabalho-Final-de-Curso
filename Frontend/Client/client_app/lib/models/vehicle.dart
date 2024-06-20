class Vehicle {
  int year;
  String plate;
  String brand;
  String model;
  String category;

  Vehicle({
    required this.year,
    required this.plate,
    required this.brand,
    required this.model,
    required this.category,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      year: json['year'],
      plate: json['plate'],
      brand: json['brand'],
      model: json['model'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'plate': plate,
      'brand': brand,
      'model': model,
      'category': category,
    };
  }
}