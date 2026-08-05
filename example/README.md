# store_scope example

A small demo app for [`store_scope`](https://pub.dev/packages/store_scope) plus
an on-device integration test suite that exercises every feature of the library.

## Run the demo

```bash
flutter run
```

The demo shows the two acquisition styles side by side:

- **Shared (store-lifetime)** — `Provider.shared` read with `context.share`; the
  same instance is reused across pages until the `StoreScope` is removed.
- **Scoped** — `Provider` bound with `space.bind`; disposed automatically when
  the page that bound it leaves the tree.

Entry point: [`lib/main.dart`](lib/main.dart).

## Run the on-device integration tests

These build, install, and drive a real widget tree on a connected device,
asserting the behaviour of every feature (shared/scoped/argument providers,
`.asShared`, ViewModel lifecycle, reference-counting, unmount disposal,
`StoreScope(overrides:)`, the scoped mixins, and `AutoStoreWidget`).

```bash
# list devices
flutter devices

# run on a specific device
flutter test integration_test -d <device-id>
```

Test source: [`integration_test/store_scope_test.dart`](integration_test/store_scope_test.dart).
