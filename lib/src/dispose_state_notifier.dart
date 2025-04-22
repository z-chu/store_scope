import 'dart:async';

import 'package:flutter/widgets.dart';

/// A [ChangeNotifier] that tracks its disposed state and notifies listeners
/// when disposed.
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

  void addListenerOrExecute(VoidCallback listener) {
    if (!_disposed) {
      addListener(listener);
    } else {
      scheduleMicrotask(listener);
    }
  }
}

/// An interface for objects that own a [DisposeStateNotifier].
///
/// Implement this interface to provide access to a dispose notifier that can be
/// used to track the lifecycle of the object.
abstract class DisposeStateAware {
  /// A listenable that notifies when this object is disposed.
  Listenable get disposeNotifier;
}
