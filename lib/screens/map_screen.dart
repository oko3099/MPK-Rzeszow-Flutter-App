import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/vehicle.dart';
import 'vehicle_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapCtrl = MapController();

  Color _colorFor(String cls, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (cls) {
      case 'late': return const Color(0xFFD32F2F);
      case 'minor': return const Color(0xFFF57F17);
      case 'ok': return const Color(0xFF2E7D32);
      case 'early': return const Color(0xFF1565C0);
      case 'terminus': return const Color(0xFF6A1B9A);
      default: return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: const MapOptions(
            initialCenter: LatLng(50.0413, 21.999),
            initialZoom: 13,
            maxZoom: 19,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pl.rzeszow.mpk_tracker',
            ),
            MarkerLayer(
              markers: state.all
                  .where((v) => v.lat != 0 && v.lon != 0)
                  .map((v) {
                    final col = _colorFor(v.statusClass, context);
                    return Marker(
                      point: LatLng(v.lat, v.lon),
                      width: 58,
                      height: 76,
                      child: GestureDetector(
                        onTap: () => _onTap(context, v),
                        child: _BusMarker(vehicle: v, color: col),
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ),

        // Legenda
        Positioned(
          bottom: 16,
          right: 12,
          child: _Legend(),
        ),

        // Error snackbar area
        if (state.errorText != null)
          Positioned(
            bottom: 12,
            left: 12,
            right: 60,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(state.errorText!,
                    style: TextStyle(fontSize: 12, color: cs.onErrorContainer)),
              ),
            ),
          ),
      ],
    );
  }

  void _onTap(BuildContext context, Vehicle v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VehicleSheet(vehicle: v),
    );
  }
}

// ── BUS MARKER ────────────────────────────────────────────────────
class _BusMarker extends StatelessWidget {
  final Vehicle vehicle;
  final Color color;
  const _BusMarker({required this.vehicle, required this.color});

  @override
  Widget build(BuildContext context) {
    final isMinor = vehicle.statusClass == 'minor';
    final tc = isMinor ? Colors.black87 : Colors.white;
    final dShort = vehicle.delayShort;
    final hShort = vehicle.headsign != null
        ? (vehicle.headsign!.length > 10 ? '${vehicle.headsign!.substring(0, 9)}…' : vehicle.headsign!)
        : null;

    return SizedBox(
      width: 58,
      height: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 69,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: color.withOpacity(.4), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (vehicle.bearing != null)
                  Transform.rotate(
                    angle: vehicle.bearing! * math.pi / 180,
                    child: Icon(Icons.navigation_rounded, size: 9, color: tc.withOpacity(.75)),
                  ),
                Text(
                  vehicle.lineNr,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tc, height: 1.0, letterSpacing: -.3),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hShort != null)
                  Text(hShort,
                      style: TextStyle(fontSize: 7.5, color: tc.withOpacity(.85), height: 1.1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center),
                if (vehicle.brigade != null)
                  Text(vehicle.brigade!,
                      style: TextStyle(fontSize: 7, color: tc.withOpacity(.7), height: 1.1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center),
                if (dShort.isNotEmpty)
                  Text(dShort,
                      style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: tc.withOpacity(.9), height: 1.1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center),
                if (vehicle.atTerminus)
                  Text('pętla',
                      style: TextStyle(fontSize: 6, color: tc.withOpacity(.7), letterSpacing: .3, height: 1.0),
                      textAlign: TextAlign.center),
              ],
            ),
          ),
          CustomPaint(size: const Size(14, 7), painter: _TrianglePainter(color)),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_TrianglePainter o) => o.color != color;
}

// ── LEGENDA ───────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendRow(const Color(0xFF2E7D32), 'Na czasie'),
            _LegendRow(const Color(0xFFF57F17), '< 3 min opóźn.'),
            _LegendRow(const Color(0xFFD32F2F), '> 3 min opóźn.'),
            _LegendRow(cs.primary, 'Brak danych RT'),
            _LegendRow(const Color(0xFF6A1B9A), 'Na pętli'),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow(this.color, this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
}
