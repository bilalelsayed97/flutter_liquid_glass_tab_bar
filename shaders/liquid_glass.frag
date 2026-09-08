#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// ImageFilter.shader owns this first vec2 and the first sampler. The Dart
// binder (GlassShaderUniforms) writes every remaining slot, in this order.
uniform vec2 uTextureSize;
uniform vec2 uOrigin;
uniform vec2 uSurfaceSize;
uniform vec4 uBaseGeometry; // inset, left group width, resting height, active height
uniform vec4 uLensGeometry; // left, bottom, width, height
uniform vec4 uMotion; // pressed, surface lift, velocity, dock/split progress
uniform vec4 uOptics; // displacement, chroma, saturation, blur radius
uniform vec4 uTint;
uniform vec4 uSpecular;
uniform vec4 uAttenuation;
uniform vec4 uLensTint;
uniform vec4 uRightGeometry; // right group width, reserved, reserved, reserved
uniform vec4 uComponentGeometry; // radius, thickness, optical padding, mode
uniform vec4 uInteraction; // direction x/y, depth, ambient-light amount
uniform float uPixelScale;
uniform sampler2D uBackdrop;

out vec4 fragColor;

bool isComponentMode() {
  return uComponentGeometry.w > 0.5;
}

float roundedBoxSdf(
  vec2 point,
  vec2 center,
  vec2 boxSize,
  float requestedRadius
) {
  vec2 halfSize = max(boxSize * 0.5, vec2(0.001));
  float radius = clamp(requestedRadius, 0.0, min(halfSize.x, halfSize.y));
  vec2 q = abs(point - center) - halfSize + vec2(radius);
  return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

float smoothUnion(float first, float second, float radius) {
  float safeRadius = max(radius, 0.001);
  float h = clamp(0.5 + 0.5 * (second - first) / safeRadius, 0.0, 1.0);
  return mix(second, first, h) - safeRadius * h * (1.0 - h);
}

float componentSdf(vec2 point) {
  float padding = max(uComponentGeometry.z, 0.0);
  vec2 componentSize = max(
    uSurfaceSize - vec2(padding * 2.0),
    vec2(0.001)
  );
  return roundedBoxSdf(
    point,
    uSurfaceSize * 0.5,
    componentSize,
    uComponentGeometry.x
  );
}

// The two tab groups may differ in width: an odd tab count puts one more
// tab in the trailing group, so mid-morph the pills are not mirror images.
// Widths arrive already resolved to the physical left/right axis.
float baseSdf(vec2 point, float height) {
  float inset = uBaseGeometry.x;
  float leftWidth = max(uBaseGeometry.y, 0.001);
  float rightWidth = max(uRightGeometry.x, 0.001);
  float centerY = uSurfaceSize.y * 0.5;
  float contentWidth = max(uSurfaceSize.x - 2.0 * inset, 0.001);
  float leftCenter = inset + leftWidth * 0.5;
  float rightCenter = uSurfaceSize.x - inset - rightWidth * 0.5;

  float fullBar = roundedBoxSdf(
    point,
    vec2(uSurfaceSize.x * 0.5, centerY),
    vec2(contentWidth, height),
    height * 0.5
  );
  float left = roundedBoxSdf(
    point,
    vec2(leftCenter, centerY),
    vec2(leftWidth, height),
    height * 0.5
  );
  float right = roundedBoxSdf(
    point,
    vec2(rightCenter, centerY),
    vec2(rightWidth, height),
    height * 0.5
  );
  float separated = min(left, right);
  float morph = smoothstep(0.08, 0.92, uMotion.w);
  return mix(fullBar, separated, morph);
}

float lensSdf(vec2 point) {
  vec2 lensSize = max(uLensGeometry.zw, vec2(0.001));
  vec2 center = vec2(
    uLensGeometry.x + lensSize.x * 0.5,
    uSurfaceSize.y - uLensGeometry.y - lensSize.y * 0.5
  );
  return roundedBoxSdf(
    point,
    center,
    lensSize,
    min(lensSize.x, lensSize.y) * 0.5
  );
}

float sceneSdf(vec2 point) {
  if (isComponentMode()) {
    return componentSdf(point);
  }
  float activeBase = baseSdf(point, uBaseGeometry.w);
  float lens = lensSdf(point);
  float connectionActivity = max(uMotion.x, uMotion.y);
  float neckRadius = mix(3.5, 6.5, connectionActivity);
  float activeVolume = smoothUnion(activeBase, lens, neckRadius);
  return mix(
    activeBase,
    activeVolume,
    smoothstep(0.0, 1.0, connectionActivity)
  );
}

vec3 sceneField(vec2 point) {
  const vec2 epsilon = vec2(1.0, 0.0);
  float distance = sceneSdf(point);
  float horizontal =
    sceneSdf(point + epsilon.xy) - sceneSdf(point - epsilon.xy);
  float vertical =
    sceneSdf(point + epsilon.yx) - sceneSdf(point - epsilon.yx);
  vec2 gradient = vec2(horizontal, vertical) * 0.5;
  float magnitude = max(length(gradient), 0.1);
  return vec3(distance / magnitude, gradient / magnitude);
}

vec2 restingBaseNormal(vec2 point) {
  const vec2 epsilon = vec2(1.0, 0.0);
  float horizontal =
    baseSdf(point + epsilon.xy, uBaseGeometry.z) -
    baseSdf(point - epsilon.xy, uBaseGeometry.z);
  float vertical =
    baseSdf(point + epsilon.yx, uBaseGeometry.z) -
    baseSdf(point - epsilon.yx, uBaseGeometry.z);
  return normalize(vec2(horizontal, vertical) + vec2(0.0001));
}

vec2 lensNormal(vec2 point) {
  const vec2 epsilon = vec2(1.0, 0.0);
  float horizontal = lensSdf(point + epsilon.xy) - lensSdf(point - epsilon.xy);
  float vertical = lensSdf(point + epsilon.yx) - lensSdf(point - epsilon.yx);
  return normalize(vec2(horizontal, vertical) + vec2(0.0001));
}

vec3 glassNormal(float signedDistance, vec2 planarNormal, float thickness) {
  float rimProgress = clamp(
    1.0 + signedDistance / max(thickness, 1.0),
    0.0,
    1.0
  );
  float slope = smoothstep(0.0, 1.0, rimProgress);
  float facing = sqrt(max(1.0 - slope * slope, 0.025));
  return normalize(vec3(planarNormal * slope, facing));
}

vec2 textureUv(vec2 coordinate) {
  // No IMPELLER_TARGET_OPENGLES y-flip here, on purpose. Since Flutter 3.46
  // (flutter/flutter#186554) Impeller absorbs OpenGL ES's render-to-texture
  // Y-axis difference in the vertex stage, so a backdrop snapshot is stored
  // top-down on Metal, Vulkan, and GLES alike. The engine dropped the same
  // flip from its own runtime-effect fixtures in that change. Re-adding it
  // double-flips GLES devices, which makes every glass surface refract the
  // mirrored half of the screen. The `ImageFilter.shader` API doc still shows
  // the old flip; it is stale. See
  // doc/android-liquid-glass-backdrop-flip-fix.md.
  vec2 uv = coordinate / uTextureSize;
  return clamp(uv, vec2(0.001), vec2(0.999));
}

vec4 blurredBackdrop(vec2 coordinate, float radius) {
  vec2 nearAxis = vec2(radius * 0.45, 0.0);
  vec2 farAxis = vec2(radius, 0.0);
  vec2 nearDiagonal = vec2(radius * 0.39);
  vec2 farDiagonal = vec2(radius * 0.78);
  vec4 result = texture(uBackdrop, textureUv(coordinate)) * 0.16;
  result += (
    texture(uBackdrop, textureUv(coordinate + nearAxis.xy)) +
    texture(uBackdrop, textureUv(coordinate - nearAxis.xy)) +
    texture(uBackdrop, textureUv(coordinate + nearAxis.yx)) +
    texture(uBackdrop, textureUv(coordinate - nearAxis.yx))
  ) * 0.08;
  result += (
    texture(uBackdrop, textureUv(coordinate + farAxis.xy)) +
    texture(uBackdrop, textureUv(coordinate - farAxis.xy)) +
    texture(uBackdrop, textureUv(coordinate + farAxis.yx)) +
    texture(uBackdrop, textureUv(coordinate - farAxis.yx))
  ) * 0.05;
  result += (
    texture(uBackdrop, textureUv(coordinate + nearDiagonal)) +
    texture(uBackdrop, textureUv(coordinate - nearDiagonal)) +
    texture(uBackdrop, textureUv(coordinate + vec2(nearDiagonal.x, -nearDiagonal.y))) +
    texture(uBackdrop, textureUv(coordinate + vec2(-nearDiagonal.x, nearDiagonal.y)))
  ) * 0.05;
  result += (
    texture(uBackdrop, textureUv(coordinate + farDiagonal)) +
    texture(uBackdrop, textureUv(coordinate - farDiagonal)) +
    texture(uBackdrop, textureUv(coordinate + vec2(farDiagonal.x, -farDiagonal.y))) +
    texture(uBackdrop, textureUv(coordinate + vec2(-farDiagonal.x, farDiagonal.y)))
  ) * 0.03;
  return result;
}

vec3 saturated(vec3 color, float amount) {
  float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
  return mix(vec3(luminance), color, amount);
}

void main() {
  vec2 fragment = FlutterFragCoord().xy;
  float pixelScale = max(uPixelScale, 1.0);
  vec2 local = fragment / pixelScale - uOrigin;
  vec3 field = sceneField(local);
  float surface = field.x;
  float coverage = 1.0 - smoothstep(-0.8, 0.8, surface);

  float shadowDistance = sceneSdf(local - vec2(0.0, 3.0));
  float shadow =
    (1.0 - smoothstep(0.0, 10.0, shadowDistance)) *
    (1.0 - coverage) *
    uAttenuation.a;
  if (coverage < 0.001 && shadow < 0.001) {
    fragColor = vec4(0.0);
    return;
  }

  bool componentMode = isComponentMode();
  float lens = componentMode ? 10000.0 : lensSdf(local);
  float lensMask = componentMode ? 0.0 : 1.0 - smoothstep(-1.0, 1.0, lens);
  float lensActivity = mix(0.30, 1.0, uMotion.x);
  float activeLensMask = lensMask * lensActivity;
  float materialActivity = componentMode
    ? uInteraction.z
    : max(uMotion.x, uMotion.y);
  float restingBase = componentMode
    ? 10000.0
    : baseSdf(local, uBaseGeometry.z);
  float activeBase = componentMode
    ? surface
    : baseSdf(local, uBaseGeometry.w);
  float activeBaseCoverage = 1.0 - smoothstep(-1.0, 1.0, activeBase);

  vec2 planarNormal = field.yz;
  if (componentMode) {
    planarNormal += uInteraction.xy * uInteraction.z * 0.08;
  }
  float insideDistance = max(-surface, 0.0);
  float glassThickness = componentMode
    ? max(uComponentGeometry.y, 1.0)
    : 13.0 + activeLensMask * 3.0;
  vec3 normal = glassNormal(surface, planarNormal, glassThickness);
  float edge = 1.0 - smoothstep(0.0, glassThickness * 1.35, insideDistance);
  float rimReach =
    uOptics.x * edge * mix(0.62, 1.0, activeLensMask) /
    max(normal.z, 0.20);

  float lensInsideDistance = max(-lens, 0.0);
  float lensEdge = componentMode ? 0.0 :
    (1.0 - smoothstep(0.0, glassThickness, lensInsideDistance)) *
    lensMask * activeBaseCoverage;
  vec2 opticalLensNormal = componentMode ? vec2(0.0) : lensNormal(local);
  vec3 opticalLensSurface = glassNormal(
    lens,
    opticalLensNormal,
    glassThickness
  );
  float lensReach =
    uOptics.x * lensEdge * lensActivity * 0.72 /
    max(opticalLensSurface.z, 0.24);
  vec2 restingNormal = componentMode ? vec2(0.0) : restingBaseNormal(local);
  float historyBand = componentMode ? 0.0 :
    exp(-abs(restingBase) * 0.26) * lensMask * materialActivity;
  float historyRefraction = historyBand * mix(3.4, 5.2, uMotion.x);
  vec2 componentRefraction = componentMode
    ? uInteraction.xy * uInteraction.z * uOptics.x * 0.18
    : vec2(0.0);
  vec2 refraction =
    -normal.xy * rimReach -
    opticalLensSurface.xy * lensReach -
    restingNormal * historyRefraction +
    vec2(uMotion.z * 1.35 * edge, 0.0) +
    componentRefraction;
  // Geometry is surface-local, but the engine-owned backdrop is addressed in
  // the fragment's texture space. Subtracting uOrigin here would sample the
  // same top-of-screen pixels after the surface moves or the page scrolls.
  vec2 displacedCoordinate = fragment + refraction * pixelScale;

  float chroma = uOptics.y * edge * mix(0.35, 1.0, activeLensMask);
  vec4 backdropSample = blurredBackdrop(
    displacedCoordinate,
    uOptics.w * pixelScale
  );
  vec3 material = saturated(backdropSample.rgb, uOptics.z);
  material += vec3(normal.x, -abs(normal.x) * 0.16, -normal.x) *
    chroma * 0.018;

  float tintAmount = componentMode
    ? uTint.a
    : uTint.a * mix(0.72, 1.0, activeLensMask);
  material = mix(material, uTint.rgb, tintAmount);
  material = mix(material, uLensTint.rgb, lensMask * uLensTint.a);
  if (componentMode) {
    material = mix(
      material,
      uSpecular.rgb,
      uInteraction.w
    );
  }

  float lensDepth = lensMask * mix(0.012, 0.085, materialActivity);
  material = mix(material, uSpecular.rgb, lensDepth);
  float historyDensity = historyBand * mix(0.018, 0.045, uMotion.x);
  material = mix(material, uAttenuation.rgb, historyDensity);

  vec2 interactionLight = componentMode
    ? uInteraction.xy * 0.16
    : vec2(-uMotion.z * 0.12, 0.0);
  vec2 lightDirection = normalize(vec2(-0.38, -1.0) - interactionLight);
  float directional = pow(max(dot(normal.xy, lightDirection), 0.0), 2.2);
  float adaptiveLuminance = dot(material, vec3(0.2126, 0.7152, 0.0722));
  vec3 adaptiveHighlight = mix(
    uSpecular.rgb,
    material,
    adaptiveLuminance * 0.55
  );
  float fresnel = pow(1.0 - normal.z, 4.0);
  float lensFresnel =
    pow(1.0 - opticalLensSurface.z, 4.0) * lensEdge * lensActivity;
  float interactionBoost = componentMode
    ? mix(1.0, 1.18, uInteraction.z)
    : 1.0;
  float highlight =
    ((directional * 0.62 + fresnel * 0.38) * edge + lensFresnel * 0.22) *
    uSpecular.a * interactionBoost;
  material = mix(material, adaptiveHighlight, highlight);

  float verticalPosition = local.y / max(uSurfaceSize.y, 1.0);
  if (componentMode) {
    float padding = max(uComponentGeometry.z, 0.0);
    verticalPosition =
      (local.y - padding) /
      max(uSurfaceSize.y - padding * 2.0, 1.0);
  }
  float lowerAttenuation =
    smoothstep(0.42, 1.0, verticalPosition) * uAttenuation.a;
  material = mix(material, uAttenuation.rgb, lowerAttenuation);

  vec3 premultiplied =
    material * coverage + uAttenuation.rgb * shadow * (1.0 - coverage);
  float alpha = max(coverage, shadow);
  fragColor = vec4(premultiplied, alpha);
}
