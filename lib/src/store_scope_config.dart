import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;

/// Global knobs for `store_scope`'s diagnostics.
///
/// All fields are static and may be set once at startup (or in a test's
/// `setUp`). Defaults are tuned for "loud in debug, quiet in release".
///
/// ```dart
/// void main() {
///   StoreScopeConfig.isLogEnable = false;              // silence the trace log
///   StoreScopeConfig.log = (text, {isError = false}) { // or route it yourself
///     myLogger.log(text, isError: isError);
///   };
///   runApp(const StoreScope(child: MyApp()));
/// }
/// ```
class StoreScopeConfig {
  /// Whether the informational trace (instances created / scopes bound /
  /// store unmounted) is emitted through [log]. Defaults to [kDebugMode].
  ///
  /// Errors ignore this flag — they are always passed to [log].
  static bool isLogEnable = kDebugMode;

  /// Whether a cleanup callback that throws surfaces as an exception rather
  /// than a log line. Defaults to [kDebugMode].
  ///
  /// This governs `ViewModel.dispose`: callbacks registered with
  /// `addCloseable` / `addKeyedCloseable` / `addSubscription`. Either way the
  /// teardown **runs to completion first** — every remaining callback, the
  /// notifier's own disposal, and the owning provider's `disposer` still
  /// happen — and the failure is reported only afterwards. Set it to `false` if
  /// a failing cleanup should never break the caller, at the cost of the
  /// failure being a log line.
  ///
  /// Independently of this flag, a failure that escapes a provider's `dispose`
  /// is reported to `FlutterError.onError` by the store, so it is never
  /// silently dropped.
  static bool throwOnCloseError = kDebugMode;

  /// The sink `store_scope`'s own trace and cleanup failures go through.
  /// Replace it to route that output into your own logger; the default writes
  /// to `dart:developer` under the `STORE_SCOPE` name.
  ///
  /// **Your implementation must not throw.** It is called from the middle of
  /// binding and teardown — including from the last-resort branch that runs
  /// when `FlutterError.onError` has already failed — and those call sites are
  /// deliberately not wrapped in `try`/`catch`: a sink that throws would break
  /// `bindWith` outright and could strand a teardown half-finished. Swallow or
  /// buffer failures inside your own logger instead.
  ///
  /// **Not every failure reaches here.** An exception that escapes a provider's
  /// `dispose` is reported to `FlutterError.onError` instead (which is what
  /// Crashlytics & co. already hook, and what makes a widget test fail). It
  /// only falls back to this sink if `FlutterError.onError` itself throws.
  static LogWriterCallback log = defaultLogWriterCallback;
}

/// Signature of the sink used by [StoreScopeConfig.log].
///
/// Implementations must not throw — see [StoreScopeConfig.log].
typedef LogWriterCallback = void Function(String text, {bool isError});

/// The default [StoreScopeConfig.log]: writes to `dart:developer` under the
/// `STORE_SCOPE` name. Errors are always written; informational messages only
/// when [StoreScopeConfig.isLogEnable] is set.
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || StoreScopeConfig.isLogEnable) {
    developer.log(value, name: 'STORE_SCOPE');
  }
}
