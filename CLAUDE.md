# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repo contains two distinct artifacts:

1. **Flutter mobile app** (`lib/`, `test/`, `pubspec.yaml`) — the main cross-platform app targeting Android and iOS. Currently at scaffold stage.
2. **RC_ARM prototype** (`RC_ARM/`) — a standalone browser-based RC controller UI for a 6-DOF robot arm + drive base connected over BLE to an ESP32. No build step; React 18 + Babel standalone are loaded from CDN, JSX files are referenced directly by `CTRL.html`.

## Flutter Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter build apk        # Build Android APK
flutter build ios        # Build iOS (macOS only)
flutter analyze          # Static analysis (uses flutter_lints)
dart format .            # Format all Dart files
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
```

## RC_ARM Prototype

Open `RC_ARM/CTRL.html` directly in a browser (no server needed — all scripts are local JSX files loaded via Babel standalone or CDN).

Component layout:
- `ctrl-app.jsx` — root `App` component; owns all state (tab, connection, speed, servos, logs)
- `ctrl-drive.jsx` — directional pad + speed slider + drive mode selector
- `ctrl-arm.jsx` — 6 servo sliders (BASE ROT → GRIPPER) + preset buttons
- `ctrl-terminal.jsx` — scrolling BLE command/response log
- `ctrl-header.jsx` — connection status bar and tab switcher
- `ctrl-icons.jsx` — shared SVG icon components
- `ios-frame.jsx` — decorative iOS device frame wrapper
- `tweaks-panel.jsx` — live-edit panel for `DEFAULTS` (accent color, HUD density, toggles)

The `DEFAULTS` object in `ctrl-app.jsx` (between `/*EDITMODE-BEGIN*/` and `/*EDITMODE-END*/` markers) is editable via the tweaks panel at runtime.

## Flutter Architecture

- `lib/main.dart` — single entry point; `MyApp` (root `MaterialApp`) → `MyHomePage` (stateful counter scaffold)
- `test/widget_test.dart` — widget tests using `flutter_test`
- Linting: `package:flutter_lints/flutter.yaml` via `analysis_options.yaml`
- Min SDK: Dart ^3.9.0
