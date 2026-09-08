import 'package:flutter/widgets.dart';

/// Keeps a handle on each tab's primary [ScrollController] so re-tapping a
/// tab can scroll it back to the top.
class GlassTabScrollRegistry {
  final Map<int, ScrollController> _controllers = {};
  final Duration _duration;
  final Curve _curve;

  /// Creates a registry whose scroll-to-top uses [duration] and [curve].
  GlassTabScrollRegistry({required Duration duration, required Curve curve})
    // ignore: prefer_initializing_formals
    : _duration = duration,
      // ignore: prefer_initializing_formals
      _curve = curve;

  /// Associates [controller] with tab [index], replacing any previous entry.
  void register(int index, ScrollController controller) {
    _controllers[index] = controller;
  }

  /// Drops [controller] from tab [index] — a no-op when a newer controller
  /// already took the slot, so a remount ordered dispose-after-init stays
  /// correct.
  void unregister(int index, ScrollController controller) {
    if (identical(_controllers[index], controller)) _controllers.remove(index);
  }

  /// Animates tab [index]'s scroll view back to the top. Does nothing when
  /// the tab has no registered controller, the controller has no attached
  /// view yet, or it is already at the top.
  void scrollToTop(int index) {
    final controller = _controllers[index];
    if (controller == null || !controller.hasClients) return;
    if (controller.offset <= 0) return;
    controller.animateTo(0, duration: _duration, curve: _curve);
  }
}
