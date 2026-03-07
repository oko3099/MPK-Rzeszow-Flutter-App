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
  final _lineCtrl = TextEditingController();
  final _headCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _taborCtrl = TextEditingController();
  bool _showFilters = true;

  @override
  void dispose() {
    _lineCtrl.dispose();
    _headCtrl.dispose();
    _modelCtrl.dispose();
    _taborCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Filter section
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: cs.surface,
          child: Column(
            children: [
              // Toggle filters + sort chips
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list_rounded, size: 18),
                      label: Text(_showFilters ? 'Ukryj filtry' : 'Filtry', style: const TextStyle(fontSize: 13)),
                    ),
                    const Spacer(),
                    Text('${state.filteredCount} / ${state.vehicleCount}',
                        style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              if (_showFilters) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(child: _FilterField(_lineCtrl, '🔍 Linia', (v) {
                        state.filterLine = v;
                        state.applyFilters();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _FilterField(_headCtrl, '🔍 Kierunek', (v) {
                        state.filterHead = v;
                        state.applyFilters();
                      })),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(child: _FilterField(_modelCtrl, '🔍 Model', (v) {
                        state.filterModel = v;
                        state.applyFilters();
                      })),
                      const SizedBox(width: 8),
                      Expanded(child: _FilterField(_taborCtrl, '🔍 Tabor', (v) {
                        state.filterTabor = v;
                        state.applyFilters();
                      })),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Sort chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _SortChip('delay', 'Opóźnienie', Icons.access_time_rounded, state),
                    const SizedBox(width: 6),
                    _SortChip('line', 'Linia', Icons.format_list_numbered_rounded, state),
                    const SizedBox(width: 6),
                    _SortChip('tabor', 'Tabor', Icons.directions_bus_rounded, state),
                  ],
                ),
              ),

              Divider(height: 1, color: cs.outlineVariant),
            ],
          ),
        ),

        // Vehicle list
        Expanded(
          child: state.loadState == LoadState.loading && state.vehicleCount == 0
              ? const Center(child: CircularProgressIndicator())
              : state.filteredCount == 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: cs.outline),
                          const SizedBox(height: 12),
                          Text(state.vehicleCount == 0 ? 'Ładowanie...' : 'Brak wyników',
                              style: TextStyle(color: cs.outline)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: state.filteredCount,
                      itemBuilder: (ctx, i) => _VehicleCard(vehicle: state.filtered[i]),
                    ),
        ),
      ],
    );
  }
}

// ── FILTER FIELD ──────────────────────────────────────────────────
class _FilterField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final ValueChanged<String> onChanged;
  const _FilterField(this.ctrl, this.hint, this.onChanged);

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13),
          suffixIcon: ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    ctrl.clear();
                    onChanged('');
                  })
              : null,
        ),
      );
}

// ── SORT CHIP ─────────────────────────────────────────────────────
class _SortChip extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final AppState state;
  const _SortChip(this.value, this.label, this.icon, this.state);

  @override
  Widget build(BuildContext context) => FilterChip(
        selected: state.sortBy == value,
        avatar: Icon(icon, size: 14),
        label: Text(label),
        onSelected: (_) => state.setSort(value),
        visualDensity: VisualDensity.compact,
      );
}

// ── VEHICLE CARD ──────────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleCard({required this.vehicle});

  Color _leftColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (vehicle.statusClass) {
      case 'late': return const Color(0xFFD32F2F);
      case 'minor': return const Color(0xFFF57F17);
      case 'ok': return const Color(0xFF2E7D32);
      case 'early': return const Color(0xFF1565C0);
      case 'terminus': return const Color(0xFF6A1B9A);
      default: return cs.outlineVariant;
    }
  }

  Color _lineColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (vehicle.statusClass) {
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
    final cs = Theme.of(context).colorScheme;
    final lc = _leftColor(context);
    final lineBg = _lineColor(context);

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => VehicleSheet(vehicle: vehicle),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Kolorowy pasek lewy
              Container(width: 4, decoration: BoxDecoration(color: lc, borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)))),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: badge linii + headsign + delay tag
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: lineBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(vehicle.lineNr,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: vehicle.statusClass == 'minor' ? Colors.black87 : Colors.white)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vehicle.headsign ?? 'Brak danych GTFS',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: vehicle.headsign != null ? cs.onSurface : cs.outline,
                                  fontStyle: vehicle.headsign != null ? FontStyle.normal : FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (vehicle.atTerminus)
                            _Badge('PĘTLA', const Color(0xFF6A1B9A))
                          else if (vehicle.statusClass != 'none')
                            _DelayBadge(vehicle),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Row 2: tabor + model + brygada
                      Row(
                        children: [
                          Text('Tabor ${vehicle.vehicleLabel}',
                              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                          if (vehicle.model != null) ...[
                            const SizedBox(width: 6),
                            Text(vehicle.modelFull,
                                style: TextStyle(fontSize: 11, color: cs.outline, fontStyle: FontStyle.italic)),
                          ],
                          const Spacer(),
                          if (vehicle.brigade != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Bryg. ${vehicle.brigade}',
                                  style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer, fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}

class _DelayBadge extends StatelessWidget {
  final Vehicle vehicle;
  const _DelayBadge(this.vehicle);

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (vehicle.statusClass) {
      case 'late': c = const Color(0xFFD32F2F);
      case 'minor': c = const Color(0xFFF57F17);
      case 'ok': c = const Color(0xFF2E7D32);
      case 'early': c = const Color(0xFF1565C0);
      default: return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
      child: Text(vehicle.delayText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
