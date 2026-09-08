import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

import '../theme/glass_motion.dart';

/// Drives the bar's dock ↔ split morph with a spring.
///
/// The layout is decided by scrolling, so a new target can arrive halfway
/// through a morph that is already running. A spring restarted from the
/// current value **and velocity** is continuous in both, so a reversal traces
/// one arc; a reversed curve would drop its velocity to zero and read as a
/// stall. The spring is critically damped, so [progress] stays inside `0..1`.
class GlassMorphDriver {
  final AnimationController _controller;

  /// Creates a driver resting at the [split] or docked endpoint.
  GlassMorphDriver({required TickerProvider vsync, required bool split})
    : _controller = AnimationController(
        vsync: vsync,
        // Never used to run anything: every motion goes through `animateWith`
        // with an explicit simulation.
        duration: GlassMotion.morph,
        value: split ? 1 : 0,
      );

  /// `0` docked, `1` split. Drive an `AnimatedBuilder` from this.
  Animation<double> get progress => _controller;

  /// Springs towards [split]'s endpoint from wherever the morph is now. Safe
  /// to call with the target already in effect — an idle bar stays idle.
  void settleTo({required bool split}) {
    final target = split ? 1.0 : 0.0;
    if (_controller.value == target && !_controller.isAnimating) return;

    // Both must be read before `animateWith`, which calls `stop()`.
    final from = _controller.value;
    final velocity = _controller.velocity;

    final simulation = SpringSimulation(
      GlassMotion.morphSpring,
      from,
      target,
      velocity,
      // A spring approaches its target asymptotically; snap so the geometry
      // actually reaches an endpoint and the status listener fires.
      snapToEnd: true,
    );

    if (split) {
      _controller.animateWith(simulation);
    } else {
      _controller.animateBackWith(simulation);
    }
  }

  /// Releases the underlying controller.
  void dispose() => _controller.dispose();
}
