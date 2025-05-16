import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:store_scope/src/provider.dart' show Provider;

import 'dispose_state_notifier.dart';
import 'store.dart';
import 'store_scope_config.dart';
import 'store_space.dart';

part 'arg_view_model_provider.dart';

abstract class ViewModel extends ChangeNotifier implements ScopeAware {
  final _viewModelScope = DisposeStateNotifier();
  final Map<String, VoidCallback> _keyToCloseables = {};
  final Set<VoidCallback> _closeables = {};

  @override
  Listenable get scope => _viewModelScope;

  bool get disposed => _viewModelScope.disposed;

  void init() {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    for (var closeable in _closeables) {
      _closeWithException(closeable);
    }
    var keyedCloseables = _keyToCloseables.values;
    for (var closeable in keyedCloseables) {
      _closeWithException(closeable);
    }
    _keyToCloseables.clear();
    _closeables.clear();
    _viewModelScope.dispose();
  }

  /// Adds a closeable resource to be disposed when the ViewModel is disposed.
  ///
  /// The [closeable] callback will be executed when:
  /// - The ViewModel is disposed
  /// - The ViewModel is already disposed (immediately)
  ///
  /// If the same [closeable] is added multiple times, it will only be executed once.
  ///
  /// Example:
  /// ```dart
  /// addCloseable(() {
  ///   // Clean up resources
  ///   subscription.cancel();
  /// });
  /// ```
  @protected
  void addCloseable(VoidCallback closeable) {
    if (disposed) {
      _closeWithException(closeable);
      return;
    }
    if (_closeables.contains(closeable)) {
      return;
    }
    _closeables.add(closeable);
  }

  /// Adds a keyed closeable resource to be disposed when the ViewModel is disposed.
  ///
  /// The [closeable] callback will be executed when:
  /// - The ViewModel is disposed
  /// - The ViewModel is already disposed (immediately)
  /// - A new closeable is added with the same [key]
  ///
  /// If a closeable with the same [key] already exists:
  /// - The old closeable will be executed immediately
  /// - The new closeable will replace the old one
  ///
  /// Example:
  /// ```dart
  /// addKeyedCloseable('subscription', () {
  ///   // Clean up resources
  ///   subscription.cancel();
  /// });
  /// ```
  @protected
  void addKeyedCloseable(String key, VoidCallback closeable) {
    if (disposed) {
      _closeWithException(closeable);
      return;
    }
    var oldCloseable = _keyToCloseables[key];
    if (oldCloseable != null) {
      if (oldCloseable == closeable) return;
      _viewModelScope.removeListener(oldCloseable);
      oldCloseable.call();
    }
    _keyToCloseables[key] = closeable;
  }

  void _closeWithException(VoidCallback closeable) {
    try {
      closeable();
    } catch (error, stackTrace) {
      if (StoreScopeConfig.throwOnCloseError) {
        throw Exception(
          'Failed to close $error\n'
          'Stack trace:\n$stackTrace',
        );
      } else {
        StoreScopeConfig.log(
          'Failed to close $error\n'
          'Stack trace:\n$stackTrace',
          isError: true,
        );
      }
    }
  }
}

abstract class ViewModelProviderBase<T extends ViewModel> extends Provider<T> {
  @override
  @nonVirtual
  T createInstance(StoreSpace space) {
    final vm = createViewModel(space);
    vm.init();
    return vm;
  }

  @override
  @nonVirtual
  void disposeInstance(T instance) {
    instance.dispose();
    disposeViewModel(instance);
  }

  T createViewModel(StoreSpace space);

  void disposeViewModel(T instance) {}
}

class ViewModelProvider<T extends ViewModel> extends ViewModelProviderBase<T> {
  final T Function(StoreSpace space) creator;
  final void Function(T instance)? disposer;

  ViewModelProvider(this.creator, {this.disposer});

  @override
  T createViewModel(StoreSpace space) {
    return creator(space);
  }

  @override
  void disposeViewModel(T instance) {
    disposer?.call(instance);
  }

  static ArgVmProviderFactory<T, A> withArgument<T extends ViewModel, A>(
    T Function(StoreSpace space, A arg) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) {
    return ArgVmProviderFactory(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  static ArgVmProviderFactory2<T, A, B>
  withArgument2<T extends ViewModel, A, B>(
    T Function(StoreSpace space, A arg1, B arg2) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) {
    return ArgVmProviderFactory2(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  static ArgVmProviderFactory3<T, A, B, C>
  withArgument3<T extends ViewModel, A, B, C>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) {
    return ArgVmProviderFactory3(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  static ArgVmProviderFactory4<T, A, B, C, D>
  withArgument4<T extends ViewModel, A, B, C, D>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) {
    return ArgVmProviderFactory4(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  static ArgVmProviderFactory5<T, A, B, C, D, E>
  withArgument5<T extends ViewModel, A, B, C, D, E>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5)
    creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) {
    return ArgVmProviderFactory5(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  static ArgVmProviderFactory6<T, A, B, C, D, E, F>
  withArgument6<T extends ViewModel, A, B, C, D, E, F>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)
    creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) {
    return ArgVmProviderFactory6(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }
}
