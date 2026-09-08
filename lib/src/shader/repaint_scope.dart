import 'package:flutter/widgets.dart';

/// Adds a retained ancestor animation to a descendant's repaint triggers.
///
/// The bar publishes its morph and lens motion here. A card with its own
/// backdrop-sampling surface (a blur, a shader) can read it with [maybeOf]
/// and repaint while the bar repositions it without rebuilding it.
class LiquidGlassRepaintScope extends InheritedWidget {
  /// Animation or notifier that can change the descendant's global position.
  final Listenable repaint;

  /// Creates a repaint scope for descendant glass surfaces.
  const LiquidGlassRepaintScope({
    super.key,
    required this.repaint,
    required super.child,
  });

  /// The nearest explicitly supplied repaint trigger, if any.
  static Listenable? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<LiquidGlassRepaintScope>()
      ?.repaint;

  @override
  bool updateShouldNotify(LiquidGlassRepaintScope oldWidget) =>
      repaint != oldWidget.repaint;
}
