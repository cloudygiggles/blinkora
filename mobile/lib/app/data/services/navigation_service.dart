import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Custom exceptions untuk navigation service
class NavigationException implements Exception {
  final String message;
  NavigationException(this.message);

  @override
  String toString() => 'NavigationException: $message';
}

class RouteCalculationException extends NavigationException {
  RouteCalculationException(String message) : super(message);
}

class OSRMServiceException extends NavigationException {
  OSRMServiceException(String message) : super(message);
}

/// Service untuk menghitung rute menggunakan OSRM API
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // OSRM Public Instance
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  
  static final LatLng blinkDestination = LatLng(-7.894947838601242, 112.66418409815083);

  /// Dapatkan rute dari start ke destination
  /// [start]: Koordinat start 
  /// [destination]: Koordinat tujuan
  /// Returns: Map berisi data rute dari OSRM
  Future<Map<String, dynamic>> getRoute(
    LatLng start, 
    LatLng destination,
  ) async {
    try {
      final String url =
          '$_baseUrl/driving/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&steps=true';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Validasi response OSRM
        if (data['code'] != 'Ok') {
          throw OSRMServiceException('OSRM returned error: ${data['code']}');
        }
        
        if (data['routes'] == null || data['routes'].isEmpty) {
          throw RouteCalculationException('No route found between points');
        }

        return data;
      } else {
        throw OSRMServiceException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}'
        );
      }
    } catch (e) {
      if (e is NavigationException) {
        rethrow;
      }
      throw OSRMServiceException('Failed to calculate route: $e');
    }
  }

  /// Decode polyline dari GeoJSON format OSRM ke List<LatLng>
  /// [routeData]: Data rute dari OSRM
  /// Returns: List koordinat untuk polyline
  List<LatLng> decodePolyline(Map<String, dynamic> routeData) {
    try {
      final geometry = routeData['routes'][0]['geometry'];
      final coordinates = geometry['coordinates'] as List<dynamic>;
      
      return coordinates.map<LatLng>((coord) {
        // GeoJSON format: [longitude, latitude]
        return LatLng(coord[1].toDouble(), coord[0].toDouble());
      }).toList();
    } catch (e) {
      throw RouteCalculationException('Failed to decode route geometry: $e');
    }
  }

  /// Dapatkan informasi rute (jarak, durasi)
  /// [routeData]: Data rute dari OSRM
  /// Returns: Map berisi distance (meter) dan duration (detik)
  Map<String, dynamic> getRouteInfo(Map<String, dynamic> routeData) {
    try {
      final route = routeData['routes'][0];
      return {
        'distance': route['distance'].toDouble(), // dalam meter
        'duration': route['duration'].toDouble(), // dalam detik
      };
    } catch (e) {
      throw RouteCalculationException('Failed to extract route info: $e');
    }
  }

  /// Dapatkan turn-by-turn instructions
  /// [routeData]: Data rute dari OSRM
  /// Returns: List instructions
  List<Map<String, dynamic>> getRouteInstructions(Map<String, dynamic> routeData) {
    try {
      final List<dynamic> legs = routeData['routes'][0]['legs'];
      final List<Map<String, dynamic>> instructions = [];

      for (final leg in legs) {
        final List<dynamic> steps = leg['steps'];
        for (final step in steps) {
          instructions.add({
            'instruction': step['maneuver']['instruction'],
            'distance': step['distance'],
            'duration': step['duration'],
            'type': step['maneuver']['type'],
          });
        }
      }

      return instructions;
    } catch (e) {
      // Return empty list jika error, karena instructions optional
      return [];
    }
  }

  /// Format distance untuk display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Format duration untuk display
  String formatDuration(double seconds) {
    if (seconds < 60) {
      return '${seconds.round()} detik';
    } else if (seconds < 3600) {
      return '${(seconds / 60).round()} menit';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).round();
      return '$hours jam $minutes menit';
    }
  }

  /// Validasi koordinat
  bool isValidCoordinate(LatLng coord) {
    return coord.latitude >= -90 && 
           coord.latitude <= 90 && 
           coord.longitude >= -180 && 
           coord.longitude <= 180;
  }

  /// Getter untuk destination
  LatLng get destination => blinkDestination;

  /// Method untuk mengubah destination jika diperlukan
  void setDestination(LatLng newDestination) {
    // Dalam implementasi real, Anda mungkin ingin menyimpan ini di persistent storage
    // Untuk sekarang kita tetap menggunakan static dummyDestination
    // dummyDestination = newDestination;
  }
}