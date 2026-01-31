// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_text.dart';
import 'data/database/database_helper.dart';
import 'growth/logic/growth_service.dart';
import 'providers/codex_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Database
  final db = DatabaseHelper();
  final database = await db.database; // Ensure database is initialized

  // Initialize Growth System
  await GrowthService.instance.initialize(database);

  // Only record daily login if growth system is enabled
  final showGrowthCard = prefs.getBool('show_growth_card') ?? true;
  if (showGrowthCard) {
    await GrowthService.instance.recordDailyLogin();
  }

  // Initialize AdMob
  await AdService().initialize();

  // Initialize language
  final langSetting = prefs.getString('app_language') ?? 'system';
  if (langSetting != 'system') {
    AppText.language = langSetting;
  } else {
    // Follow system language
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    AppText.language = switch (locale.languageCode) {
      'zh' => 'zh',
      'en' => 'en',
      'ja' => 'ja',
      _ => 'zh', // Default to Traditional Chinese
    };
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(db),
        ),
        ChangeNotifierProvider(
          create: (_) => CodexProvider(db),
        ),
      ],
      child: const QRScannerApp(),
    ),
  );
}

class QRScannerApp extends StatelessWidget {
  const QRScannerApp({super.key});

  /// Build theme with consistent SnackBar styling
  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Margin: 底部留空間給 Banner Ad (50) + NavigationBar 安全距離
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 70),
        // Material 3 配色
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        actionTextColor: colorScheme.inversePrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: AppText.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: _buildTheme(settings.themeColor, Brightness.light),
          darkTheme: _buildTheme(settings.themeColor, Brightness.dark),
          home: const HomeScreen(),
        );
      },
    );
  }
}
