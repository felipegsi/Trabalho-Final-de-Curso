class TravelInformation {
  final String driverLocation;
  final String orderStatus;
 // final String distance;
 // final String duration;


  TravelInformation({
    required this.driverLocation,
    required this.orderStatus,
   // required this.distance,
   // required this.duration,
  });

  factory TravelInformation.fromJson(Map<String, dynamic> json) {
    return TravelInformation(
      driverLocation: json['driverLocation'] as String,
      orderStatus: json['orderStatus'] as String,
     // distance: json['distance'] as String,
     // duration: json['duration'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverLocation': driverLocation,
      'orderStatus': orderStatus,
     // 'distance': distance,
     // 'duration': duration,
    };
  }



}