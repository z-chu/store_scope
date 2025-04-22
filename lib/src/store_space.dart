import 'package:flutter/widgets.dart';
import 'package:store_scope/src/dispose_state_notifier.dart';
import 'package:store_scope/src/provider.dart';
import 'package:store_scope/src/store.dart';

class StoreSpace implements DisposeStateAware, Store {
  final Store _store;

  @override
  final Listenable disposeNotifier;

  const StoreSpace(this._store, this.disposeNotifier);

  /// Binds a provider within the current space scope.
  ///
  /// This is the recommended way to bind a provider in a Space.
  /// It automatically uses the Space's own [disposeNotifier] to handle cleanup.
  ///
  /// Example:
  /// ```dart
  /// final myState = space.bindWith(myProvider);
  /// ```
  T bindWith<T>(Provider<T> provider) {
    return _store.bind(provider, disposeNotifier);
  }

  /// @nodoc
  /// This is an internal implementation method.
  ///
  /// Please use [bindWith] instead, which automatically handles the dispose notification
  /// for the current space scope.
  @override
  @protected
  T bind<T>(Provider<T> provider, Listenable disposeNotifier) {
    return _store.bind(provider, disposeNotifier);
  }

  @override
  bool exists<T>(Provider<T> provider) {
    return _store.exists(provider);
  }

  @override
  T? find<T>(Provider<T> provider) {
    return _store.find(provider);
  }

  @override
  bool get mounted => _store.mounted;

  @override
  T shared<T>(Provider<T> provider) {
    return _store.shared(provider);
  }
}
