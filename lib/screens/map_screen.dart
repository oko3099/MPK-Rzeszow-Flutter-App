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
  bool _showError = true;

  Color _colorFor(String cls) {
    switch (cls) {
      case 'late':     return const Color(0xFFD32F2F);
      case 'minor':    return const Color(0xFFF57F17);
      case 'ok':       return const Color(0xFF2E7D32);
      case 'early':    return const Color(0xFF1565C0);
      case 'terminus': return const Color(0xFF6A1B9A);
      default:         return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final cs       = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // Ukryj błąd gdy dane się pojawią
    if (state.vehicleCount > 0 && _showError &&
        state.errorText != null && state.errorText!.contains('SocketFailed')) {
      _showError = false;
    }
    if (state.errorText == null) _showError = true;

    return Stack(children: [
      FlutterMap(
        mapController: _mapCtrl,
        options: MapOptions(
          initialCenter: const LatLng(50.0413, 21.999),
          initialZoom: isTablet ? 12.5 : 13.0,
          maxZoom: 19,
          interactionOptions: const InteractionOptions(
            scrollWheelVelocity: 0.005,
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'pl.rzeszow.mpk_tracker',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: state.all
                .where((v) => v.lat != 0 && v.lon != 0)
                .map((v) => Marker(
                      point: LatLng(v.lat, v.lon),
                      width: 52,
                      height: 62,
                      child: GestureDetector(
                        onTap: () => _onTap(context, v),
                        child: _Marker(vehicle: v, color: _colorFor(v.statusClass)),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),

      // Legenda — tablet po lewej, telefon po prawej
      Positioned(
        bottom: 16,
        right: isTablet ? null : 12,
        left:  isTablet ? 12  : null,
        child: const _Legend(),
      ),

      // Błąd — tylko gdy brak danych i tylko przez chwilę
      if (state.errorText != null && _showError && state.vehicleCount == 0)
        Positioned(
          bottom: 12, left: 12, right: 12,
          child: _ErrorBanner(
            message: _friendlyError(state.errorText!),
            onDismiss: () => setState(() => _showError = false),
          ),
        ),
    ]);
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketFailed') || raw.contains('No address'))
      return 'Brak połączenia z serwerem. Sprawdź internet.';
    if (raw.contains('timeout') || raw.contains('Timeout'))
      return 'Przekroczono czas połączenia. Spróbuj ponownie.';
    if (raw.contains('502') || raw.contains('503'))
      return 'Serwer chwilowo niedostępny.';
    return 'Błąd połączenia. Odświeżam…';
  }

  void _onTap(BuildContext context, Vehicle v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => VehicleSheet(vehicle: v),
    );
  }
}

// ── MARKER ────────────────────────────────────────────────────────
class _Marker extends StatelessWidget {
  final Vehicle vehicle;
  final Color color;
  const _Marker({required this.vehicle, required this.color});

  @override
  Widget build(BuildContext context) {
    final isMinor = vehicle.statusClass == 'minor';
    final tc      = isMinor ? Colors.black87 : Colors.white;
    final dShort  = vehicle.delayShort;

    return SizedBox(
      width: 52,
      height: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 55,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: color.withOpacity(.5), blurRadius: 5, offset: const Offset(0, 2)),
                BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 3),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Strzałka kierunku
                if (vehicle.bearing != null)
                  Transform.rotate(
                    angle: vehicle.bearing! * math.pi / 180,
                    child: Icon(Icons.navigation_rounded, size: 10, color: tc.withOpacity(.8)),
                  )
                else
                  const SizedBox(height: 2),

                // Numer linii — główny element
                Text(
                  vehicle.lineNr,
                  style: TextStyle(
                    fontSize: vehicle.lineNr.length > 2 ? 14 : 17,
                    fontWeight: FontWeight.w900,
                    color: tc,
                    height: 1.0,
                    letterSpacing: -.5,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),

                // Opóźnienie
                if (dShort.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    dShort,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: tc.withOpacity(.95),
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Pętla
                if (vehicle.atTerminus) ...[
                  const SizedBox(height: 1),
                  Text('pętla', style: TextStyle(
                    fontSize: 6.5, color: tc.withOpacity(.8), letterSpacing: .2)),
                ],
              ],
            ),
          ),
          // Trójkąt
          CustomPaint(
            size: const Size(12, 6),
            painter: _Arrow(color),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends CustomPainter {
  final Color color;
  const _Arrow(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      ui.Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
    );
    // Solidna nakładka
    canvas.drawPath(
      ui.Path()
        ..moveTo(1, 0)
        ..lineTo(size.width - 1, 0)
        ..lineTo(size.width / 2, size.height - 1)
        ..close(),
      Paint()..color = color,
    );
  }
  @override
  bool shouldRepaint(_Arrow o) => o.color != color;
}

// ── ERROR BANNER ──────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(14),
      color: cs.errorContainer,
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
              style: TextStyle(fontSize: 12.5, color: cs.onErrorContainer))),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: cs.onErrorContainer),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ]),
      ),
    );
  }
}

// ── LEGENDA ───────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LRow(const Color(0xFF2E7D32), 'Na czasie'),
            _LRow(const Color(0xFFF57F17), '< 3 min opóźn.'),
            _LRow(const Color(0xFFD32F2F), '> 3 min opóźn.'),
            _LRow(const Color(0xFF1565C0), 'Wcześnie / brak RT'),
            _LRow(const Color(0xFF6A1B9A), 'Na pętli'),
          ],
        ),
      ),
    );
  }
}

class _LRow extends StatelessWidget {
  final Color color; final String label;
  const _LRow(this.color, this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.5),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 11, height: 11,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}
