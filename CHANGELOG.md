# Changelog

## 0.1.0 - 2026-09-08

First standalone release, extracted from the Quran Kareem app's bottom
navigation bar (in-app versions 1.0.0 through 1.4.9) and generalised to any
tab count.

### Added
- `LiquidGlassTabBar`: a floating glass tab bar with docked and split
  layouts, for 2 to 6 tabs. An odd count gives the trailing pill one more tab
  and the two pills morph with independent widths.
- Refractive liquid-glass material rendered by `shaders/liquid_glass.frag`
  on Impeller, with a `BackdropFilter` fallback that keeps identical
  geometry on renderers without shader filters.
- Drag-to-select lens: press, slide along the bar, release to commit; one
  haptic per candidate change; spring settle; reduce-motion aware.
- Scroll-driven dock/split morph with a reversal-safe spring, fed by
  `LiquidGlassTabScrollReporter` (depth-zero vertical scrolls only) and a
  tunable `LiquidGlassCollapsePolicy`.
- Card slot: hand the bar one widget and it is positioned above the pills
  when docked and beside them when split, without being rebuilt.
- `LiquidGlassTabController`: selection, layout, `hasCard` presence, and
  re-tap-to-scroll-to-top through `LiquidGlassTabScrollTarget`.
- `LiquidGlassTabScaffold` and `LiquidGlassTabHost`: lazily built,
  kept-alive tabs with tickers muted while hidden.
- `LiquidGlassTabBarTheme` as a `ThemeExtension` with light and dark
  defaults.
- Tab labels hide above 1.5× text scale, every tab is a labelled selectable
  button, RTL mirrors the layout while indexes stay logical.

### Requirements
- Flutter >= 3.47.0 with Impeller enabled on iOS and Android for the shader
  path. Backdrops are sampled without a GLES y-flip; older engines would
  mirror the refraction on Android OpenGL ES.
