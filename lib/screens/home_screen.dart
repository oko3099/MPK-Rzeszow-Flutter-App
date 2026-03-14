import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'map_screen.dart';
import 'list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [MapScreen(), ListScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    // Status bar icons color based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
    ));

    return Scaffold(
      appBar: _index == 2
          ? null // ustawienia mają własny nagłówek
          : AppBar(
              title: const Row(
                children: [
                  Icon(Icons.directions_bus_rounded, size: 22),
                  SizedBox(width: 8),
                  Text('MPK Rzeszów', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  SizedBox(width: 4),
                  Text('Live', style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16)),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _StatusDot(state: state),
                ),
                TextButton.icon(
                  onPressed: state.loadState == LoadState.loading ? null : state.refresh,
                  icon: state.loadState == LoadState.loading
                      ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Icon(Icons.refresh_rounded, size: 18, color: cs.onPrimary),
                  label: Text(
                    state.loadState == LoadState.loading ? '' : '↺ ${state.countdown}s',
                    style: TextStyle(color: cs.onPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),

      body: Column(
        children: [
          if (_index != 2) _StatsBar(state: state),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _screens,
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt_rounded),
            label: 'Lista (${state.vehicleCount})',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ustawienia',
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final AppState state;
  const _StatusDot({required this.state});
  @override
  Widget build(BuildContext context) {
    Color c;
    switch (state.loadState) {
      case LoadState.loading: c = Colors.amber;
      case LoadState.error: c = Colors.red.shade300;
      case LoadState.idle: c = state.vehicleCount > 0 ? Colors.greenAccent : Colors.grey;
    }
    return Container(
      width: 9, height: 9,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final AppState state;
  const _StatsBar({required this.state});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        children: [
          _Stat('🚌', '${state.vehicleCount}', 'pojazdów'),
          const SizedBox(width: 14),
          _Stat('⏰', '${state.lateCount}', 'opóźn.'),
          const SizedBox(width: 14),
          _Stat('🟣', '${state.terminusCount}', 'pętla'),
          const Spacer(),
          Text(state.statusText,
              style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer.withOpacity(.7)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon, value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer.withOpacity(.65))),
      ],
    );
  }
}
