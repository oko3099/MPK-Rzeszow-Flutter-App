import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/settings_state.dart';
import '../models/vehicle.dart';
import 'vehicle_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final _mapCtrl  = MapController();
  bool  _showError    = true;
  bool  _showFilters  = false;
  String _filterLine  = '';   // '' = wszystkie

  // Animacja panelu filtrów
  late AnimationController _filterAnim;
  late Animation<double>   _filterSlide;

  @override
  void initState() {
    super.initState();
    _filterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _filterSlide = CurvedAnimation(
        parent: _filterAnim, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _filterAnim.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    final settings = context.read<SettingsState>();
    setState(() => _showFilters = !_showFilters);
    if (settings.animationsEnabled) {
      _showFilters ? _filterAnim.forward() : _filterAnim.reverse();
    } else {
      _filterAnim.value = _showFilters ? 1.0 : 0.0;
    }
  }

  Color _colorFor(String cls) {
    switch (cls) {
      case 'late':      return const Color(0xFFD32F2F);
      case 'minor':     return const Color(0xFFF57F17);
      case 'ok':        return const Color(0xFF2E7D32);
      case 'early':     return const Color(0xFF1565C0);
      case 'terminus':  return const Color(0xFF6A1B9A);
      case 'technical': return const Color(0xFF546E7A);
      default:          return const Color(0xFF1565C0);
    }
  }

  // Unikalne linie (posortowane)
  List<String> _availableLines(List<Vehicle> all) {
    final lines = all
        .where((v) => !v.isTechnical && v.lineNr.isNotEmpty)
        .map((v) => v.lineNr)
        .toSet()
        .toList();
    lines.sort((a, b) {
      final ia = int.tryParse(a), ib = int.tryParse(b);
      if (ia != null && ib != null) return ia.compareTo(ib);
      return a.compareTo(b);
    });
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final settings = context.watch<SettingsState>();
    final cs       = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // Ukryj błąd gdy dane się pojawią
    if (state.vehicleCount > 0 && _showError &&
        state.errorText != null &&
        state.errorText!.contains('SocketFailed')) {
      _showError = false;
    }
    if (state.errorText == null) _showError = true;

    // Filtruj pojazdy dla mapy
    final mapVehicles = state.all.where((v) {
      if (v.lat == 0 && v.lon == 0) return false;
      if (_filterLine.isNotEmpty && v.lineNr != _filterLine) return false;
      return true;
    }).toList();

    final lines = _availableLines(state.all);

    return Stack(children: [

      // ── MAPA ──────────────────────────────────────────────────
      FlutterMap(
        mapController: _mapCtrl,
        options: MapOptions(
          initialCenter: const LatLng(50.0413, 21.999),
          initialZoom:   isTablet ? 12.5 : 13.0,
          maxZoom:       19,
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
            markers: mapVehicles.map((v) {
              final col = _colorFor(v.statusClass);
              return Marker(
                point:  LatLng(v.lat, v.lon),
                width:  v.isTechnical ? 64 : 52,
                height: v.isTechnical ? 58 : 62,
                child:  GestureDetector(
                  onTap: () => _onTap(context, v),
                  child: v.isTechnical
                      ? _TechMarker(vehicle: v, color: col)
                      : _BusMarker(vehicle: v, color: col),
                ),
              );
            }).toList(),
          ),
        ],
      ),

      // ── PRZYCISK FILTRY (góra-lewo) ───────────────────────────
      Positioned(
        top: 12, left: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Przycisk otwierania filtrów
            GestureDetector(
              onTap: _toggleFilters,
              child: AnimatedContainer(
                duration: settings.animationsEnabled
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: _showFilters
                      ? cs.primary
                      : cs.surface.withOpacity(.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 18,
                    color: _showFilters
                        ? cs.onPrimary
                        : cs.onSurface,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _filterLine.isEmpty
                        ? 'Filtry'
                        : 'Linia $_filterLine',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _showFilters
                          ? cs.onPrimary
                          : cs.onSurface,
                    ),
                  ),
                  if (_filterLine.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _filterLine = ''),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _showFilters
                            ? cs.onPrimary
                            : cs.onSurface,
                      ),
                    ),
                  ],
                ]),
              ),
            ),

            // Panel z chipami linii
            SizeTransition(
              sizeFactor: _filterSlide,
              axisAlignment: -1,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 24),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(.97),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text('Filtruj linie na mapie',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Chip "Wszystkie"
                      _LineChip(
                        label: 'Wszystkie',
                        selected: _filterLine.isEmpty,
                        color: cs.primary,
                        onTap: () => setState(() {
                          _filterLine = '';
                        }),
                      ),
                      ...lines.map((l) => _LineChip(
                            label: l,
                            selected: _filterLine == l,
                            color: _lineColor(l),
                            onTap: () => setState(() {
                              _filterLine = _filterLine == l ? '' : l;
                            }),
                          )),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),

      // Licznik widocznych pojazdów gdy filtr aktywny
      if (_filterLine.isNotEmpty)
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.1),
                    blurRadius: 6)
              ],
            ),
            child: Text(
              '${mapVehicles.length} autobus'
              '${mapVehicles.length == 1 ? '' : 'ów'}',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer),
            ),
          ),
        ),

      // ── LEGENDA ───────────────────────────────────────────────
      Positioned(
        bottom: 16,
        right:  isTablet ? null : 12,
        left:   isTablet ? 12   : null,
        child:  const _Legend(),
      ),

      // ── BŁĄD POŁĄCZENIA ───────────────────────────────────────
      if (state.errorText != null &&
          _showError &&
          state.vehicleCount == 0)
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

  Color _lineColor(String line) {
    final n = int.tryParse(line) ?? 0;
    if (n == 0)  return Colors.blueGrey;
    if (n < 10)  return const Color(0xFF1565C0);
    if (n < 20)  return const Color(0xFF2E7D32);
    if (n < 30)  return const Color(0xFFE65100);
    if (n < 40)  return const Color(0xFF6A1B9A);
    if (n < 50)  return const Color(0xFFC62828);
    return const Color(0xFF00695C);
  }
}

// ── CHIP LINII ────────────────────────────────────────────────────
class _LineChip extends StatelessWidget {
  final String    label;
  final bool      selected;
  final Color     color;
  final VoidCallback onTap;
  const _LineChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color:        selected ? color : color.withOpacity(.1),
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(
                color:     selected ? color : color.withOpacity(.4),
                width:     1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w800,
              color:      selected ? Colors.white : color,
            ),
          ),
        ),
      );
}

// ── MARKER ZWYKŁY ─────────────────────────────────────────────────
class _BusMarker extends StatelessWidget {
  final Vehicle vehicle;
  final Color   color;
  const _BusMarker({required this.vehicle, required this.color});

  @override
  Widget build(BuildContext context) {
    final isMinor = vehicle.statusClass == 'minor';
    final tc      = isMinor ? Colors.black87 : Colors.white;
    final dShort  = vehicle.delayShort;
    final lineLen = vehicle.lineNr.length;

    return SizedBox(
      width: 52, height: 62,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 50, height: 55,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(.5),
                  blurRadius: 5,
                  offset: const Offset(0, 2)),
              BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 3),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (vehicle.bearing != null)
                Transform.rotate(
                  angle: vehicle.bearing! * math.pi / 180,
                  child: Icon(Icons.navigation_rounded,
                      size: 10, color: tc.withOpacity(.8)),
                )
              else
                const SizedBox(height: 2),
              Text(
                vehicle.lineNr,
                style: TextStyle(
                  fontSize:   lineLen > 2 ? 14 : 17,
                  fontWeight: FontWeight.w900,
                  color:      tc,
                  height:     1.0,
                  letterSpacing: -.5,
                ),
                textAlign:   TextAlign.center,
                overflow:    TextOverflow.ellipsis,
              ),
              if (dShort.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(dShort,
                    style: TextStyle(
                        fontSize:   8,
                        fontWeight: FontWeight.w700,
                        color:      tc.withOpacity(.95),
                        height:     1.0),
                    textAlign: TextAlign.center,
                    overflow:  TextOverflow.ellipsis),
              ],
              if (vehicle.atTerminus) ...[
                const SizedBox(height: 1),
                Text('pętla',
                    style: TextStyle(
                        fontSize: 6.5,
                        color:    tc.withOpacity(.8),
                        letterSpacing: .2)),
              ],
            ],
          ),
        ),
        CustomPaint(size: const Size(12, 6), painter: _Arrow(color)),
      ]),
    );
  }
}

// ── MARKER TECHNICZNY ─────────────────────────────────────────────
class _TechMarker extends StatelessWidget {
  final Vehicle vehicle;
  final Color   color;
  const _TechMarker({required this.vehicle, required this.color});

  @override
  Widget build(BuildContext context) {
    final tc = Colors.white;
    return SizedBox(
      width: 64, height: 58,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 62, height: 51,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikona klucza
              Text('🔧',
                  style: const TextStyle(fontSize: 13, height: 1.1),
                  textAlign: TextAlign.center),
              // Napis TECH
              Text('TECH',
                  style: TextStyle(
                      fontSize:   9,
                      fontWeight: FontWeight.w900,
                      color:      tc,
                      letterSpacing: .5,
                      height:     1.1),
                  textAlign: TextAlign.center),
              // Brygada
              if (vehicle.brigade != null)
                Text(
                  vehicle.brigade!,
                  style: TextStyle(
                      fontSize:   8,
                      fontWeight: FontWeight.w600,
                      color:      tc.withOpacity(.85),
                      height:     1.1),
                  textAlign:   TextAlign.center,
                  overflow:    TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        CustomPaint(size: const Size(12, 6), painter: _Arrow(color)),
      ]),
    );
  }
}

// ── TRÓJKĄT ───────────────────────────────────────────────────────
class _Arrow extends CustomPainter {
  final Color color;
  const _Arrow(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(1, 0)
      ..lineTo(size.width - 1, 0)
      ..lineTo(size.width / 2, size.height - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(_Arrow o) => o.color != color;
}

// ── BANER BŁĘDU ───────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String       message;
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
          Icon(Icons.wifi_off_rounded,
              size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(
                      fontSize: 12.5, color: cs.onErrorContainer))),
          IconButton(
            icon: Icon(Icons.close,
                size: 16, color: cs.onErrorContainer),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 28, minHeight: 28),
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
    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            _LRow(Color(0xFF2E7D32), 'Na czasie'),
            _LRow(Color(0xFFF57F17), '< 3 min opóźn.'),
            _LRow(Color(0xFFD32F2F), '> 3 min opóźn.'),
            _LRow(Color(0xFF1565C0), 'Wcześnie / brak RT'),
            _LRow(Color(0xFF6A1B9A), 'Na pętli'),
            _LRow(Color(0xFF546E7A), 'Techniczny'),
          ],
        ),
      ),
    );
  }
}

class _LRow extends StatelessWidget {
  final Color  color;
  final String label;
  const _LRow(this.color, this.label);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width:  11, height: 11,
              decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );
}
