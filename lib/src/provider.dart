import 'package:flutter/foundation.dart' show nonVirtual;

import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store.dart';
import 'store_scope_config.dart';

abstract class Provider<T> {
  T create(Store store);

  void dispose(T instance);

  static Provider<T> fn<T>(
    T Function(Store store) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

  static BindableProvider<T> bindable<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackBindableProvider(creator: creator, disposer: disposer);
}

abstract class BindableProvider<T> extends Provider<T> {
  late final Map<T, DisposeStateNotifier> _disposeNotifiers =
      Map<T, DisposeStateNotifier>.identity();

  @override
  @nonVirtual
  T create(Store store) {
    var disposeStateNotifier = DisposeStateNotifier();
    final instance = createInstance(StoreSpace(store, disposeStateNotifier));
    _disposeNotifiers[instance] = disposeStateNotifier;
    return instance;
  }

  @override
  @nonVirtual
  void dispose(T instance) {
    StoreScopeConfig.log('$runtimeType dispose method called');
    _disposeNotifiers[instance]?.dispose();
    _disposeNotifiers.remove(instance);
    disposeInstance(instance);
  }

  T createInstance(StoreSpace space);

  void disposeInstance(T instance);

  static BindableProvider<T> fn<T>({
    required T Function(StoreSpace space) creator,
    void Function(T instance)? disposer,
  }) => _CallbackBindableProvider(creator: creator, disposer: disposer);
}

class _CallbackProvider<T> extends Provider<T> {
  final T Function(Store store) _creator;
  final void Function(T instance)? _disposer;

  _CallbackProvider({
    required T Function(Store store) creator,
    void Function(T instance)? disposer,
  }) : _creator = creator,
       _disposer = disposer;

  @override
  T create(Store store) => _creator(store);

  @override
  void dispose(T instance) {
    StoreScopeConfig.log('$runtimeType dispose method called');
    _disposer?.call(instance);
  }
}

class _CallbackBindableProvider<T> extends BindableProvider<T> {
  final T Function(StoreSpace space) _creator;
  final void Function(T instance)? _disposer;

  _CallbackBindableProvider({
    required T Function(StoreSpace space) creator,
    void Function(T instance)? disposer,
  }) : _creator = creator,
       _disposer = disposer;

  @override
  T createInstance(StoreSpace space) => _creator(space);

  @override
  void disposeInstance(T instance) => _disposer?.call(instance);
}
