# Contributing to store_scope

Thanks for your interest in improving store_scope! Issues and pull requests are
welcome.

## Development setup

```bash
git clone https://github.com/z-chu/store_scope
cd store_scope
flutter pub get
```

The package has no codegen and no runtime dependencies beyond Flutter and
[`equatable`](https://pub.dev/packages/equatable).

## Running tests

```bash
# Unit tests (host VM)
flutter analyze lib test
flutter test

# On-device integration tests (real device or emulator)
cd example
flutter test integration_test -d <device-id>
```

Please keep both suites green, and add a test for any behaviour change —
lifecycle and disposal bugs are exactly the kind this library exists to prevent,
so regressions there should be caught by a test.

## Pull requests

- Keep the public API small and the core reactivity-agnostic. store_scope is a
  DI + lifecycle container; it intentionally does **not** ship a reactivity layer
  or an opinionated async/state type. Features that belong in user code or a
  companion package are usually better left out of core.
- Match the surrounding code style; run `dart format .` before committing.
- Update `CHANGELOG.md`, and bump the version in `pubspec.yaml` following
  [semantic versioning](https://dart.dev/tools/pub/versioning) (pre-1.0:
  breaking changes bump the minor).
- Update the README(s) and dartdoc when you change public API. Documented code
  must compile — don't reference APIs that don't exist.

## Reporting issues

Include the `store_scope` version, Flutter/Dart version (`flutter --version`),
and a minimal reproduction where possible.
