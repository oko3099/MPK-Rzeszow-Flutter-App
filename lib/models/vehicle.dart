class Vehicle {
  final String id;
  final String vehicleLabel;
  final String lineNr;
  final String? headsign;
  final String? brigade;
  final String? brand;
  final String? model;
  final double lat;
  final double lon;
  final int? delay;
  final double? bearing;
  final bool atTerminus;
  final String? statusLabel;
  final String? occupancy;

  const Vehicle({
    required this.id,
    required this.vehicleLabel,
    required this.lineNr,
    this.headsign,
    this.brigade,
    this.brand,
    this.model,
    required this.lat,
    required this.lon,
    this.delay,
    this.bearing,
    this.atTerminus = false,
    this.statusLabel,
    this.occupancy,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] ?? '',
        vehicleLabel: j['vehicleLabel'] ?? '',
        lineNr: j['lineNr'] ?? j['routeId'] ?? '?',
        headsign: j['headsign'],
        brigade: j['brigade'],
        brand: j['brand'],
        model: j['model'],
        lat: (j['lat'] ?? 0).toDouble(),
        lon: (j['lon'] ?? 0).toDouble(),
        delay: j['delay'],
        bearing: j['bearing']?.toDouble(),
        atTerminus: j['atTerminus'] ?? false,
        statusLabel: j['statusLabel'],
        occupancy: j['occupancy'],
      );

  String get modelFull =>
      '${brand ?? ''} ${model ?? ''}'.trim().isEmpty ? 'Nieznany model' : '${brand ?? ''} ${model ?? ''}'.trim();

  String get delayText {
    if (delay == null) return '—';
    if (delay!.abs() <= 30) return 'Na czasie';
    final ad = delay!.abs();
    final h = ad ~/ 3600;
    final m = (ad % 3600) ~/ 60;
    final s = ad % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${h}h');
    if (m > 0 || h > 0) parts.add('${m}min');
    parts.add('${s}s');
    final str = parts.join(' ');
    return delay! > 0 ? 'Spóźn. -$str' : 'Przed cz. +$str';
  }

  String get delayShort {
    if (delay == null || delay!.abs() <= 30) return '';
    final ad = delay!.abs();
    final h = ad ~/ 3600;
    final m = (ad % 3600) ~/ 60;
    final s = ad % 60;
    final sgn = delay! > 0 ? '-' : '+';
    if (h > 0) return '$sgn${h}h${m}m';
    if (m > 0) return '$sgn${m}m${s}s';
    return '$sgn${s}s';
  }

  // 'late' | 'minor' | 'ok' | 'early' | 'terminus' | 'none'
  String get statusClass {
    if (atTerminus) return 'terminus';
    if (delay == null) return 'none';
    if (delay! > 180) return 'late';
    if (delay! > 30) return 'minor';
    if (delay! < -30) return 'early';
    return 'ok';
  }
}
