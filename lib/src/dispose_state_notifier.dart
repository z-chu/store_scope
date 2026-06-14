import 'dart:async';

import 'package:flutter/widgets.dart';

/// A [ChangeNotifier] that tracks its disposed state and notifies listeners
/// exactly once when it is disposed.
///
/// [DisposeStateNotifier] turns a disposal event into a [Listenable] signal:
/// it fires its listeners the moment [dispose] is called and then remembers
/// that it is dead via [disposed]. Because it is a [Listenable], it is the
/// canonical building block for a *scope* in this package — a thing whose
/// disposal releases the instances bound through it.
///
/// This makes it the recommended backing for the [ScopeAware.scope] property:
/// expose a [DisposeStateNotifier] as your `scope`, and call its [dispose]
/// from your own teardown. Whoever bound instances against that scope (e.g.
/// through `space.bind`) will then have those instances released
/// deterministically when your object dies.
///
/// **Listener behavior:**
/// Listeners added before disposal are notified once, synchronously, when
/// [dispose] is called. If a listener is added *after* the notifier has
/// already been disposed, it is instead scheduled to run immediately in a
/// microtask (see [addListener]). This guarantees that every listener —
/// regardless of registration timing — is always notified of the disposal
/// event, so callers never miss a "scope is now invalid" signal because of a
/// race.
///
/// Once disposed, the notifier stays disposed; [dispose] is idempotent and
/// will not fire listeners a second time.
///
/// Example usage:
/// ```dart
/// class MyController with ScopeAware {
///   final DisposeStateNotifier _notifier = DisposeStateNotifier();
///   @override
///   Listenable get scope => _notifier;
///
///   void dispose() {
///     _notifier.dispose();
///   }
/// }
/// ```
class DisposeStateNotifier extends ChangeNotifier {
  bool _disposed = false;

  /// Whether this object has already been disposed.
  ///
  /// Becomes `true` permanently after the first call to [dispose]. Use it to
  /// guard against acting on a scope whose disposal signal has already fired.
  bool get disposed => _disposed;

  /// Marks this notifier as disposed and notifies its listeners.
  ///
  /// On the first call this flips [disposed] to `true` and calls
  /// `notifyListeners()` once, signalling every listener that the scope is now
  /// invalid. Subsequent calls are no-ops with respect to listeners — the
  /// notification fires exactly once over the lifetime of the object.
  ///
  /// Always delegates to `super.dispose()` to release the underlying
  /// [ChangeNotifier] resources.
  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      notifyListeners();
    }
    super.dispose();
  }

  /// Registers a listener to be called when this notifier is disposed.
  ///
  /// If the notifier has not yet been disposed, the listener is added normally
  /// and will be invoked when [dispose] is later called. If the notifier has
  /// *already* been disposed, the listener is instead scheduled to run
  /// immediately via [scheduleMicrotask], so it still observes the disposal
  /// event rather than being silently dropped.
  @override
  void addListener(VoidCallback listener) {
    if (!_disposed) {
      super.addListener(listener);
    } else {
      scheduleMicrotask(listener);
    }
  }
}
