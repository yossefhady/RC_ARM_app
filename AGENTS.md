# Agent Instructions

This repository contains three distinct artifacts:
1. **Flutter Mobile App**: Located in `lib/`, `test/`, and configured via `pubspec.yaml`. Targets Android and iOS.
2. **RC_ARM Prototype**: Located in `RC_ARM/`. A standalone browser-based controller UI for a 6-DOF robot arm + drive base.
3. **Arduino/ESP32 Firmware**: Located in `tg_ble_test/`. C++ code (`.ino`) that controls the motors and servos over BluetoothSerial.

## Flutter App Guidelines

- **Entry Point**: `lib/main.dart`
- **Linting**: Enforced via `analysis_options.yaml` (using `flutter_lints`).
- **Tests**: Widget tests are located in `test/widget_test.dart`.

### Common Commands

- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
- Run widget tests: `flutter test`
- Static analysis: `flutter analyze`
- Format code: `dart format .`

## RC_ARM Prototype Guidelines

- Directly open `RC_ARM/CTRL.html` in a web browser to run (no server or build step needed).
- Built using React 18 and Babel loaded via CDN. Components are raw JSX files.
- The `ctrl-app.jsx` file contains the root state. The `DEFAULTS` object inside it (between `/*EDITMODE-BEGIN*/` and `/*EDITMODE-END*/` markers) is editable via the tweaks panel at runtime.

For more details on the project structure and architecture, refer to [CLAUDE.md](CLAUDE.md).

## Arduino/ESP32 Firmware Guidelines

- **Location**: `tg_ble_test/tg_ble_test.ino`
- **Hardware**: Targets an ESP32 using the `BluetoothSerial.h` and `ESP32Servo.h` libraries.
- **Protocol**: Accepts single characters for drive commands (`F`, `B`, `R`, `L`, `S`) and string commands like `<servo_index> <angle>\n` for arm articulation.