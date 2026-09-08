# Fix Android liquid-glass backdrop sampling (wrong region behind glass)

Status: **applied** 2026-09-04. The hypothesis below was confirmed on a real
device before the permanent edit landed; see "Outcome" at the end for what was
verified and what was not.

## Context

On Android the glass surfaces (`AppGlassButton`, `AppGlassContainer`, the bottom
navigation bar in `BottomNavBarScreen`) refract the **wrong part of the screen**:
the bottom bar shows the "Home" header from the top of the page, the bell button
near the top shows the beige bottom of the page. iOS renders correctly.

The three Dart files involved are all consumers of **one** fragment shader,
`shaders/app_liquid_glass.frag`, through two thin render objects:

- `lib/core/widgets/app_liquid_glass_shader_backdrop.dart` (cards, buttons,
  compact player)
- `lib/features/bottom_nav_bar/presentation/widgets/bottom_nav_shader_backdrop.dart`
  (navigation bar)

The Dart side is correct on both platforms. The defect is inside the shader and
is platform-specific by construction.

## Root cause (verified against engine sources)

`textureUv()` in `shaders/app_liquid_glass.frag` (lines 165-171) flips the
sample row on the OpenGL ES backend:

```glsl
vec2 uv = coordinate / uTextureSize;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;     // <-- stale
#endif
```

Evidence chain:

1. The symptom is an exact vertical mirror. In the 2000 px tall screenshot the
   bar at y≈1880 samples y≈120 (the "Home" title row) and the bell at y≈157
   samples the bottom strip. Only a Y flip produces that; an origin offset would
   not.
2. The Android emulator used for the screenshot runs Impeller **OpenGLES**
   (logcat: `Using the Impeller rendering backend (OpenGLES)`), so the `#ifdef`
   branch is active there. Vulkan devices never define the macro and were never
   affected.
3. The project pins Flutter **3.47.1** (`.fvmrc`). Engine commit
   `475014b679b` "[Impeller] absorb OpenGL ES render-to-texture Y-axis
   difference at the GLES backend" (flutter/flutter#186554, shipped in 3.46+)
   makes render-to-texture content top-down on every backend, and the follow-up
   `73ac4622e70` removed `Texture::GetYCoordScale()` entirely. The first commit
   **deleted the `IMPELLER_TARGET_OPENGLES` flip from the engine's own
   runtime-effect fixtures** (`impeller/fixtures/runtime_stage_filter_circle.frag`,
   `runtime_stage_filter_warp.frag`, `texture.frag`). Our shader still carries
   it, so on GLES it now flips an already-upright backdrop: a double flip.
4. `FlutterFragCoord()` is `_fragCoord = position` (engine
   `impeller/entity/shaders/runtime_effect.vert`), i.e. the backdrop snapshot's
   own pixel space, unchanged by the engine change. The geometry path
   (`local = fragment / pixelScale - uOrigin`) therefore stays valid; only the
   sampling flip must go.

Note: the `ImageFilter.shader` doc comment in the engine's `lib/ui/painting.dart`
still shows the flip example. It is stale relative to the engine; the fixture
diff is the authoritative behaviour. The in-shader comment added in step 1 must
say this explicitly or the next reader will "fix" it back.

## Spec

**R1.** A glass surface samples the backdrop pixels directly beneath its own
bounds on iOS (Metal), Android Vulkan, and Android OpenGL ES, in docked and
split bar layouts, while scrolling, and during the bar morph.

**R2.** No platform branching in Dart; the shader remains backend-agnostic in
source.

**R3.** The app declares the minimum Flutter version whose engine guarantees
top-down backdrop textures, so a downgrade cannot silently reintroduce the flip.

Acceptance criteria:

- **AC1** On the GLES emulator the bottom bar over the Home stats section shows
  the stats section (red heat dots), not the header; the bell button shows the
  sky gradient behind it. Visually equivalent to the iOS screenshot.
- **AC2** iOS rendering is unchanged (the removed lines live inside a GLES-only
  `#ifdef`, so Metal never compiled them).
- **AC3** A real Vulkan Android device renders as before the change.
- **AC4** `dart analyze` is clean; `flutter test` for core ui/widgets and
  bottom_nav_bar passes. Both uniform-contract tests load the real `.frag`, so
  they prove the shader still compiles for the runtime-effect target.
- **AC5** Both changelogs carry the fix entry.

## Steps

### 0. Spike (falsify the hypothesis before editing for real)

1. Temporarily delete the three `#ifdef` lines in `textureUv()`.
2. `fvm flutter run -d <android-emulator>` (shader assets need a full build,
   not a hot reload). Confirm logcat still reports `OpenGLES`:
   `adb logcat -d | grep "Impeller rendering backend"`.
3. `adb exec-out screencap -p > /tmp/android_after.png` and compare with the
   original screenshot.
4. If the backdrop now sits under the glass, proceed. If it is still wrong,
   stop and report: the hypothesis is wrong and the next candidate is the
   `uOrigin` / snapshot re-rasterization path in the engine's
   `runtime_effect_filter_contents.cc`.

### 1. Shader fix — `shaders/app_liquid_glass.frag`

- Remove the `#ifdef IMPELLER_TARGET_OPENGLES … #endif` block from
  `textureUv()`.
- Replace it with a comment stating why there is no flip: Flutter ≥ 3.46 stores
  render-to-texture backdrops top-down on every Impeller backend
  (flutter/flutter#186554); the engine's own runtime-effect fixtures dropped the
  flip in the same change; re-adding it double-flips GLES.
- Keep the existing comment near `displacedCoordinate` (the "do not subtract
  uOrigin when sampling" note) as is; it is still correct.

### 2. Pin the engine guarantee — `pubspec.yaml`

- Raise `environment.flutter` from `">=3.38.0"` to `">=3.47.0"` (first stable
  containing both engine commits; `.fvmrc` already pins 3.47.1).

### 3. Regression guard test — new `test/core/ui/app_liquid_glass_shader_contract_test.dart`

- One `test()` that reads `shaders/app_liquid_glass.frag` as a file and asserts
  it contains no `IMPELLER_TARGET_OPENGLES` guard, with a failure message
  pointing at R1/R3 in this document. `flutter test` runs Skia and never
  executes the shader, so this is the only place the "sampling is
  backend-agnostic" rule can be encoded.
- Leave the existing uniform-contract tests untouched
  (`test/core/ui/app_liquid_glass_shader_uniforms_test.dart`,
  `test/features/bottom_nav_bar/presentation/services/bottom_nav_shader_uniforms_test.dart`).

### 4. Changelogs

- `lib/core/CHANGELOG.md`: new dated section, `### Fixed`, one entry: Android
  OpenGL ES glass surfaces sampled a vertically mirrored backdrop because of a
  stale GLES Y-flip in the shared shader; flip removed, Flutter floor raised
  to 3.47.
- `lib/features/bottom_nav_bar/CHANGELOG.md`: `## [1.4.8] - <date>`,
  `### Fixed`, the same fix phrased for the bar and compact player.

### 5. Update this document

- Fill in the spike result and the devices/backends actually verified, then
  flip the status line at the top to **applied**.

### Files that intentionally do NOT change

- `lib/core/widgets/app_glass_button.dart`
- `lib/core/widgets/app_glass_container.dart`
- `lib/features/bottom_nav_bar/presentation/screens/bottom_nav_bar_screen.dart`
- both `*_shader_backdrop.dart` render objects and both uniform binders

Their `localToGlobal` origin plus `devicePixelRatio` contract is correct on all
backends. Adding a `Platform.isAndroid` branch there would violate R2 and could
not distinguish Vulkan from GLES anyway.

## Verification

1. Spike screenshot (step 0) shows the backdrop under the glass on the GLES
   emulator: AC1.
2. `fvm flutter run` on an iOS simulator or device, same screen: unchanged: AC2.
3. If a physical Android phone is available, run once, confirm logcat says
   `Vulkan`, and check rendering matches before/after: AC3. If none is
   available, state that in the final report instead of claiming it.
4. `fvm dart analyze` and
   `fvm flutter test test/core/ui test/core/widgets test/features/bottom_nav_bar`:
   AC4. Goldens use the Skia fallback material and are unaffected; do **not**
   run `--update-goldens`.
5. On the emulator exercise dock ↔ split morph, scroll the Home tab, and press a
   glass button to confirm the geometry path (`uOrigin`) was never the problem.

## Risks / notes

- Anyone building with Flutter < 3.46 would get the old GLES behaviour
  reversed; the pubspec floor (step 2) turns that into a build-time error
  instead of a silent visual bug.
- The optional emulator-only backend override, if ever needed for diagnosis,
  is the `io.flutter.embedding.android.ImpellerBackend` manifest meta-data
  (`vulkan` / `opengles`). Do not commit it.

## Outcome — 2026-09-04

Applied as specified. All five steps landed; nothing was descoped.

**Confirmed on device.** `sdk_gphone64_arm64`, Android 14, 1344x2992 @ 480dpi,
dev flavour debug build, both Impeller backends exercised on the same emulator:

| Backend | Log line | Result |
|---|---|---|
| OpenGL ES | `android_context_gl_impeller.cc(104)` | Fixed. Bar and player refract the live-stream cards beneath them; the bell refracts the sky. |
| Vulkan | `android_context_vk_impeller.cc(62)` | Unchanged and correct, including mid-scroll, where the bar refracts the reciter photos beneath it. |

Vulkan was forced with a temporary `ImpellerBackend` manifest meta-data, which
was reverted immediately afterwards; the committed manifest carries only
`EnableImpeller`. That run is the empirical half of AC3, and it also stands in
for AC2: Metal and Vulkan both leave `IMPELLER_TARGET_OPENGLES` undefined, so
they compile the identical post-fix `textureUv()`.

**Not re-run: iOS (AC2 empirically).** The removed lines sat inside
`#ifdef IMPELLER_TARGET_OPENGLES`, a macro Metal never defines, so the
preprocessor had already discarded them on iOS before this change. iOS output is
therefore byte-identical by construction, and the Vulkan run above exercises the
same compiled path. Worth one visual pass on an iOS device anyway the next time
one is to hand, purely as belt and braces.

**AC4.** `dart analyze` reports no error, and no issue of any level, in the
changed files. `flutter test test/core/ui test/core/widgets
test/features/bottom_nav_bar` is 122 passing. Goldens were not regenerated: they
render the Skia fallback material, which this change does not touch.

**One note for the next reader.** The regression guard in step 3 initially failed
against its own subject, because the explanatory comment added to the shader in
step 1 names `IMPELLER_TARGET_OPENGLES`. The test now strips `//` lines before
searching, so the prose can keep naming the flip it forbids.
