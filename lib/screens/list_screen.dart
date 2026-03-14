import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/vehicle.dart';
import 'vehicle_sheet.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final _lineCtrl  = TextEditingController();
  final _headCtrl  = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _taborCtrl = TextEditingController();
  bool _showFilters = true;

  @override
  void dispose() {
    _lineCtrl.dispose(); _headCtrl.dispose();
    _modelCtrl.dispose(); _taborCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final cs       = Theme.of(context).colorScheme;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Column(children: [
      // ── Panel filtrów ──
      Material(
        color: cs.surface,
        elevation: 1,
        shadowColor: Colors.black12,
        child: Column(children: [
          // Nagłówek
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            child: Row(children: [
              TextButton.icon(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list_rounded, size: 18),
                label: Text(_showFilters ? 'Ukryj filtry' : 'Filtry',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(20)),
                child: Text('${state.filteredCount} / ${state.vehicleCount}',
                    style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          // Pola filtrów
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: isTablet
                ? Row(children: [
                    Expanded(child: _FF(_lineCtrl,  'Linia',    Icons.numbers_rounded,        (v) { state.filterLine  = v; state.applyFilters(); })),
                    const SizedBox(width: 8),
                    Expanded(child: _FF(_headCtrl,  'Kierunek', Icons.arrow_forward_rounded,  (v) { state.filterHead  = v; state.applyFilters(); })),
                    const SizedBox(width: 8),
                    Expanded(child: _FF(_modelCtrl, 'Model',    Icons.directions_bus_rounded, (v) { state.filterModel = v; state.applyFilters(); })),
                    const SizedBox(width: 8),
                    Expanded(child: _FF(_taborCtrl, 'Tabor',    Icons.tag_rounded,            (v) { state.filterTabor = v; state.applyFilters(); })),
                  ])
                : Column(children: [
                    Row(children: [
                      Expanded(child: _FF(_lineCtrl,  'Linia',    Icons.numbers_rounded,       (v) { state.filterLine  = v; state.applyFilters(); })),
                      const SizedBox(width: 8),
                      Expanded(child: _FF(_headCtrl,  'Kierunek', Icons.arrow_forward_rounded, (v) { state.filterHead  = v; state.applyFilters(); })),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _FF(_modelCtrl, 'Model', Icons.directions_bus_rounded, (v) { state.filterModel = v; state.applyFilters(); })),
                      const SizedBox(width: 8),
                      Expanded(child: _FF(_taborCtrl, 'Tabor', Icons.tag_rounded,            (v) { state.filterTabor = v; state.applyFilters(); })),
                    ]),
                  ]),
            ),
            secondChild: const SizedBox(height: 4),
            crossFadeState: _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),

          // Chipy sortowania
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(children: [
              _SC('delay', 'Opóźnienie', Icons.access_time_rounded, state),
              const SizedBox(width: 6),
              _SC('line',  'Linia',      Icons.format_list_numbered_rounded, state),
              const SizedBox(width: 6),
              _SC('tabor', 'Tabor',      Icons.directions_bus_rounded, state),
            ]),
          ),
          Divider(height: 1, color: cs.outlineVariant),
        ]),
      ),

      // ── Lista / siatka ──
      Expanded(
        child: state.loadState == LoadState.loading && state.vehicleCount == 0
            ? const Center(child: CircularProgressIndicator())
            : state.filteredCount == 0
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(state.vehicleCount == 0 ? 'Ładowanie...' : 'Brak wyników',
                        style: TextStyle(color: cs.outline)),
                  ]))
                : isTablet
                    ? _Grid(vehicles: state.filtered)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: state.filteredCount,
                        itemBuilder: (ctx, i) => _Card(vehicle: state.filtered[i]),
                      ),
      ),
    ]);
  }
}

// ── TABLET GRID ───────────────────────────────────────────────────
class _Grid extends StatelessWidget {
  final List<Vehicle> vehicles;
  const _Grid({required this.vehicles});
  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.of(context).size.width >= 900 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols, crossAxisSpacing: 10,
        mainAxisSpacing: 10,  childAspectRatio: 2.6,
      ),
      itemCount: vehicles.length,
      itemBuilder: (ctx, i) => _Card(vehicle: vehicles[i]),
    );
  }
}

// ── FILTER FIELD ──────────────────────────────────────────────────
class _FF extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChange;
  const _FF(this.ctrl, this.hint, this.icon, this.onChange);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      onChanged: onChange,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { ctrl.clear(); onChange(''); })
            : null,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}

// ── SORT CHIP ─────────────────────────────────────────────────────
class _SC extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final AppState state;
  const _SC(this.value, this.label, this.icon, this.state);
  @override
  Widget build(BuildContext context) => FilterChip(
        selected: state.sortBy == value,
        avatar: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        onSelected: (_) => state.setSort(value),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
}

// ── VEHICLE CARD ──────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Vehicle vehicle;
  const _Card({required this.vehicle});

  Color _col() {
    switch (vehicle.statusClass) {
      case 'late':     return const Color(0xFFD32F2F);
      case 'minor':    return const Color(0xFFF57F17);
      case 'ok':       return const Color(0xFF2E7D32);
      case 'early':    return const Color(0xFF1565C0);
      case 'terminus': return const Color(0xFF6A1B9A);
      default:         return const Color(0xFF607D8B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final col = _col();
    final isMinor = vehicle.statusClass == 'minor';

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context, isScrollControlled: true, useSafeArea: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => VehicleSheet(vehicle: vehicle),
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withOpacity(.6)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            // Pasek koloru
            Container(width: 5, decoration: BoxDecoration(
              color: col,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            )),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Wiersz 1
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(8)),
                      child: Text(vehicle.lineNr, style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.3,
                        color: isMinor ? Colors.black87 : Colors.white,
                      )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      vehicle.headsign ?? 'Brak danych GTFS',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: vehicle.headsign != null ? cs.onSurface : cs.outline,
                        fontStyle: vehicle.headsign != null ? FontStyle.normal : FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 6),
                    if (vehicle.atTerminus)
                      _Bdg('PĘTLA', const Color(0xFF6A1B9A))
                    else if (vehicle.statusClass != 'none')
                      _DlyBdg(vehicle),
                  ]),
                  const SizedBox(height: 6),
                  // Wiersz 2
                  Row(children: [
                    Icon(Icons.tag, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 3),
                    Text(vehicle.vehicleLabel, style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                    if (vehicle.year != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.calendar_today, size: 11, color: cs.onSurfaceVariant.withOpacity(.6)),
                      const SizedBox(width: 2),
                      Text('${vehicle.year}', style: TextStyle(
                        fontSize: 11.5, color: cs.onSurfaceVariant.withOpacity(.7))),
                    ],
                    if (vehicle.model != null) ...[
                      const SizedBox(width: 6),
                      Expanded(child: Text(vehicle.modelFull, style: TextStyle(
                        fontSize: 11.5, color: cs.outline, fontStyle: FontStyle.italic),
                        overflow: TextOverflow.ellipsis)),
                    ] else const Spacer(),
                    if (vehicle.brigade != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                        child: Text('Bryg. ${vehicle.brigade}', style: TextStyle(
                          fontSize: 11.5, color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                      ),
                  ]),
                  // Wiersz 3 — przystanek (jeśli dostępny)
                  if (vehicle.nearestStop != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.location_on, size: 12, color: cs.primary.withOpacity(.7)),
                      const SizedBox(width: 3),
                      Expanded(child: Text(
                        '${vehicle.nearestStop}${vehicle.nearestStopDist != null ? " · ${vehicle.nearestStopDist}m" : ""}',
                        style: TextStyle(fontSize: 11.5, color: cs.primary.withOpacity(.8)),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ]),
                  ],
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Bdg extends StatelessWidget {
  final String t; final Color c;
  const _Bdg(this.t, this.c);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: c.withOpacity(.3))),
    child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
  );
}

class _DlyBdg extends StatelessWidget {
  final Vehicle vehicle;
  const _DlyBdg(this.vehicle);
  @override
  Widget build(BuildContext context) {
    Color c;
    switch (vehicle.statusClass) {
      case 'late':  c = const Color(0xFFD32F2F); break;
      case 'minor': c = const Color(0xFFF57F17); break;
      case 'ok':    c = const Color(0xFF2E7D32); break;
      case 'early': c = const Color(0xFF1565C0); break;
      default: return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withOpacity(.3))),
      child: Text(vehicle.delayText, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
