/// A scroll position together with how far it has travelled since it last
/// changed direction.
///
/// Deciding the bar's layout from a single frame's delta cannot tell a
/// deliberate drag apart from noise: a `BouncingScrollPhysics` settle
/// alternates the delta's sign every frame, and each frame on its own clears
/// a per-frame threshold, so the bar flips repeatedly inside one morph.
///
/// Accumulating travel and resetting it whenever the direction reverses fixes
/// that at the source — alternating frames cancel instead of accumulating,
/// so only a *sustained* drag reaches a decision threshold.
class LiquidGlassScrollGesture {
  /// Current scroll offset in pixels.
  final double offset;

  /// Distance accumulated since the last direction change. Positive means
  /// scrolling down (content moving up).
  final double travel;

  /// Creates a gesture, at rest by default.
  const LiquidGlassScrollGesture({this.offset = 0, this.travel = 0});

  /// Folds one scroll frame in.
  ///
  /// [delta] continues the current run while it keeps the same sign and
  /// starts a new one the moment it flips. A zero delta carries the run
  /// unchanged; it is not a direction change.
  LiquidGlassScrollGesture extend({
    required double offset,
    required double delta,
  }) {
    final reversed =
        delta != 0 && travel != 0 && delta.isNegative != travel.isNegative;
    return LiquidGlassScrollGesture(
      offset: offset,
      travel: reversed ? delta : travel + delta,
    );
  }

  /// Forgets the accumulated run, keeping the position.
  LiquidGlassScrollGesture reset() => LiquidGlassScrollGesture(offset: offset);
}
