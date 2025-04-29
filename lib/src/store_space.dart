import 'package:flutter/widgets.dart';
import 'package:store_scope/src/provider.dart';
import 'package:store_scope/src/store.dart';

class StoreSpace implements ScopeAware, Store {
  final Store _store;

  @override
  final Listenable scope;

  const StoreSpace(this._store, this.scope);

  /// Binds a provider within the current space scope.
  ///
  /// This is the recommended way to bind a provider in a Space.
  /// It automatically uses the Space's own [scope] to handle cleanup.
  ///
  /// Example:
  /// ```dart
  /// final myState = space.bind(myProvider);
  /// ```
  T bind<T>(ProviderBase<T> provider) {
    return _store.bindWith(provider, scope);
  }

  @override
  T bindWith<T>(ProviderBase<T> provider, Listenable scope) {
    return _store.bindWith(provider, scope);
  }

  @override
  bool exists<T>(ProviderBase<T> provider) {
    return _store.exists(provider);
  }

  @override
  T? find<T>(ProviderBase<T> provider) {
    return _store.find(provider);
  }

  @override
  bool get mounted => _store.mounted;

  @override
  T shared<T>(ProviderBase<T> provider) {
    return _store.shared(provider);
  }
}
