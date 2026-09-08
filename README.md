<h1 align="center">flutter_liquid_glass_tab_bar</h1>

<p align="center">
  A liquid-glass bottom tab bar for Flutter. One refractive Impeller shader,
  a lens that follows your finger, a bar that splits around your mini player
  as you scroll. Same pixels on iOS and Android.
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_liquid_glass_tab_bar"><img src="https://img.shields.io/pub/v/flutter_liquid_glass_tab_bar" alt="pub"></a>
  <a href="https://github.com/bilalelsayed97/flutter_liquid_glass_tab_bar/actions/workflows/ci.yml"><img src="https://github.com/bilalelsayed97/flutter_liquid_glass_tab_bar/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT"></a>
</p>

---

## Features

- **Liquid glass.** A single fragment shader draws the bar, the selected
  lens, the neck that joins them, refraction, chromatic shift, specular light
  and shadow, sampling the live page beneath. No stacked blurs, no fake
  borders.
- **Drag-to-select lens.** Press anywhere on the bar and the lens comes to
  your finger; slide, and it stretches and tightens with velocity; release to
  select. One haptic per tab crossed. A tap still just selects.
- **Dock ↔ split morph.** Scroll a tab down and the bar folds its middle
  tabs away, leaving two icon pills at the edges with your card centred
  between them. Scroll up and it docks again. Spring-driven, so a reversal
  mid-morph is continuous.
- **Card slot.** Hand the bar one widget — a mini player, a banner — and it
  is positioned, never rebuilt, so playback state survives the morph.
- **2 to 6 tabs.** Odd counts give the trailing pill one more tab; the two
  pills morph with independent widths.
- **Accessible.** Labels drop instead of ellipsizing above 1.5× text scale,
  every tab is a labelled selectable button, RTL mirrors the layout, reduce
  motion removes overshoot.
- **Fallback.** Where Impeller's shader filters are unavailable (Skia, web,
  `flutter test`) the bar renders a blur with painted highlights and the
  same geometry.

## Requirements

- **Flutter 3.47 or newer.** From 3.46 Impeller stores render-to-texture
  backdrops top-down on Metal, Vulkan and OpenGL ES alike, and the shader
  samples them without a GLES y-flip. On an older engine the refraction
  would show the mirrored half of the screen on Android OpenGL ES. See
  [doc/android-liquid-glass-backdrop-flip-fix.md](doc/android-liquid-glass-backdrop-flip-fix.md).
- **Impeller enabled on both platforms** for the shader path.

  `ios/Runner/Info.plist`:
  ```xml
  <key>FLTEnableImpeller</key>
  <true/>
  ```

  `android/app/src/main/AndroidManifest.xml`, inside `<application>`:
  ```xml
  <meta-data
      android:name="io.flutter.embedding.android.EnableImpeller"
      android:value="true" />
  ```
- **Content behind the bar.** The glass refracts what is beneath it, so
  stack the bar over your page (see below) and on Android use edge-to-edge:
  ```dart
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  ```

When `LiquidGlassShaderSupport.isAvailable` is false the bar uses its
fallback material automatically. It looks like frosted glass rather than a
lens; the layout, morph and gestures are identical.

## Install

```sh
flutter pub add flutter_liquid_glass_tab_bar
```

Then, in `main()`, compile the shader before the first frame:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await precacheLiquidGlassShader();
  runApp(const MyApp());
}
```

## Quick start

`LiquidGlassTabScaffold` stacks the bar over lazily built, kept-alive tabs.
Put it in `Scaffold.body` with `extendBody: true`.

```dart
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final _controller = LiquidGlassTabController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: LiquidGlassTabScaffold(
      controller: _controller,
      items: const [
        LiquidGlassTabItem(icon: CupertinoIcons.house_fill, label: 'Home'),
        LiquidGlassTabItem(icon: CupertinoIcons.search, label: 'Search'),
        LiquidGlassTabItem(icon: CupertinoIcons.music_note_list, label: 'Library'),
        LiquidGlassTabItem(icon: CupertinoIcons.gear_solid, label: 'Settings'),
      ],
      tabBuilders: [
        (_) => const HomePage(),
        (_) => const SearchPage(),
        (_) => const LibraryPage(),
        (_) => const SettingsPage(),
      ],
      card: const MiniPlayer(),
    ),
  );
}
```

Inset each tab's scrollable by `LiquidGlassTabBar.estimatedDockedHeight`
plus the bottom safe-area padding so the last item is not trapped under the
glass.

### Using the bar alone

If you already have a shell, use `LiquidGlassTabBar` directly. It is a plain
widget: give it the items, the selected index, the layout and a callback.

```dart
Stack(
  children: [
    Positioned.fill(child: pages[selected]),
    PositionedDirectional(
      start: 0, end: 0, bottom: 0,
      child: LiquidGlassTabBar(
        items: items,
        selectedIndex: selected,
        layout: layout,           // docked or split — yours to decide
        onSelect: (i) => setState(() => selected = i),
        card: const MiniPlayer(),
      ),
    ),
  ],
)
```

## Scroll collapse

`LiquidGlassTabController` turns scroll frames into a layout through a
`LiquidGlassCollapsePolicy` with two kinds of hysteresis — on position and on
sustained travel — so a bouncing settle never flips the bar mid-morph. The
scaffold already wraps the tabs in a `LiquidGlassTabScrollReporter`; only
depth-zero vertical scroll views drive the bar, so nested carousels and
sheets do not collapse it.

To make re-tapping the selected tab scroll it to the top, register the tab's
scroll controller:

```dart
LiquidGlassTabScrollTarget(
  tabController: controller,
  scrollController: _scroll,
  child: ListView.builder(controller: _scroll, ...),
)
```

Tune the thresholds if your lists are short:

```dart
LiquidGlassTabController(
  collapsePolicy: const LiquidGlassCollapsePolicy(splitOffset: 32, splitTravel: 24),
)
```

## The card slot

Pass a bare widget as `card`; the bar adds the edge and bottom padding that
lines it up with the pills. Docked, it sits above the bar; split, it is
centred vertically against the two pills even when it is taller than they
are. It is one widget instance that is positioned, not rebuilt.

If the card can disappear, tell the controller so the bar docks when it
does:

```dart
final hasCard = ValueNotifier(false);
final controller = LiquidGlassTabController(hasCard: hasCard);
```

Without a card the bar never splits — there would be nothing to hold the
centre.

## Theming

Register a `LiquidGlassTabBarTheme` on your `ThemeData` (the light and dark
constructors are neutral defaults) or pass one to a single bar's `theme`.

```dart
ThemeData(
  extensions: [
    LiquidGlassTabBarTheme.light().copyWith(
      activeColor: const Color(0xFF007338),
      indicatorColor: const Color(0xFFE4EEE6),
      tint: const Color(0xFFE4EEE6),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
    ),
  ],
)
```

| Field | What it colours |
|---|---|
| `activeColor` / `inactiveColor` | Glyph and label of the tab under the lens / every other tab |
| `indicatorColor` | The resting lens behind the selected tab (fades out while moving) |
| `tint`, `tintOpacity` | The whole material |
| `attenuationColor` | Shadow and lower-edge darkening |
| `specularColor` | Rim and highlight reflections |
| `labelStyle` | Label size, weight, family (colour is per tab) |

## Accessibility and RTL

- `MediaQuery.disableAnimations` (iOS Reduce Motion, Android animator scale)
  removes spring overshoot; override with `reduceMotion:`.
- Labels are dropped above `maxLabelTextScale` (default 1.5) rather than
  ellipsized; the pill keeps its 48 pt touch target at every scale.
- Every tab is a semantics button with `selected` state and a label; pass
  `semanticLabel` when the visible label is not what should be read aloud.
- In RTL the layout, lens and gestures mirror while indexes stay logical.
- `enableHaptics: false` silences the per-tab selection tick.

## Platform notes

- The bar is pure Flutter: no platform views, no UIKit. Android and iOS get
  the same material. Under Impeller both Android backends (Vulkan and OpenGL
  ES) render identically; do not add an `IMPELLER_TARGET_OPENGLES` flip to
  the shader.
- `SafeArea(bottom: true)` is applied inside the bar (`useSafeArea: false`
  to opt out), so the gap below the glass follows the device: home
  indicator on iOS, gesture or button navigation on Android.
- `flutter test` runs on Skia and exercises the fallback; goldens of the
  shader path have to come from a device (`example/integration_test`).

## FAQ

**It looks like a plain blur.** Impeller is off, or the app runs on web or
desktop. Check `LiquidGlassShaderSupport.isAvailable` and the flags above.

**Does it work with go_router / auto_route?** Yes. The bar knows nothing
about routing: keep the selected index in your router and pass it in, or
use `LiquidGlassTabScaffold` as the shell of a single route.

**Can a card with its own blur stay sharp during the morph?** Read
`LiquidGlassRepaintScope.maybeOf(context)` inside the card and add it to
the repaint triggers of your backdrop layer.

## License

MIT © 2026 Bilal Elsayed. See [LICENSE](LICENSE).
