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

class Stop {
  final String id, name;
  final double lat, lon;
  const Stop({required this.id, required this.name, required this.lat, required this.lon});
  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
    id: j['id'] ?? '', name: j['name'] ?? '', lat: (j['lat']??0).toDouble(), lon: (j['lon']??0).toDouble());
}

class Departure {
  final String lineNr, headsign, departure;
  final int diffMins;
  const Departure({required this.lineNr, required this.headsign, required this.departure, required this.diffMins});
  factory Departure.fromJson(Map<String, dynamic> j) => Departure(
    lineNr: j['lineNr'] ?? '', headsign: j['headsign'] ?? '',
    departure: j['departure'] ?? '', diffMins: (j['diffMins'] ?? 0).toInt());
}

extension ScheduleApi on ApiService {
  static Future<List<Stop>> fetchStops(String query) async {
    final q = query.trim();
    final uri = q.isEmpty
        ? Uri.parse('${ApiService.baseUrl}/api/stops?limit=9999')
        : Uri.parse('${ApiService.baseUrl}/api/stops?q=${Uri.encodeComponent(q)}&limit=9999');
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    final data = json.decode(resp.body);
    return (data['stops'] as List).map((s) => Stop.fromJson(s)).toList();
  }

  static Future<Map<String, dynamic>> fetchDepartures(String stopId) async {
    final resp = await http.get(Uri.parse('${ApiService.baseUrl}/api/departures?stop_id=${Uri.encodeComponent(stopId)}'))
        .timeout(const Duration(seconds: 10));
    return json.decode(resp.body);
  }
}

class BusRoute {
  final String id, lineNr;
  const BusRoute({required this.id, required this.lineNr});
  factory BusRoute.fromJson(Map<String, dynamic> j) =>
      BusRoute(id: j['id'] ?? '', lineNr: j['lineNr'] ?? '');
}

class RouteSchedule {
  final String routeId, lineNr;
  final Map<String, List<ScheduleTrip>> variants; // headsign → trips
  const RouteSchedule({required this.routeId, required this.lineNr, required this.variants});
  factory RouteSchedule.fromJson(Map<String, dynamic> j) {
    final raw = j['variants'] as Map<String, dynamic>? ?? {};
    final variants = raw.map((head, trips) => MapEntry(
      head,
      (trips as List).map((t) => ScheduleTrip.fromJson(t)).toList(),
    ));
    return RouteSchedule(routeId: j['routeId'] ?? '', lineNr: j['lineNr'] ?? '', variants: variants);
  }
}

class ScheduleTrip {
  final String tripId, headsign;
  final List<ScheduleStop> stops;
  const ScheduleTrip({required this.tripId, required this.headsign, required this.stops});
  factory ScheduleTrip.fromJson(Map<String, dynamic> j) => ScheduleTrip(
    tripId: j['tripId'] ?? '',
    headsign: j['headsign'] ?? '',
    stops: (j['stops'] as List? ?? []).map((s) => ScheduleStop.fromJson(s)).toList(),
  );
  String get firstDeparture => stops.isNotEmpty ? stops.first.departure : '';
  String get firstDep5 => firstDeparture.length >= 5 ? firstDeparture.substring(0, 5) : firstDeparture;
}

class ScheduleStop {
  final String stopId, stopName, departure;
  const ScheduleStop({required this.stopId, required this.stopName, required this.departure});
  factory ScheduleStop.fromJson(Map<String, dynamic> j) => ScheduleStop(
    stopId: j['stopId'] ?? '', stopName: j['stopName'] ?? '', departure: j['departure'] ?? '');
  String get dep5 => departure.length >= 5 ? departure.substring(0, 5) : departure;
}

extension RouteApi on ApiService {
  static Future<List<BusRoute>> fetchRoutes() async {
    final resp = await http.get(Uri.parse('${ApiService.baseUrl}/api/routes'))
        .timeout(const Duration(seconds: 10));
    final data = json.decode(resp.body);
    return (data['routes'] as List).map((r) => BusRoute.fromJson(r)).toList();
  }

  static Future<RouteSchedule> fetchSchedule(String lineNr) async {
    final resp = await http
        .get(Uri.parse('${ApiService.baseUrl}/api/schedule?line_nr=${Uri.encodeComponent(lineNr)}'))
        .timeout(const Duration(seconds: 15));
    return RouteSchedule.fromJson(json.decode(resp.body));
  }
}
