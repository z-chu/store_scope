import 'dart:async';

import 'package:flutter/widgets.dart';

/// A [ChangeNotifier] that tracks its disposed state and notifies listeners
/// when disposed.
///
/// This class is especially useful for managing the lifecycle of objects
/// that need to notify others when they are disposed. It is recommended
/// to use [DisposeStateNotifier] as the implementation for the [ScopeAware.scope]
/// property, as it provides a convenient and reliable way to signal when
/// the object's scope becomes invalid.
///
/// **Listener Behavior:**  
/// Listeners added before disposal will be notified when the object is disposed.
/// If a listener is added after the object has already been disposed,
/// it will be scheduled to execute immediately in a microtask.  
/// This ensures that all listeners, regardless of when they are added,
/// will always be notified of the disposal event.
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

  /// Whether this object has been disposed.
  bool get disposed => _disposed;

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      notifyListeners();
    }
    super.dispose();
  }

  /// Adds a listener that will be called when the object is disposed.
  ///
  /// If the object has already been disposed, the listener will be scheduled
  /// to execute immediately in a microtask.
  @override
  void addListener(VoidCallback listener) {
    if (!_disposed) {
      super.addListener(listener);
    } else {
      scheduleMicrotask(listener);
    }
  }
}