import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  /// Determina a posição atual do dispositivo.
  Future<LatLng?> determinePosition() async {
    try {
      // Verifica se o serviço de localização está habilitado.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null; // Retorna null se o serviço de localização estiver desabilitado.
      }

      // Verifica e solicita permissão de localização.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          print('Location permissions are denied.');
          return null; // Retorna null se a permissão for negada.
        }
      }

      // Se a permissão estiver negada para sempre, retorna null.
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        return null;
      }

      // Obtém a posição atual com alta precisão.
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Retorna a posição como LatLng.
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Failed to get location: $e');
      return null; // Retorna null se ocorrer uma exceção.
    }
  }
}
