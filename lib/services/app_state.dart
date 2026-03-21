import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/api_service.dart';

enum LoadState { idle, loading, error }

class AppState extends ChangeNotifier {
  List<Vehicle> all      = [];
  List<Vehicle> filtered = [];
  LoadState loadState    = LoadState.idle;
  String statusText      = 'Inicjalizacja...';
  String? errorText;
  int countdown          = 15;
  Vehicle? selected;
  String sortBy          = 'delay';
  String filterLine      = '';
  String filterHead      = '';
  String filterModel     = '';
  String filterTabor     = '';
  bool   showTechnical   = false;   // ← przejazdy techniczne
  int terminusCount      = 0;
  int lateCount          = 0;

  // Lista unikalnych linii dla chipów
  List<String> get availableLines {
    final lines = all
        .where((v) => !v.isTechnical)
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

  int get technicalCount => all.where((v) => v.isTechnical).length;

  Timer? _cdTimer;

  int get vehicleCount  => all.length;
  int get filteredCount => filtered.length;

  void init() => refresh();

  Future<void> refresh() async {
    loadState = LoadState.loading;
    statusText = 'Pobieranie...';
    errorText  = null;
    _cdTimer?.cancel();
    notifyListeners();

    try {
      final result = await ApiService.fetchVehicles();
      all           = result.vehicles;
      terminusCount = result.atTerminus;
      lateCount     = all.where((v) =>
          v.delay != null && v.delay! > 180 && !v.atTerminus).length;
      statusText = 'Live · ${all.length} pojazdów';
      loadState  = LoadState.idle;
      applyFilters();
    } catch (e) {
      loadState  = LoadState.error;
      errorText  = e.toString().replaceAll('Exception: ', '');
      statusText = 'Błąd połączenia';
      notifyListeners();
    }
    _startCountdown();
  }

  void _startCountdown() {
    countdown = 15;
    _cdTimer?.cancel();
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      notifyListeners();
      if (countdown <= 0) { t.cancel(); refresh(); }
    });
  }

  void applyFilters() {
    var list = all.where((v) {
      // Przejazdy techniczne
      if (v.isTechnical && !showTechnical) return false;
      if (!showTechnical && filterLine.isEmpty && v.isTechnical) return false;

      if (filterLine.isNotEmpty &&
          !v.lineNr.toLowerCase().contains(filterLine.toLowerCase())) return false;
      if (filterHead.isNotEmpty &&
          !(v.headsign ?? '').toLowerCase().contains(filterHead.toLowerCase())) return false;
      if (filterModel.isNotEmpty &&
          !v.modelFull.toLowerCase().contains(filterModel.toLowerCase())) return false;
      if (filterTabor.isNotEmpty &&
          !v.vehicleLabel.toLowerCase().contains(filterTabor.toLowerCase())) return false;
      return true;
    }).toList();

    switch (sortBy) {
      case 'delay':
        list.sort((a, b) {
          final sa = a.atTerminus ? -99999 : (a.delay ?? -9999);
          final sb = b.atTerminus ? -99999 : (b.delay ?? -9999);
          return sb.compareTo(sa);
        });
      case 'line':
        list.sort((a, b) {
          final ia = int.tryParse(a.lineNr), ib = int.tryParse(b.lineNr);
          if (ia != null && ib != null) return ia.compareTo(ib);
          return a.lineNr.compareTo(b.lineNr);
        });
      case 'tabor':
        list.sort((a, b) => a.vehicleLabel.compareTo(b.vehicleLabel));
    }

    filtered = list;
    notifyListeners();
  }

  void setSort(String s) { sortBy = s; applyFilters(); }
  void toggleTechnical()  { showTechnical = !showTechnical; applyFilters(); }

  void selectVehicle(Vehicle? v) {
    selected = v;
    notifyListeners();
  }

  @override
  void dispose() { _cdTimer?.cancel(); super.dispose(); }
}
