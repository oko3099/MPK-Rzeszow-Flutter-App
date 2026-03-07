# 🚌 MPK Rzeszów Live — Flutter App

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Material%20You-Android%2012+-green?logo=android" />
  <img src="https://img.shields.io/badge/Platform-Android-brightgreen" />
  <img src="https://img.shields.io/badge/License-MIT-orange" />
</p>

Aplikacja mobilna do śledzenia autobusów MPK Rzeszów na żywo. Pokazuje pozycje pojazdów na mapie, opóźnienia i informacje GTFS w czasie rzeczywistym.

---

## 📱 Zrzuty ekranu

| Mapa | Lista | Ustawienia |
|------|-------|------------|
| Autobusy na żywo z markerami | Filtrowanie i sortowanie | Motywy i Material You |

---

## ✨ Funkcje

- 🗺️ **Mapa na żywo** — autobusy z kolorowymi markerami (linia, kierunek, brygada, opóźnienie)
- 📋 **Lista pojazdów** — filtrowanie po linii, kierunku, modelu, numerze taborowym
- 🔄 **Auto-odświeżanie** co 15 sekund
- 🎨 **Material You** — dynamiczne kolory z tapety telefonu (Android 12+)
- 🌙 **Tryb ciemny** — jasny / ciemny / zgodny z systemem
- 📊 **Pasek statystyk** — liczba pojazdów, opóźnień, pojazdów na pętli
- 📍 **Szczegóły pojazdu** — model autobusu, brygada, dokładne opóźnienie

---

## 🛠️ Stack technologiczny

| Technologia | Zastosowanie |
|------------|-------------|
| [Flutter 3](https://flutter.dev) | Framework UI |
| [flutter_map](https://pub.dev/packages/flutter_map) | Mapa OpenStreetMap |
| [provider](https://pub.dev/packages/provider) | Zarządzanie stanem |
| [http](https://pub.dev/packages/http) | Pobieranie danych API |
| [dynamic_color](https://pub.dev/packages/dynamic_color) | Material You |
| [url_launcher](https://pub.dev/packages/url_launcher) | Otwieranie linków |

---

## 🔌 API

Aplikacja pobiera dane z backendu Node.js:

```
GET https://mpk-rzeszow-tracker.onrender.com/api/vehicles
```

Backend parsuje dane GTFS Realtime z MPK Rzeszów i wzbogaca je o dane statyczne GTFS.

Kod źródłowy backendu: [MPK-Rzeszow-Tracker](https://github.com/oko3099/mpk-rzeszow-tracker)

---

## 🚀 Jak uruchomić

### Wymagania
- [Flutter SDK 3.16+](https://docs.flutter.dev/get-started/install)
- [Android Studio](https://developer.android.com/studio) z Android SDK
- Android 5.0+ (API 21+)

### Instalacja

```bash
# Klonuj repozytorium
git clone https://github.com/oko3099/MPK-Rzeszow-Flutter-App.git
cd MPK-Rzeszow-Flutter-App

# Pobierz zależności
flutter pub get

# Uruchom
flutter run
```

### Budowanie APK

```bash
flutter build apk --release
```

Gotowy plik APK znajdziesz w: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📁 Struktura projektu

```
lib/
├── main.dart                    # Entry point, Material You theme
├── models/
│   └── vehicle.dart             # Model pojazdu (GTFS + RT)
├── services/
│   ├── api_service.dart         # HTTP client → /api/vehicles
│   ├── app_state.dart           # Stan aplikacji (Provider)
│   └── settings_state.dart      # Ustawienia (motyw, kolory)
└── screens/
    ├── home_screen.dart          # NavigationBar + AppBar + StatsBar
    ├── map_screen.dart           # Mapa z markerami autobusów
    ├── list_screen.dart          # Lista z filtrami i sortowaniem
    ├── vehicle_sheet.dart        # BottomSheet ze szczegółami pojazdu
    └── settings_screen.dart      # Ustawienia motywu i O aplikacji
```

---

## 🎨 Kolory statusów

| Kolor | Status |
|-------|--------|
| 🟢 Zielony | Na czasie (≤30s) |
| 🟡 Żółty | Małe opóźnienie (<3 min) |
| 🔴 Czerwony | Duże opóźnienie (>3 min) |
| 🟤 Brązowy | Brak danych RT |
| 🟣 Fioletowy | Na pętli (terminus) |

---

## 👤 Autor

**oko3099**

- GitHub: [@oko3099](https://github.com/oko3099)

---

## 📄 Licencja

MIT License — możesz swobodnie używać, modyfikować i dystrybuować.

---

## 🙏 Dane i podziękowania

- Dane GTFS i RT: **MPK Rzeszów**
- Mapa: **© OpenStreetMap contributors**
- Framework: **Flutter / Google**
