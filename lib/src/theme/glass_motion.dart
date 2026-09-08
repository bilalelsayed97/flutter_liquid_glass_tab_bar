import 'package:flutter/animation.dart';

/// Durations, curves and springs that drive the bar's motion.
///
/// A spring is the driver wherever an animation can be interrupted part-way:
/// restarting a spring from the current value *and* velocity is continuous in
/// both, so a reversal reads as one curve. `withDurationAndBounce` is
/// Flutter's equivalent of SwiftUI's `spring(duration:bounce:)`.
abstract final class GlassMotion {
  /// The selected lens sliding from one tab to another.
  static const Duration select = Duration(milliseconds: 260);

  /// The bar splitting apart or docking back together.
  static const Duration morph = Duration(milliseconds: 400);

  /// Programmatic scroll to the top of a tab's list.
  static const Duration scrollToTop = Duration(milliseconds: 400);

  /// The whole navigation material swelling around a held tab.
  static const Duration glassSurfaceLift = Duration(milliseconds: 500);

  /// Default easing for state changes that start and end at rest.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Critically damped dock ↔ split morph: it never overshoots, which keeps
  /// the progress inside `0..1` where the geometry is defined.
  static final SpringDescription morphSpring =
      SpringDescription.withDurationAndBounce(duration: morph, bounce: 0);

  /// The lens settling onto a tab.
  static final SpringDescription selectSpring =
      SpringDescription.withDurationAndBounce(duration: select, bounce: 0);

  /// Fast, near-critically-damped lift when a finger first takes contact.
  static const SpringDescription glassLiftSpring = SpringDescription(
    mass: 1,
    stiffness: 631.654682,
    damping: 50.265482,
  );

  /// Softer flex when the lens releases pointer velocity and returns to rest.
  static const SpringDescription glassFlexSpring = SpringDescription(
    mass: 1,
    stiffness: 175.308955,
    damping: 21.184686,
  );

  /// Soft, nearly critical lift for the bar's whole surface.
  static final SpringDescription glassSurfaceLiftSpring =
      SpringDescription.withDurationAndBounce(
        duration: glassSurfaceLift,
        bounce: 0.04,
      );
}
