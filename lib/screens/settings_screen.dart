import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [

          // ── WYGLĄD ──────────────────────────────────────────────
          _SectionHeader('Wygląd'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.brightness_6_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Motyw aplikacji',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Zmień wygląd aplikacji', style: TextStyle(fontSize: 12, color: cs.outline)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.phone_android_rounded, size: 16),
                        label: Text('Auto'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded, size: 16),
                        label: Text('Jasny'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded, size: 16),
                        label: Text('Ciemny'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.setThemeMode(s.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('Schemat kolorów',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Material You pobiera kolory z tapety (Android 12+)',
                      style: TextStyle(fontSize: 12, color: cs.outline)),
                  const SizedBox(height: 12),
                  SegmentedButton<ColorMode>(
                    segments: const [
                      ButtonSegment(
                        value: ColorMode.mpk,
                        icon: Icon(Icons.directions_bus_rounded, size: 16),
                        label: Text('MPK Orange'),
                      ),
                      ButtonSegment(
                        value: ColorMode.dynamic,
                        icon: Icon(Icons.auto_awesome_rounded, size: 16),
                        label: Text('Material You'),
                      ),
                    ],
                    selected: {settings.colorMode},
                    onSelectionChanged: (s) => settings.setColorMode(s.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(height: 14),
                  // Podgląd kolorów
                  Row(
                    children: [
                      _ColorDot(cs.primary, 'Primary'),
                      const SizedBox(width: 10),
                      _ColorDot(cs.secondary, 'Secondary'),
                      const SizedBox(width: 10),
                      _ColorDot(cs.tertiary, 'Tertiary'),
                      const SizedBox(width: 10),
                      _ColorDot(cs.primaryContainer, 'Container'),
                    ],
                  ),
                  if (settings.colorMode == ColorMode.dynamic) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kolory dynamiczne działają na Android 12+. Na starszych urządzeniach używany jest kolor MPK Orange.',
                              style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── O APLIKACJI ─────────────────────────────────────────
          _SectionHeader('O aplikacji'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + nazwa
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: cs.primary.withOpacity(.3), blurRadius: 8, offset: const Offset(0,3))],
                        ),
                        child: Icon(Icons.directions_bus_rounded, color: cs.onPrimary, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MPK Rzeszów Live',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Wersja 1.0.1',
                                style: TextStyle(fontSize: 12, color: cs.outline)),
                            Text('Flutter 3 · Material You',
                                style: TextStyle(fontSize: 12, color: cs.outline)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: cs.outlineVariant),

                  _InfoRow(Icons.person_rounded, 'Autor', 'oko3099', cs),
                  _InfoRow(Icons.code_rounded, 'Technologia', 'Flutter + Dart', cs),
                  _InfoRow(Icons.map_rounded, 'Mapa', 'OpenStreetMap + flutter_map', cs),
                  _InfoRow(Icons.cloud_rounded, 'API', 'mpk-rzeszow-tracker.onrender.com', cs),
                  _InfoRow(Icons.directions_bus_outlined, 'Dane', 'MPK Rzeszów GTFS + RT', cs),

                  const SizedBox(height: 16),
                  Divider(color: cs.outlineVariant),
                  const SizedBox(height: 12),

                  // GitHub button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => settings.openGitHub(),
                      icon: const Icon(Icons.code_rounded, size: 18),
                      label: const Text('Source Code na GitHub'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'github.com/oko3099/MPK-Rzeszow-Flutter-App',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LICENCJE ─────────────────────────────────────────────
          _SectionHeader('Licencje i dane'),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(Icons.copyright_rounded, 'Mapa', '© OpenStreetMap contributors', cs),
                  _InfoRow(Icons.info_outline_rounded, 'Dane RT', '© MPK Rzeszów', cs),
                  _InfoRow(Icons.flutter_dash, 'Framework', '© Google Flutter (BSD-3)', cs),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Stworzone z ❤️ przez oko3099',
              style: TextStyle(fontSize: 12, color: cs.outline, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 1.2)),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ColorDot(this.color, this.label);
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: .5),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final ColorScheme cs;
  const _InfoRow(this.icon, this.label, this.value, this.cs);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 17, color: cs.outline),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}
