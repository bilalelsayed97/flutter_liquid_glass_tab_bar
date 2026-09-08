import 'scroll_gesture.dart';
import 'tab_layout.dart';

/// Decides whether the bar is docked or split from a [LiquidGlassScrollGesture].
///
/// The rule is deliberately hard to trip, because every spurious flip
/// interrupts a morph that is already running. Two independent forms of
/// hysteresis do that work:
///
/// * **On position** — [splitOffset] and [dockOffset] differ, so the band
///   between them holds whatever layout is already in effect.
/// * **On travel** — a decision needs *sustained* movement in one direction
///   ([LiquidGlassScrollGesture.travel]), not one frame's delta.
class LiquidGlassCollapsePolicy {
  /// Offset past which sustained downward travel may split the bar.
  final double splitOffset;

  /// Offset below which the bar always re-docks, whatever the travel. Lower
  /// than [splitOffset] on purpose: the gap is the hysteresis band.
  final double dockOffset;

  /// Sustained downward travel that splits the bar.
  final double splitTravel;

  /// Sustained upward travel that re-docks it. Smaller than [splitTravel]:
  /// getting the tabs back should take less deliberation than giving them up.
  final double dockTravel;

  /// Creates a policy; the defaults are tuned for a phone list.
  const LiquidGlassCollapsePolicy({
    this.splitOffset = 64,
    this.dockOffset = 24,
    this.splitTravel = 48,
    this.dockTravel = 32,
  });

  /// The layout [gesture] calls for, given the layout [current]ly in effect.
  ///
  /// [hasCard] reports whether there is a card to move into the centre;
  /// without one the split layout would leave an empty gap, so the bar stays
  /// docked.
  LiquidGlassTabLayout resolve({
    required LiquidGlassScrollGesture gesture,
    required LiquidGlassTabLayout current,
    required bool hasCard,
  }) {
    if (!hasCard) return LiquidGlassTabLayout.docked;
    if (gesture.offset <= dockOffset) return LiquidGlassTabLayout.docked;
    if (gesture.travel <= -dockTravel) return LiquidGlassTabLayout.docked;
    if (gesture.travel >= splitTravel && gesture.offset > splitOffset) {
      return LiquidGlassTabLayout.split;
    }
    return current;
  }
}
