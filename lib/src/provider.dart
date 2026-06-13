import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:equatable/equatable.dart';

import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store.dart';
part 'arg_provider.dart';
part 'instance_scope.dart';

abstract class ProviderBase<T> {
  T create(Store store);

  void dispose(Store store, T instance);
}

/// A provider whose instance lifetime follows the [Store] itself: it is created
/// lazily on first access and disposed when the Store is unmounted. Unlike a
/// scoped [Provider], it is never tied to a widget scope, so it is the only kind
/// accepted by the scope-free [Store.read].
///
/// Create one via [Provider.shared] or [ViewModelProvider.shared].
abstract class SharedProvider<T> extends ProviderBase<T> {
  /// Wraps a scoped [Provider] so its instance follows the Store lifetime.
  /// Used internally by [Provider.shared] / [ViewModelProvider.shared].
  static SharedProvider<T> of<T>(Provider<T> provider) =>
      _SharedProvider<T>(provider);
}

class _SharedProvider<T> extends SharedProvider<T> {
  final Provider<T> _delegate;

  _SharedProvider(this._delegate);

  @override
  T create(Store store) => _delegate.create(store);

  @override
  void dispose(Store store, T instance) => _delegate.dispose(store, instance);
}

abstract class Provider<T> extends ProviderBase<T> {
  @override
  @nonVirtual
  T create(Store store) {
    var instanceScopeManager = store.read(_instanceScopeManagerProvider);
    var scope = DisposeStateNotifier();
    final instance = createInstance(StoreSpace(store, scope));
    instanceScopeManager.onInstanceCreated(instance, scope);
    return instance;
  }

  @override
  @nonVirtual
  void dispose(Store store, T instance) {
    if (store.mounted) {
      var instanceScopeManager = store.read(_instanceScopeManagerProvider);
      instanceScopeManager.onInstanceDisposed(instance);
    }
    // disposeInstance 必须无条件执行:unmount() 会先把 _mounted 置为 false 再析构实例,
    // 若把它放进 if(store.mounted) 内,Store 卸载时所有实例都不会被析构(资源泄漏)。
    // 只有上面的 instanceScopeManager 簿记需要 mounted 守卫(卸载时整个 manager 会被清空)。
    disposeInstance(instance);
  }

  T createInstance(StoreSpace space);

  void disposeInstance(T instance) {}

  static Provider<T> from<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

  /// Creates a store-lifetime provider: the instance is created lazily on first
  /// [Store.read] and kept alive until the Store is unmounted (it is never tied
  /// to a widget scope).
  ///
  /// Example:
  /// ```dart
  /// final authProvider = Provider.shared((space) => Auth());
  /// final auth = context.read(authProvider); // or store.read(authProvider)
  /// ```
  static SharedProvider<T> shared<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => SharedProvider.of(
    _CallbackProvider(creator: creator, disposer: disposer),
  );

  /// Creates an [ArgProviderFactory] for values that require an argument at creation time.
  ///
  /// Example:
  /// ```dart
  /// final userProvider = Provider.withArgument<User, int>(
  ///   (space, userId) => User(userId)
  /// );
  /// // Usage:
  /// final user = store.shard(userProvider(42));
  ///
  /// For the same arguments, returns an equal provider instance::
  /// userProvider(42)==userProvider(42) // true
  /// userProvider(0)==userProvider(1) // false
  /// ```
  static ArgProviderFactory<T, A> withArgument<T, A>(
    T Function(StoreSpace space, A) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) => ArgProviderFactory(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  static ArgProviderFactory2<T, A, B> withArgument2<T, A, B>(
    T Function(StoreSpace space, A, B) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) => ArgProviderFactory2(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  static ArgProviderFactory3<T, A, B, C> withArgument3<T, A, B, C>(
    T Function(StoreSpace space, A, B, C) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) => ArgProviderFactory3(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  static ArgProviderFactory4<T, A, B, C, D> withArgument4<T, A, B, C, D>(
    T Function(StoreSpace space, A, B, C, D) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) => ArgProviderFactory4(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  static ArgProviderFactory5<T, A, B, C, D, E> withArgument5<T, A, B, C, D, E>(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) => ArgProviderFactory5(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  static ArgProviderFactory6<T, A, B, C, D, E, F>
  withArgument6<T, A, B, C, D, E, F>(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) => ArgProviderFactory6(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );
}

class _CallbackProvider<T> extends Provider<T> {
  final T Function(StoreSpace space) _creator;
  final void Function(T instance)? _disposer;

  _CallbackProvider({
    required T Function(StoreSpace space) creator,
    void Function(T instance)? disposer,
  }) : _creator = creator,
       _disposer = disposer;

  @override
  T createInstance(StoreSpace space) => _creator(space);

  @override
  void disposeInstance(T instance) => _disposer?.call(instance);
}
