import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  LatLng? _currentPosition;
  String? _placeName;

  LatLng? get currentPosition => _currentPosition;
  String? get placeName => _placeName;

  Future<LatLng?> requestAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = LatLng(position.latitude, position.longitude);
      _placeName = await _reverseGeocode(position.latitude, position.longitude);
      return _currentPosition;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&zoom=12',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'Loomea/1.0 (com.example.loomea)',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final neighbourhood = address['neighbourhood'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String?
              ?? address['town'] as String?
              ?? address['village'] as String?;
          final state = address['state'] as String?;
          final parts = [
            neighbourhood ?? suburb,
            city ?? state,
          ].whereType<String>().toList();
          if (parts.isNotEmpty) return parts.join(', ');
        }
      }
    } catch (_) {}
    return null;
  }
}
