import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';

class ApiResult {
  final List<Vehicle> vehicles;
  final int atTerminus;
  final bool gtfsLoaded;
  final int tripsInDb;

  const ApiResult({
    required this.vehicles,
    required this.atTerminus,
    required this.gtfsLoaded,
    required this.tripsInDb,
  });
}

class ApiService {
  static const String baseUrl = 'https://mpk-rzeszow-tracker.onrender.com';

  static Future<ApiResult> fetchVehicles() async {
    final resp = await http
        .get(Uri.parse('$baseUrl/api/vehicles'))
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }

    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error']);

    final vehicles = (data['vehicles'] as List)
        .map((v) => Vehicle.fromJson(v as Map<String, dynamic>))
        .where((v) => v.lat != 0 && v.lon != 0)
        .toList();

    return ApiResult(
      vehicles: vehicles,
      atTerminus: (data['atTerminus'] ?? 0) as int,
      gtfsLoaded: (data['gtfsLoaded'] ?? false) as bool,
      tripsInDb: (data['tripsInDb'] ?? 0) as int,
    );
  }
}
