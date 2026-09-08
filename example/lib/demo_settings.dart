import 'package:flutter/foundation.dart';

/// Everything the demo lets you toggle.
@immutable
class DemoSettings {
  final bool dark;
  final bool rtl;
  final bool showCard;
  final bool reduceMotion;
  final double textScale;
  final int tabCount;

  const DemoSettings({
    this.dark = false,
    this.rtl = false,
    this.showCard = true,
    this.reduceMotion = false,
    this.textScale = 1.0,
    this.tabCount = 4,
  });

  DemoSettings copyWith({
    bool? dark,
    bool? rtl,
    bool? showCard,
    bool? reduceMotion,
    double? textScale,
    int? tabCount,
  }) => DemoSettings(
    dark: dark ?? this.dark,
    rtl: rtl ?? this.rtl,
    showCard: showCard ?? this.showCard,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    textScale: textScale ?? this.textScale,
    tabCount: tabCount ?? this.tabCount,
  );
}

/// Holds the live [DemoSettings] for the whole demo.
class DemoSettingsController extends ValueNotifier<DemoSettings> {
  DemoSettingsController() : super(const DemoSettings());

  void update(DemoSettings Function(DemoSettings) change) =>
      value = change(value);
}
