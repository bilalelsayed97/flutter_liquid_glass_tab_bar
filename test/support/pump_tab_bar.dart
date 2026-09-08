import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside the minimum ancestors the bar needs: a [MaterialApp]
/// whose theme carries the brightness, an explicit [Directionality] so the
/// RTL variant mirrors, and a text scaler.
///
/// The platform is pinned to iOS: `flutter_test` reports Android by default,
/// so a widget branching on the platform would render one variant while the
/// golden silently claimed to be platform-neutral.
Future<void> pumpTabBar(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool rtl = false,
  double textScale = 1.0,
  Size surface = const Size(390, 844),
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
