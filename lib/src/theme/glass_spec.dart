// ignore_for_file: public_member_api_docs

import 'package:flutter/physics.dart';

import 'glass_motion.dart';

/// Tuning vocabulary for the bar's optical material and lens.
///
/// These values describe one physical control and are consumed as a set by
/// the fragment shader, the fallback painters and the geometry, so they are
/// not exposed individually: an incoherent combination renders as a broken
/// material rather than a customised one.
abstract final class GlassSpec {
  // Geometry.
  /// Height of the docked navigation material.
  static const double dockedHeight = 65;

  /// Gap between the lens and its slot on every edge.
  static const double lensInset = 3;

  /// Horizontal stretch of the lens midway between two tabs.
  static const double lensTravelStretch = 16;

  /// Horizontal stretch added at full drag velocity.
  static const double lensVelocityStretch = 8;

  /// Lead the lens takes ahead of its position while moving.
  static const double lensLeadingShift = 3;

  /// Vertical overflow of the lens above and below the pill while pressed.
  static const double lensInteractiveVerticalOverflow = 8;

  /// Growth of the whole bar on each edge while pressed (shader path only).
  static const double activeBarExpansion = 4;

  /// How far the lens may be dragged past the outermost slots.
  static const double maximumOverscroll = 8;

  // Fallback material.
  static const double parentBlurSigma = 20;
  static const double parentTintOpacity = 0.085;
  static const double parentTintBottomOpacity = 0.035;
  static const double parentSpecularOpacity = 0.025;
  static const double parentAttenuationOpacity = 0.035;
  static const double parentRimOpacity = 0.1;
  static const double parentRimMiddleOpacity = 0.01;
  static const double lensTintOpacity = 0.8;
  static const double lensTintBottomOpacity = 0.008;
  static const double lensLuminosityOpacity = 0.025;
  static const double lensSpecularOpacity = 0.08;
  static const double lensAttenuationOpacity = 0.04;
  static const double lensRimOpacity = 0.22;
  static const double lensRimMiddleOpacity = 0.035;
  static const double opticalStroke = 1;
  static const double lowerRimOpacity = 0.015;
  static const double lensLowerRimOpacity = 0.055;
  static const double ambientShadowOpacity = 0.045;
  static const double lensShadowOpacity = 0.065;
  static const double ambientShadowSigma = 10;
  static const double ambientShadowOffset = 3;
  static const double transparentOpacity = 0;
  static const List<double> rimStops = [0, 0.5, 1];

  /// Distance below which the two pills start pulling towards each other.
  static const double glassAttractionDistance = 64;

  /// Distance below which the two pills are drawn as one connected shape.
  static const double glassConnectionDistance = 48;

  // Gradient geometry.
  static const double parentSpecularRadius = 1.15;
  static const double parentRimEndFactor = 0.35;
  static const double lensLuminosityCenterY = -0.08;
  static const double lensLuminosityRadius = 0.95;
  static const double lensSpecularCenterX = -0.42;
  static const double lensSpecularCenterY = -1;
  static const double lensSpecularRadius = 0.72;
  static const double lensAttenuationBeginY = -0.20;
  static const double lensAttenuationEndY = 0.80;
  static const double lensRimBeginX = -0.75;
  static const double lensRimEndX = 0.75;
  static const double lensRimVelocityShift = 0.18;
  static const double lensRimEndFactor = 0.88;

  // Deformation.
  static const double maximumVelocitySlotsPerSecond = 5;
  static const double verticalTravelExpansion = 0.04;
  static const double horizontalPressExpansion = 0.02;
  static const double cornerTightening = 0.12;
  static const double specularVelocityShift = 0.28;

  // Interaction.
  /// Pointer travel before a press becomes a drag.
  static const double dragSlop = 8;
  static const double overscrollResistance = 0.20;
  static const double releaseVelocityThreshold = 1.15;
  static const double candidateHysteresis = 0.10;

  // Shader material.
  static const double shaderDisplacement = 10;
  static const double shaderBarBlurRadius = 3;
  static const double shaderChromaticShift = 0.65;
  static const double shaderSaturation = 1.08;
  static const double shaderTintOpacityLight = 0.16;
  static const double shaderTintOpacityDark = 0.22;
  static const double shaderSpecularOpacity = 0.13;
  static const double shaderAttenuationOpacity = 0.085;

  /// Paint budget around the bar that lets the lens and shadow overflow it.
  static const double shaderOpticalPadding = 14;

  // Springs.
  static final SpringDescription lensSpring = GlassMotion.selectSpring;
  static const SpringDescription lensLiftSpring = GlassMotion.glassLiftSpring;
  static const SpringDescription lensReleaseSpring =
      GlassMotion.glassFlexSpring;
  static final SpringDescription barLiftSpring =
      GlassMotion.glassSurfaceLiftSpring;
  static final SpringDescription barReleaseSpring =
      GlassMotion.glassSurfaceLiftSpring;
}
