import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/glass_spec.dart';
import 'lens_position_resolver.dart';
import 'lens_state.dart';
import 'morph_geometry.dart';

/// Gesture-driven, interruptible motion source for the selected glass lens.
class GlassLensDriver extends ChangeNotifier {
  static const GlassLensPositionResolver _resolver =
      GlassLensPositionResolver();

  final AnimationController _controller;
  final AnimationController _interactionController;
  final AnimationController _surfaceController;

  /// Whether a candidate change during a drag ticks the haptic engine.
  bool enableHaptics;

  int _committedIndex;
  int _candidateIndex;
  bool _pressed = false;
  bool _dragging = false;
  bool _reduceMotion = false;
  double _dragVelocity = 0;
  double? _downCoordinate;
  double? _grabOffset;
  double? _lastPosition;
  Duration? _lastTimeStamp;
  int? _settlingIndex;

  /// Creates a driver resting on [committedIndex].
  GlassLensDriver({
    required TickerProvider vsync,
    required int committedIndex,
    this.enableHaptics = true,
  }) : _committedIndex = committedIndex,
       _candidateIndex = committedIndex,
       _controller = AnimationController.unbounded(
         vsync: vsync,
         value: committedIndex.toDouble(),
       ),
       _interactionController = AnimationController.unbounded(vsync: vsync),
       _surfaceController = AnimationController.unbounded(vsync: vsync) {
    _controller.addListener(notifyListeners);
    _controller.addStatusListener(_onStatusChanged);
    _interactionController.addListener(notifyListeners);
    _surfaceController.addListener(notifyListeners);
  }

  /// The lens's current frame.
  GlassLensState get state => GlassLensState(
    position: _controller.value,
    velocity: _dragging ? _dragVelocity : _controller.velocity,
    candidateIndex: _candidateIndex,
    pressed: _pressed,
    interactionAmount: _interactionController.value.clamp(0.0, 1.0),
    dragging: _dragging,
  );

  /// Slower expansion channel for the whole navigation platter.
  double get surfaceAmount => _surfaceController.value.clamp(0.0, 1.0);

  /// Whether the lens has no active pointer or spring motion.
  bool get isAtRest => !_pressed && !_dragging && !_controller.isAnimating;

  /// Whether spring overshoot and velocity response should be removed.
  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (!value) return;
    _interactionController
      ..stop()
      ..value = _pressed ? 1 : 0;
    _surfaceController
      ..stop()
      ..value = _pressed ? 1 : 0;
    notifyListeners();
  }

  /// Arms the lens for a press at [coordinate].
  void begin({
    required double coordinate,
    required Duration timeStamp,
    required GlassMorphGeometry geometry,
  }) {
    _controller.stop();
    _settlingIndex = null;
    _pressed = true;
    _dragging = false;
    _dragVelocity = 0;
    _downCoordinate = coordinate;
    _lastPosition = _controller.value;
    _lastTimeStamp = timeStamp;
    _grabOffset = _grabOffsetFor(coordinate, geometry);
    _settleInteraction(1, GlassSpec.lensLiftSpring);
    _settleSurface(1, GlassSpec.barLiftSpring);
    notifyListeners();
  }

  double _grabOffsetFor(double coordinate, GlassMorphGeometry geometry) {
    final lensCoordinate = _resolver.coordinateOf(
      geometry: geometry,
      position: _controller.value,
    );
    final liveSlotWidth = _resolver.slotWidthAt(
      geometry: geometry,
      position: _controller.value,
    );
    final landedOnLens =
        (coordinate - lensCoordinate).abs() <= liveSlotWidth / 2;
    return landedOnLens ? coordinate - lensCoordinate : 0;
  }

  /// Moves the lens with the pointer once it has crossed touch slop.
  void update({
    required double coordinate,
    required Duration timeStamp,
    required GlassMorphGeometry geometry,
  }) {
    final down = _downCoordinate;
    if (!_pressed || down == null) return;
    if (!_dragging && (coordinate - down).abs() < GlassSpec.dragSlop) return;
    _dragging = true;
    final dragPosition = _resolver.positionOf(
      geometry: geometry,
      coordinate: coordinate - (_grabOffset ?? 0),
    );
    _recordVelocity(dragPosition, timeStamp);
    _controller.value = dragPosition;
    _lastPosition = dragPosition;
    _lastTimeStamp = timeStamp;
    _updateCandidate(geometry);
  }

  void _recordVelocity(double position, Duration timeStamp) {
    final previousPosition = _lastPosition ?? position;
    final previousTime = _lastTimeStamp ?? timeStamp;
    final elapsedMicros = (timeStamp - previousTime).inMicroseconds;
    if (elapsedMicros <= 0) return;
    _dragVelocity =
        (position - previousPosition) /
        (elapsedMicros / Duration.microsecondsPerSecond);
  }

  /// Finishes the interaction and returns the logical tab to commit.
  int end({required double coordinate, required GlassMorphGeometry geometry}) {
    final target = _dragging
        ? _resolver.releaseIndex(
            geometry: geometry,
            position: _controller.value,
            velocity: _dragVelocity,
          )
        : geometry.indexAt(coordinate);
    _pressed = false;
    _dragging = false;
    _settleInteraction(0, GlassSpec.lensReleaseSpring);
    _settleSurface(0, GlassSpec.barReleaseSpring);
    _clearPointerSamples();
    _settleTo(target, initialVelocity: _dragVelocity);
    _dragVelocity = 0;
    return target;
  }

  /// Rolls a cancelled interaction back to the committed tab.
  void cancel() {
    if (!_pressed && !_dragging) return;
    _pressed = false;
    _dragging = false;
    _settleInteraction(0, GlassSpec.lensReleaseSpring);
    _settleSurface(0, GlassSpec.barReleaseSpring);
    _clearPointerSamples();
    _settleTo(_committedIndex, initialVelocity: _dragVelocity);
    _dragVelocity = 0;
  }

  /// Reconciles an external selection without fighting an already-running
  /// settlement towards the same destination.
  void syncCommittedIndex(int index) {
    final unchanged = _committedIndex == index;
    _committedIndex = index;
    if (_pressed || _dragging || _settlingIndex == index) return;
    if (unchanged &&
        !_controller.isAnimating &&
        (_controller.value - index).abs() < precisionErrorTolerance) {
      return;
    }
    _candidateIndex = index;
    _settleTo(index, initialVelocity: _controller.velocity);
  }

  void _updateCandidate(GlassMorphGeometry geometry) {
    final candidate = _resolver.candidateIndex(
      geometry: geometry,
      position: _controller.value,
      currentCandidate: _candidateIndex,
    );
    if (candidate == _candidateIndex) return;
    _candidateIndex = candidate;
    if (enableHaptics) unawaited(HapticFeedback.selectionClick());
    notifyListeners();
  }

  void _settleTo(int index, {required double initialVelocity}) {
    _candidateIndex = index;
    _settlingIndex = index;
    _controller.animateWith(
      SpringSimulation(
        GlassSpec.lensSpring,
        _controller.value,
        index.toDouble(),
        initialVelocity,
        snapToEnd: true,
      ),
    );
    notifyListeners();
  }

  void _settleInteraction(double target, SpringDescription spring) {
    if (_reduceMotion) {
      _interactionController
        ..stop()
        ..value = target;
      return;
    }
    _interactionController.animateWith(
      SpringSimulation(
        spring,
        _interactionController.value,
        target,
        _interactionController.velocity,
        snapToEnd: true,
      ),
    );
  }

  void _settleSurface(double target, SpringDescription spring) {
    if (_reduceMotion) {
      _surfaceController
        ..stop()
        ..value = target;
      return;
    }
    _surfaceController.animateWith(
      SpringSimulation(
        spring,
        _surfaceController.value,
        target,
        _surfaceController.velocity,
        snapToEnd: true,
      ),
    );
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _settlingIndex = null;
    notifyListeners();
  }

  void _clearPointerSamples() {
    _downCoordinate = null;
    _grabOffset = null;
    _lastPosition = null;
    _lastTimeStamp = null;
  }

  @override
  void dispose() {
    _controller.removeListener(notifyListeners);
    _controller.removeStatusListener(_onStatusChanged);
    _interactionController.removeListener(notifyListeners);
    _surfaceController.removeListener(notifyListeners);
    _controller.dispose();
    _interactionController.dispose();
    _surfaceController.dispose();
    super.dispose();
  }
}
