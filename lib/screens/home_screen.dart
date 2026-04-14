import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/settings_state.dart';
import 'map_screen.dart';
import 'list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _index    = 0;
  int _prevIndex = 0;

  final _screens = const [MapScreen(), ListScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final state    = context.watch<AppState>();
    final settings = context.watch<SettingsState>();
    final cs       = Theme.of(context).colorScheme;
    final anim     = settings.animationsEnabled;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
    ));

    return Scaffold(
      appBar: _index == 2
          ? null
          : AppBar(
              title: const Row(children: [
                Icon(Icons.directions_bus_rounded, size: 22),
                SizedBox(width: 8),
                Text('MPK Rzeszów',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                SizedBox(width: 4),
                Text('Live',
                    style: TextStyle(fontWeight: FontWeight.w300, fontSize: 16)),
              ]),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _StatusDot(state: state),
                ),
                TextButton.icon(
                  onPressed: state.loadState == LoadState.loading
                      ? null
                      : state.refresh,
                  icon: state.loadState == LoadState.loading
                      ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary),
                        )
                      : Icon(Icons.refresh_rounded,
                          size: 18, color: cs.onPrimary),
                  label: Text(
                    state.loadState == LoadState.loading
                        ? ''
                        : '↺ ${state.countdown}s',
                    style: TextStyle(color: cs.onPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),

      body: Column(children: [
        if (_index != 2) _StatsBar(state: state),
        Expanded(
          child: anim
              ? _AnimatedScreen(
                  index:     _index,
                  prevIndex: _prevIndex,
                  screens:   _screens,
                )
              : IndexedStack(index: _index, children: _screens),
        ),
      ]),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        animationDuration: anim
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        onDestinationSelected: (i) {
          setState(() {
            _prevIndex = _index;
            _index     = i;
          });
        },
        destinations: [
          const NavigationDestination(
            icon:         Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label:        'Mapa',
          ),
          NavigationDestination(
            icon:         const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt_rounded),
            label:        'Lista (${state.vehicleCount})',
          ),
          const NavigationDestination(
            icon:         Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label:        'Ustawienia',
          ),
        ],
      ),
    );
  }
}

// ── Animowane przejście między zakładkami ─────────────────────────
class _AnimatedScreen extends StatefulWidget {
  final int index, prevIndex;
  final List<Widget> screens;
  const _AnimatedScreen({
    required this.index,
    required this.prevIndex,
    required this.screens,
  });
  @override
  State<_AnimatedScreen> createState() => _AnimatedScreenState();
}

class _AnimatedScreenState extends State<_AnimatedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _fade;
  late Animation<Offset>   _slide;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedScreen old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      // Kierunek slajdu — prawo/lewo lub góra/dół
      final goRight = widget.index > widget.prevIndex;
      _slide = Tween<Offset>(
        begin: Offset(goRight ? 0.06 : -0.06, 0),
        end:   Offset.zero,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

      _ctrl.value = 0;
      _ctrl.forward().then((_) {
        setState(() => _currentIndex = widget.index);
      });
      setState(() => _currentIndex = widget.index);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child:   SlideTransition(
          position: _slide,
          child:    widget.screens[_currentIndex],
        ),
      );
}

// ── Status dot ────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final AppState state;
  const _StatusDot({required this.state});
  @override
  Widget build(BuildContext context) {
    final c = switch (state.loadState) {
      LoadState.loading => Colors.amber,
      LoadState.error   => Colors.red.shade300,
      LoadState.idle    => state.vehicleCount > 0
          ? Colors.greenAccent
          : Colors.grey,
    };
    return Container(
      width: 9, height: 9,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final AppState state;
  const _StatsBar({required this.state});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(children: [
        _Stat('🚌', '${state.vehicleCount}', 'pojazdów'),
        const SizedBox(width: 14),
        _Stat('⏰', '${state.lateCount}', 'opóźn.'),
        const SizedBox(width: 14),
        _Stat('🟣', '${state.terminusCount}', 'pętla'),
        const Spacer(),
        Text(state.statusText,
            style: TextStyle(
                fontSize: 11,
                color: cs.onPrimaryContainer.withOpacity(.7)),
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String icon, value, label;
  const _Stat(this.icon, this.value, this.label);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 3),
      Text(value,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onPrimaryContainer)),
      const SizedBox(width: 2),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: cs.onPrimaryContainer.withOpacity(.65))),
    ]);
  }
}
