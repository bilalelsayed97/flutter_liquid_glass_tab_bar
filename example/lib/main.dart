import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_tab_bar/flutter_liquid_glass_tab_bar.dart';

import 'demo_settings.dart';
import 'demo_settings_scope.dart';
import 'demo_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge so there is page content behind the bar's glass on Android.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  // Compile the glass shader before the first frame.
  await precacheLiquidGlassShader();
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  final DemoSettingsController _settings = DemoSettingsController();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoSettingsScope(
    controller: _settings,
    child: ValueListenableBuilder<DemoSettings>(
      valueListenable: _settings,
      builder: (context, settings, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Liquid Glass Tab Bar',
        themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF4361EE),
          brightness: Brightness.light,
          extensions: [LiquidGlassTabBarTheme.light()],
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: const Color(0xFF4361EE),
          brightness: Brightness.dark,
          extensions: [LiquidGlassTabBarTheme.dark()],
        ),
        builder: (context, child) => Directionality(
          textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.textScale),
            ),
            child: child!,
          ),
        ),
        home: DemoShell(settings: settings),
      ),
    ),
  );
}
