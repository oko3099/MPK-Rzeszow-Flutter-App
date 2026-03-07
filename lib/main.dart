import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'services/app_state.dart';
import 'services/settings_state.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..init()),
        ChangeNotifierProvider(create: (_) => SettingsState()),
      ],
      child: const MpkApp(),
    ),
  );
}

class MpkApp extends StatelessWidget {
  const MpkApp({super.key});

  static const _mpkOrange = Color(0xFFE8560A);

  ThemeData _buildTheme(ColorScheme cs) => ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: cs.primaryContainer,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        chipTheme: ChipThemeData(
          selectedColor: cs.primaryContainer,
          labelStyle: const TextStyle(fontSize: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.outlineVariant),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cs.surfaceContainerHighest.withOpacity(.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          isDense: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (settings.useDynamicColor && lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: _mpkOrange,
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: _mpkOrange,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'MPK Rzeszów',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: _buildTheme(lightScheme),
          darkTheme: _buildTheme(darkScheme),
          home: const HomeScreen(),
        );
      },
    );
  }
}
