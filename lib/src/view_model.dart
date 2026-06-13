import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:store_scope/src/provider.dart' show Provider, SharedProvider;

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
    // 先 dispose scope:让 disposed=true,这样在 closeable 内重入调用
    // addCloseable/addKeyedCloseable 时会走"立即关闭"分支,不再 mutate 集合。
    // 再对集合做快照遍历(toList),双保险避免 ConcurrentModificationError。
    _viewModelScope.dispose();
    for (var closeable in _closeables.toList()) {
      _closeWithException(closeable);
    }
    for (var closeable in _keyToCloseables.values.toList()) {
      _closeWithException(closeable);
    }
    _keyToCloseables.clear();
    _closeables.clear();
    // super.dispose() 放最后:closeable 运行期间 ChangeNotifier 仍可用。
    super.dispose();
  }

  @protected
  void addSubscription(StreamSubscription subscription) {
    _closeables.add(() {
      subscription.cancel();
    });
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
      // 立即执行旧的 keyed closeable。注意:closeable 从不作为 listener 注册,
      // 因此无需(也不能)调用 removeListener。
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

  /// Creates a store-lifetime ViewModel provider: the ViewModel is created
  /// lazily on first [Store.read], `init()` is called, and it is disposed when
  /// the Store is unmounted. Read it with `context.read(provider)`.
  static SharedProvider<T> shared<T extends ViewModel>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => SharedProvider.of(ViewModelProvider(creator, disposer: disposer));

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
