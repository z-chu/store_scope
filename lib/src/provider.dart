import 'package:flutter/foundation.dart' show nonVirtual;

import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store.dart';
import 'store_scope_config.dart';
part 'arg_provider.dart';

abstract class ProviderBase<T> {
  T create(Store store);

  void dispose(T instance);
}

abstract class Provider<T> extends ProviderBase<T> {
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

  void disposeInstance(T instance){}

  static Provider<T> from<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

  /// Creates an [ArgProvider] for values that require an argument at creation time.
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
  static ArgProvider<T, A> withArgument<T, A>(
    T Function(StoreSpace space, A) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider(creator, disposer: disposer);

  static ArgProvider2<T, A, B> withArgument2<T, A, B>(
    T Function(StoreSpace space, A, B) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider2(creator, disposer: disposer);

  static ArgProvider3<T, A, B, C> withArgument3<T, A, B, C>(
    T Function(StoreSpace space, A, B, C) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider3(creator, disposer: disposer);

  static ArgProvider4<T, A, B, C, D> withArgument4<T, A, B, C, D>(
    T Function(StoreSpace space, A, B, C, D) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider4(creator, disposer: disposer);

  static ArgProvider5<T, A, B, C, D, E> withArgument5<T, A, B, C, D, E>(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider5(creator, disposer: disposer);
  

  static ArgProvider6<T, A, B, C, D, E, F> withArgument6<T, A, B, C, D, E, F>(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    Function(T instance)? disposer,
  }) => ArgProvider6(creator, disposer: disposer);

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
