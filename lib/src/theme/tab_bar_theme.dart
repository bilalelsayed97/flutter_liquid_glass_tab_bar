import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Colours and label style of a [LiquidGlassTabBar].
///
/// Register it as a [ThemeExtension] on your [ThemeData] so every bar in the
/// app resolves it through [of], or hand one to a single bar's `theme`
/// parameter. Anything not supplied falls back to [fallback] for the ambient
/// brightness.
///
/// ```dart
/// ThemeData(
///   extensions: [LiquidGlassTabBarTheme.light().copyWith(activeColor: ...)],
/// )
/// ```
class LiquidGlassTabBarTheme extends ThemeExtension<LiquidGlassTabBarTheme> {
  /// Glyph and label colour of the tab under the lens.
  final Color activeColor;

  /// Glyph and label colour of every other tab.
  final Color inactiveColor;

  /// Tint of the resting lens behind the selected tab. It is faded out
  /// while the lens moves so the material stays clear mid-drag.
  final Color indicatorColor;

  /// Tint of the whole navigation material.
  final Color tint;

  /// Shadow and lower-edge attenuation colour.
  final Color attenuationColor;

  /// Highlight colour of the rim and specular reflections.
  final Color specularColor;

  /// Opacity at which [tint] is mixed into the refracted backdrop.
  final double tintOpacity;

  /// Style of the tab labels. Colour is overridden per tab; size, weight and
  /// family are yours.
  final TextStyle labelStyle;

  /// Creates a theme with every value supplied.
  const LiquidGlassTabBarTheme({
    required this.activeColor,
    required this.inactiveColor,
    required this.indicatorColor,
    required this.tint,
    required this.attenuationColor,
    required this.specularColor,
    required this.tintOpacity,
    required this.labelStyle,
  });

  /// Default label style: 12pt medium, inheriting the ambient font family.
  static const TextStyle defaultLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Neutral light palette.
  factory LiquidGlassTabBarTheme.light() => const LiquidGlassTabBarTheme(
    activeColor: Color(0xFF007AFF),
    inactiveColor: Color(0xFF6E6E73),
    indicatorColor: Color(0xFFF7F9FA),
    tint: Color(0xFFE4E7EA),
    attenuationColor: Color(0xFF2C2C2E),
    specularColor: Color(0xFFFFFFFF),
    tintOpacity: 0.16,
    labelStyle: defaultLabelStyle,
  );

  /// Neutral dark palette.
  factory LiquidGlassTabBarTheme.dark() => const LiquidGlassTabBarTheme(
    activeColor: Color(0xFF0A84FF),
    inactiveColor: Color(0xFF98989D),
    indicatorColor: Color(0xFF3A3E46),
    tint: Color(0xFF282B31),
    attenuationColor: Color(0xFF000000),
    specularColor: Color(0xFFFFFFFF),
    tintOpacity: 0.22,
    labelStyle: defaultLabelStyle,
  );

  /// The neutral palette for [brightness].
  factory LiquidGlassTabBarTheme.fallback(Brightness brightness) =>
      brightness == Brightness.dark
      ? LiquidGlassTabBarTheme.dark()
      : LiquidGlassTabBarTheme.light();

  /// The theme registered on the ambient [ThemeData], or [fallback] for its
  /// brightness when none is registered.
  static LiquidGlassTabBarTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<LiquidGlassTabBarTheme>() ??
        LiquidGlassTabBarTheme.fallback(theme.brightness);
  }

  @override
  LiquidGlassTabBarTheme copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Color? indicatorColor,
    Color? tint,
    Color? attenuationColor,
    Color? specularColor,
    double? tintOpacity,
    TextStyle? labelStyle,
  }) => LiquidGlassTabBarTheme(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    tint: tint ?? this.tint,
    attenuationColor: attenuationColor ?? this.attenuationColor,
    specularColor: specularColor ?? this.specularColor,
    tintOpacity: tintOpacity ?? this.tintOpacity,
    labelStyle: labelStyle ?? this.labelStyle,
  );

  @override
  LiquidGlassTabBarTheme lerp(LiquidGlassTabBarTheme? other, double t) {
    if (other == null) return this;
    return LiquidGlassTabBarTheme(
      activeColor: Color.lerp(activeColor, other.activeColor, t)!,
      inactiveColor: Color.lerp(inactiveColor, other.inactiveColor, t)!,
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      attenuationColor: Color.lerp(
        attenuationColor,
        other.attenuationColor,
        t,
      )!,
      specularColor: Color.lerp(specularColor, other.specularColor, t)!,
      tintOpacity: lerpDouble(tintOpacity, other.tintOpacity, t)!,
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassTabBarTheme &&
          other.activeColor == activeColor &&
          other.inactiveColor == inactiveColor &&
          other.indicatorColor == indicatorColor &&
          other.tint == tint &&
          other.attenuationColor == attenuationColor &&
          other.specularColor == specularColor &&
          other.tintOpacity == tintOpacity &&
          other.labelStyle == labelStyle;

  @override
  int get hashCode => Object.hash(
    activeColor,
    inactiveColor,
    indicatorColor,
    tint,
    attenuationColor,
    specularColor,
    tintOpacity,
    labelStyle,
  );
}
