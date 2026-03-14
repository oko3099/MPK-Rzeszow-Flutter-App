import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class VehicleSheet extends StatelessWidget {
  final Vehicle vehicle;
  const VehicleSheet({super.key, required this.vehicle});

  Color _color(BuildContext context) {
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
    final col = _color(context);
    final isMinor = vehicle.statusClass == 'minor';
    final tc = isMinor ? Colors.black87 : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: .55,
      minChildSize: .4,
      maxChildSize: .9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),

          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Numer linii
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: col,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: col.withOpacity(.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Text(vehicle.lineNr,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: tc, height: 1)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.headsign ?? 'Brak kierunku',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: vehicle.headsign != null ? cs.onSurface : cs.outline),
                          ),
                          const SizedBox(height: 4),
                          Text(vehicle.modelFull,
                              style: TextStyle(fontSize: 13, color: cs.outline, fontStyle: FontStyle.italic)),
                          if (vehicle.atTerminus)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Chip(
                                label: const Text('NA PĘTLI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                backgroundColor: const Color(0xFF6A1B9A).withOpacity(.1),
                                labelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 8),

                // Info rows
                _InfoRow(icon: Icons.confirmation_number_outlined, label: 'Numer taborowy', value: vehicle.vehicleLabel),
                if (vehicle.brigade != null)
                  _InfoRow(icon: Icons.badge_outlined, label: 'Brygada', value: vehicle.brigade!),
                if (vehicle.brand != null)
                  _InfoRow(icon: Icons.business_outlined, label: 'Producent', value: vehicle.brand!),
                if (vehicle.model != null)
                  _InfoRow(icon: Icons.directions_bus_outlined, label: 'Model', value: vehicle.model!),
                if (vehicle.year != null)
                  _InfoRow(icon: Icons.calendar_today_outlined, label: 'Rok produkcji', value: '${vehicle.year}'),
                if (vehicle.nearestStop != null)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Obecnie przy przystanku',
                    value: vehicle.nearestStopDist != null
                        ? '${vehicle.nearestStop} (${vehicle.nearestStopDist}m)'
                        : vehicle.nearestStop!,
                    valueColor: const Color(0xFF1565C0),
                  ),
                if (vehicle.bearing != null)
                  _InfoRow(icon: Icons.explore_outlined, label: 'Kierunek jazdy', value: '${vehicle.bearing!.toStringAsFixed(0)}°'),
                _InfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Opóźnienie',
                  value: vehicle.delayText,
                  valueColor: vehicle.statusClass == 'late' ? const Color(0xFFD32F2F)
                      : vehicle.statusClass == 'early' ? const Color(0xFF1565C0)
                      : vehicle.statusClass == 'ok' ? const Color(0xFF2E7D32)
                      : vehicle.statusClass == 'minor' ? const Color(0xFFF57F17)
                      : null,
                ),
                if (vehicle.statusLabel != null)
                  _InfoRow(icon: Icons.info_outline_rounded, label: 'Status', value: vehicle.statusLabel!),
                if (vehicle.occupancy != null)
                  _InfoRow(icon: Icons.people_outline_rounded, label: 'Zapełnienie', value: vehicle.occupancy!),

                const SizedBox(height: 16),
                Divider(color: cs.outlineVariant),
                const SizedBox(height: 8),

                // Position
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Pozycja',
                  value: '${vehicle.lat.toStringAsFixed(5)}, ${vehicle.lon.toStringAsFixed(5)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.outline),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? cs.onSurface)),
        ],
      ),
    );
  }
}
