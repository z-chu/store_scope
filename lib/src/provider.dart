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

abstract class Provider<T> extends ProviderBase<T> {
  @override
  @nonVirtual
  T create(Store store) {
    var instanceScopeManager = store.shared(_instanceScopeManagerProvider);
    var scope = DisposeStateNotifier();
    final instance = createInstance(StoreSpace(store, scope));
    instanceScopeManager.onInstanceCreated(instance, scope);
    return instance;
  }

  @override
  @nonVirtual
  void dispose(Store store, T instance) {
    var instanceScopeManager = store.shared(_instanceScopeManagerProvider);
    instanceScopeManager.onInstanceDisposed(instance);
    disposeInstance(instance);
  }

  T createInstance(StoreSpace space);

  void disposeInstance(T instance) {}

  static Provider<T> from<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

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
