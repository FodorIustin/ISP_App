# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Static analysis (dart analyzer + flutter_lints)
flutter build apk        # Android
flutter build ios        # iOS
flutter build web        # Web
```

## Architecture

This is a standard Flutter app targeting all 6 platforms (Android, iOS, Web, macOS, Linux, Windows).

- **Entry point:** `lib/main.dart` — currently a single-file default template
- **State management:** Plain `setState` (no BLoC/Provider/Riverpod)
- **Theme:** Material 3 with `ColorScheme.fromSeed`
- **Linting:** `flutter_lints` defaults via `analysis_options.yaml`

The app has a single `StatefulWidget` (`MyHomePage`) with a counter. As features are added, split into subdirectories under `lib/` (e.g., `screens/`, `widgets/`, `services/`).

## Dependencies

Direct runtime dependencies (beyond Flutter SDK):
- `cupertino_icons: ^1.0.8`

Dev: `flutter_lints: ^6.0.0`
