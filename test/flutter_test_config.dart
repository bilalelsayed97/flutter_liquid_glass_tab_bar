import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the Material icon font once for every test, so goldens render real
/// glyphs instead of placeholder boxes. Text keeps flutter_test's
/// deterministic default font; the package bundles no fonts of its own.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final materialFonts = _materialFontsDirectory();
  if (materialFonts != null) {
    final file = File('$materialFonts/MaterialIcons-Regular.otf');
    if (file.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(
          file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)),
        );
      await loader.load();
    }
  }
  await testMain();
}

/// The Flutter SDK's bundled Material font directory, derived from the
/// running Dart executable.
String? _materialFontsDirectory() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path) {
    final fonts = Directory(
      '${directory.path}/bin/cache/artifacts/material_fonts',
    );
    if (fonts.existsSync()) return fonts.path;
    directory = directory.parent;
  }
  return null;
}
