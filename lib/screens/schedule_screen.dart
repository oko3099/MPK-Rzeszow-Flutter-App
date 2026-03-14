import 'package:flutter/material.dart';
import '../services/api_service.dart';

// ══════════════════════════════════════════════════════════════════
// GŁÓWNY EKRAN ROZKŁADU
// ══════════════════════════════════════════════════════════════════
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.schedule_rounded, size: 20),
          SizedBox(width: 8),
          Text('Rozkład jazdy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        bottom: TabBar(
          controller: _tab,
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onPrimary.withOpacity(.65),
          indicatorColor: cs.onPrimary,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(icon: Icon(Icons.route_outlined, size: 18), text: 'Linia'),
            Tab(icon: Icon(Icons.location_on_outlined, size: 18), text: 'Przystanek'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_LineTab(), _StopTab()],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 1 — LINIA → kierunek → przystanek → rozkład
// ══════════════════════════════════════════════════════════════════
class _LineTab extends StatefulWidget {
  const _LineTab();
  @override
  State<_LineTab> createState() => _LineTabState();
}

class _LineTabState extends State<_LineTab> {
  // Etapy: 'lines' | 'variants' | 'stops' | 'timetable'
  String _step = 'lines';
  List<BusRoute> _allRoutes = [];
  List<BusRoute> _filtered = [];
  bool _loading = true;
  String? _error;

  BusRoute? _route;
  RouteSchedule? _schedule;
  String _variant = '';          // wybrany kierunek (headsign)
  ScheduleTrip? _trip;           // reprezentatywny trip dla stopu
  String _stopId = '';
  String _stopName = '';

  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadRoutes(); }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadRoutes() async {
    try {
      final r = await RouteApi.fetchRoutes();
      setState(() { _allRoutes = r; _filtered = r; _loading = false; });
    } catch (e) { setState(() { _error = '$e'; _loading = false; }); }
  }

  void _filter(String q) => setState(() =>
    _filtered = q.isEmpty ? _allRoutes
        : _allRoutes.where((r) => r.lineNr.toLowerCase().contains(q.toLowerCase())).toList());

  Future<void> _pickRoute(BusRoute r) async {
    setState(() { _route = r; _step = 'loading'; _error = null; });
    try {
      final s = await RouteApi.fetchSchedule(r.lineNr);
      setState(() {
        _schedule = s;
        _variant = s.variants.keys.isNotEmpty ? s.variants.keys.first : '';
        _step = 'variants';
      });
    } catch (e) { setState(() { _error = '$e'; _step = 'lines'; }); }
  }

  void _pickVariant(String v) {
    setState(() { _variant = v; _step = 'stops'; });
  }

  void _pickStop(String stopId, String stopName, ScheduleTrip trip) {
    setState(() { _stopId = stopId; _stopName = stopName; _trip = trip; _step = 'timetable'; });
  }

  void _back() {
    setState(() {
      switch (_step) {
        case 'variants': _step = 'lines'; _route = null; _searchCtrl.clear(); _filter('');
        case 'stops': _step = 'variants';
        case 'timetable': _step = 'stops';
        default: _step = 'lines';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _step == 'lines') return _ErrorView(_error!, _loadRoutes);

    return switch (_step) {
      'lines'     => _buildLines(),
      'loading'   => const Center(child: CircularProgressIndicator()),
      'variants'  => _buildVariants(),
      'stops'     => _buildStops(),
      'timetable' => _buildTimetable(),
      _           => _buildLines(),
    };
  }

  // ── KROK 1: Siatka linii ──────────────────────────────────────
  Widget _buildLines() {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      _SearchBox(ctrl: _searchCtrl, hint: 'Szukaj linii...', onChanged: _filter,
          onClear: () { _searchCtrl.clear(); _filter(''); }),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        child: Row(children: [
          Icon(Icons.touch_app_outlined, size: 14, color: cs.outline),
          const SizedBox(width: 6),
          Text('Wybierz linię', style: TextStyle(fontSize: 12, color: cs.outline)),
          const Spacer(),
          Text('${_filtered.length} linii', style: TextStyle(fontSize: 11, color: cs.outline)),
        ]),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.5),
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final r = _filtered[i];
            return GestureDetector(
              onTap: () => _pickRoute(r),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: cs.primary.withOpacity(.25), blurRadius: 4, offset: const Offset(0,2))],
                ),
                alignment: Alignment.center,
                child: Text(r.lineNr,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onPrimary)),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── KROK 2: Wybór kierunku ────────────────────────────────────
  Widget _buildVariants() {
    final cs = Theme.of(context).colorScheme;
    final variants = _schedule!.variants.keys.toList();
    return Column(children: [
      _StepHeader(
        lineNr: _route!.lineNr, title: 'Wybierz kierunek', onBack: _back, cs: cs),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: variants.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final v = variants[i];
            final trips = _schedule!.variants[v]!;
            final first = trips.isNotEmpty ? trips.first.firstDep5 : '';
            final last  = trips.isNotEmpty ? trips.last.firstDep5  : '';
            return GestureDetector(
              onTap: () => _pickVariant(v),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(children: [
                  Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text('${trips.length} kursów · $first – $last',
                        style: TextStyle(fontSize: 12, color: cs.outline)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: cs.outline),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── KROK 3: Wybór przystanku ──────────────────────────────────
  Widget _buildStops() {
    final cs = Theme.of(context).colorScheme;
    final trips = _schedule!.variants[_variant] ?? [];
    if (trips.isEmpty) return const _EmptyHint(icon: Icons.info_outline, text: 'Brak danych', sub: '');

    // Użyj pierwszego tripu jako wzorca przystanków
    final refTrip = trips.first;
    final stops = refTrip.stops;

    return Column(children: [
      _StepHeader(lineNr: _route!.lineNr, title: _variant, onBack: _back, cs: cs),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
        child: Text('Wybierz przystanek aby zobaczyć rozkład',
            style: TextStyle(fontSize: 12, color: cs.outline)),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          itemCount: stops.length,
          itemBuilder: (_, i) {
            final s = stops[i];
            final isLast = i == stops.length - 1;
            return InkWell(
              onTap: () => _pickStop(s.stopId, s.stopName, refTrip),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  SizedBox(width: 32, child: Column(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: i == 0 || isLast ? cs.primary : cs.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.primary, width: 2),
                        )),
                    if (!isLast) Container(width: 2, height: 30, color: cs.primaryContainer),
                  ])),
                  const SizedBox(width: 8),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Expanded(child: Text(s.stopName,
                          style: TextStyle(fontSize: 13,
                              fontWeight: i == 0 || isLast ? FontWeight.w700 : FontWeight.w400))),
                      Text(s.dep5, style: TextStyle(fontSize: 12, color: cs.outline, fontFamily: 'monospace')),
                    ]),
                  )),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── KROK 4: Rozkład godzinowy ─────────────────────────────────
  Widget _buildTimetable() {
    final cs = Theme.of(context).colorScheme;
    final trips = _schedule!.variants[_variant] ?? [];

    // Zbierz godziny odjazdu z wybranego przystanku dla wszystkich tripów
    final Map<int, List<String>> byHour = {};
    for (final t in trips) {
      final st = t.stops.where((s) => s.stopId == _stopId).firstOrNull;
      if (st == null) continue;
      if (st.dep5.length < 5) continue;
      final parts = st.dep5.split(':');
      final h = int.tryParse(parts[0]) ?? -1;
      if (h < 0) continue;
      byHour.putIfAbsent(h, () => []).add(parts[1]);
    }
    final hours = byHour.keys.toList()..sort();
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;

    return Column(children: [
      _StepHeader(lineNr: _route!.lineNr, title: _stopName, onBack: _back, cs: cs,
          subtitle: '→ $_variant'),
      if (hours.isEmpty)
        const Expanded(child: _EmptyHint(icon: Icons.schedule_outlined,
            text: 'Brak kursów przez ten przystanek', sub: ''))
      else
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hours.length,
            itemBuilder: (_, i) {
              final h = hours[i];
              final mins = byHour[h]!..sort();
              final isCurrent = h == now.hour;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? cs.primaryContainer.withOpacity(.4) : cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? cs.primary.withOpacity(.5) : cs.outlineVariant,
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 44, padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                    ),
                    alignment: Alignment.center,
                    child: Text('$h', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: isCurrent ? cs.onPrimary : cs.onSurfaceVariant)),
                  ),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Wrap(spacing: 6, runSpacing: 4, children: mins.map((m) {
                      final isPast = h * 60 + (int.tryParse(m) ?? 0) < nowMins;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPast ? cs.surfaceContainerHighest
                              : isCurrent ? cs.primary.withOpacity(.15)
                              : cs.primaryContainer.withOpacity(.4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(m, style: TextStyle(
                            fontSize: 13,
                            fontWeight: isCurrent && !isPast ? FontWeight.w700 : FontWeight.w500,
                            color: isPast ? cs.outline : cs.onSurface)),
                      );
                    }).toList()),
                  )),
                ]),
              );
            },
          ),
        ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
// TAB 2 — PRZYSTANEK → odjazdy
// ══════════════════════════════════════════════════════════════════
class _StopTab extends StatefulWidget {
  const _StopTab();
  @override
  State<_StopTab> createState() => _StopTabState();
}

class _StopTabState extends State<_StopTab> {
  final _ctrl = TextEditingController();
  List<Stop> _allStops = [];
  List<Stop> _filtered = [];
  bool _loading = true;
  Stop? _selected;
  List<Departure> _departures = [];
  String _stopName = '';
  bool _loadingDeps = false;
  String? _error;

  @override
  void initState() { super.initState(); _loadStops(); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _loadStops() async {
    try {
      final s = await ScheduleApi.fetchStops('');
      setState(() { _allStops = s; _filtered = s; _loading = false; });
    } catch (e) { setState(() { _error = '$e'; _loading = false; }); }
  }

  void _filter(String q) => setState(() =>
    _filtered = q.isEmpty ? _allStops
        : _allStops.where((s) => s.name.toLowerCase().contains(q.toLowerCase())).toList());

  Future<void> _pickStop(Stop s) async {
    setState(() { _selected = s; _loadingDeps = true; _departures = []; _error = null; });
    try {
      final d = await ScheduleApi.fetchDepartures(s.id);
      setState(() {
        _departures = (d['departures'] as List? ?? []).map((x) => Departure.fromJson(x)).toList();
        _stopName = d['stopName'] ?? s.name;
        _loadingDeps = false;
      });
    } catch (e) { setState(() { _error = '$e'; _loadingDeps = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_selected != null) {
      return Column(children: [
        // Nagłówek przystanku z powrotem
        Container(
          color: cs.primaryContainer,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            GestureDetector(
              onTap: () => setState(() { _selected = null; _departures = []; }),
              child: Icon(Icons.arrow_back_rounded, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Icon(Icons.location_on_rounded, color: cs.onPrimaryContainer, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(_stopName,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer))),
          ]),
        ),
        Expanded(
          child: _loadingDeps
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                  : _departures.isEmpty
                      ? const _EmptyHint(icon: Icons.schedule_outlined,
                          text: 'Brak odjazdów w najbliższych 3h', sub: '')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: _departures.length,
                          itemBuilder: (_, i) => _DepartureCard(dep: _departures[i]),
                        ),
        ),
      ]);
    }

    // Lista przystanków
    return Column(children: [
      _SearchBox(ctrl: _ctrl, hint: 'Szukaj przystanku...', onChanged: _filter,
          onClear: () { _ctrl.clear(); _filter(''); }),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: Row(children: [
          Icon(Icons.touch_app_outlined, size: 14, color: cs.outline),
          const SizedBox(width: 6),
          Text('Wybierz przystanek', style: TextStyle(fontSize: 12, color: cs.outline)),
          const Spacer(),
          Text('${_filtered.length} przystanków', style: TextStyle(fontSize: 11, color: cs.outline)),
        ]),
      ),
      Expanded(
        child: _filtered.isEmpty
            ? const _EmptyHint(icon: Icons.search_off_rounded, text: 'Brak wyników', sub: '')
            : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  return ListTile(
                    leading: Icon(Icons.location_on_outlined, color: cs.primary, size: 20),
                    title: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20),
                    dense: true,
                    onTap: () => _pickStop(s),
                  );
                },
              ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
// WSPÓLNE WIDGETY
// ══════════════════════════════════════════════════════════════════

class _StepHeader extends StatelessWidget {
  final String lineNr, title;
  final String? subtitle;
  final VoidCallback onBack;
  final ColorScheme cs;
  const _StepHeader({required this.lineNr, required this.title, required this.onBack,
      required this.cs, this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    color: cs.primaryContainer,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(children: [
      GestureDetector(onTap: onBack,
          child: Icon(Icons.arrow_back_rounded, color: cs.onPrimaryContainer)),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(7)),
        child: Text(lineNr,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onPrimary)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onPrimaryContainer),
            overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(subtitle!, style: TextStyle(fontSize: 11, color: cs.onPrimaryContainer.withOpacity(.7)),
              overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool loading;
  const _SearchBox({required this.ctrl, required this.hint, required this.onChanged,
      required this.onClear, this.loading = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
    child: TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear)
            : loading ? const Padding(padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))) : null,
      ),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  final IconData icon; final String text, sub;
  const _EmptyHint({required this.icon, required this.text, required this.sub});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 52, color: cs.outlineVariant),
      const SizedBox(height: 14),
      Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      if (sub.isNotEmpty) ...[const SizedBox(height: 6),
        Text(sub, style: TextStyle(fontSize: 12, color: cs.outline))],
    ]));
  }
}

class _ErrorView extends StatelessWidget {
  final String error; final VoidCallback onRetry;
  const _ErrorView(this.error, this.onRetry);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
      const SizedBox(height: 12),
      Text('Błąd połączenia', style: TextStyle(fontWeight: FontWeight.w600, color: cs.error)),
      const SizedBox(height: 6),
      Text(error, style: TextStyle(fontSize: 11, color: cs.outline), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded), label: const Text('Spróbuj ponownie')),
    ]));
  }
}

class _DepartureCard extends StatelessWidget {
  final Departure dep;
  const _DepartureCard({required this.dep});

  Color _tc(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    if (dep.diffMins <= 0) return cs.outline;
    if (dep.diffMins <= 2) return const Color(0xFFD32F2F);
    if (dep.diffMins <= 5) return const Color(0xFFF57F17);
    return const Color(0xFF2E7D32);
  }

  String get _label {
    if (dep.diffMins <= 0) return 'Odjeżdża';
    if (dep.diffMins < 60) return '${dep.diffMins} min';
    return '${dep.diffMins ~/ 60}h ${dep.diffMins % 60}min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tc = _tc(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(width: 44, padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
              child: Text(dep.lineNr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onPrimary),
                  textAlign: TextAlign.center)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dep.headsign, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            Text(dep.departure.length >= 5 ? dep.departure.substring(0, 5) : dep.departure,
                style: TextStyle(fontSize: 12, color: cs.outline)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: tc.withOpacity(.1), borderRadius: BorderRadius.circular(20)),
            child: Text(_label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc)),
          ),
        ]),
      ),
    );
  }
}
