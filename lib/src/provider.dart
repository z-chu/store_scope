import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:equatable/equatable.dart';

import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store.dart';
part 'arg_provider.dart';
part 'instance_scope.dart';

/// The most basic interface for a provider.
///
/// A [ProviderBase] is responsible for creating and disposing an instance of type [T]
/// within the context of a [Store]. This interface is used by the [Store] to manage
/// the lifecycle of instances.
///
/// Consider extending [Provider] for more convenient instance and scope management.
abstract class ProviderBase<T> {
  /// Creates an instance of type [T] using the provided [store].
  ///
  /// - [store]: The [Store] in which the instance is being created. This can be
  ///   used to access other shared instances if needed for dependency injection.
  /// Returns the created instance of type [T].
  T create(Store store);

  /// Disposes of the given [instance] of type [T] within the context of the [store].
  ///
  /// This method is called when the instance is no longer needed and should
  /// perform any necessary cleanup.
  /// - [store]: The [Store] from which the instance is being disposed.
  /// - [instance]: The instance to dispose.
  void dispose(Store store, T instance);
}

/// An abstract class that simplifies [ProviderBase] implementation by managing
/// instance scope and providing a [StoreSpace].
///
/// [Provider] handles the creation of a [DisposeStateNotifier] for each instance,
/// making it available via [StoreSpace.scope]. This scope is automatically managed
/// and disposed when the provider instance is disposed.
///
/// Subclasses should implement [createInstance] to produce the value and
/// [disposeInstance] for any custom cleanup logic.
abstract class Provider<T> extends ProviderBase<T> {
  /// Creates an instance of type [T] and associates it with a new lifecycle scope.
  ///
  /// This method wraps the [createInstance] call, providing it with a [StoreSpace]
  /// that includes a dedicated [DisposeStateNotifier] for the instance's scope.
  /// This scope is registered with the store's [InstanceScopeManager].
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

  /// Creates an instance of type [T] within the given [StoreSpace].
  ///
  /// Subclasses must override this method to provide the actual instance.
  /// The [space] provides access to the [Store] and the instance's own
  /// lifecycle [Listenable] scope (via `space.scope`).
  ///
  /// - [space]: The [StoreSpace] for this instance.
  /// Returns the created instance.
  T createInstance(StoreSpace space);

  /// Disposes the given [instance].
  ///
  /// Subclasses can override this method to perform custom cleanup logic
  /// when the instance is no longer needed. This is called after the instance's
  /// scope ([StoreSpace.scope]) has been disposed.
  ///
  /// - [instance]: The instance to dispose.
  void disposeInstance(T instance) {}

  /// A factory method to create a simple [Provider<T>] from a creator function.
  ///
  /// - [T]: The type of the value the provider will create.
  /// - [creator]: A function that takes a [StoreSpace] and returns an instance of [T].
  /// - [disposer]: An optional function that takes the instance of [T] and performs cleanup.
  ///
  /// Returns a new [Provider<T>] instance.
  static Provider<T> from<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

  /// Creates an [ArgProviderFactory] for values that require one argument at creation time.
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
  ///
  /// - [T]: The type of the value the provider will create.
  /// - [A]: The type of the argument.
  /// - [creator]: A function that takes a [StoreSpace] and an argument of type [A]
  ///              to create an instance of [T].
  /// - [disposer]: Optional. A function to dispose the instance [T].
  /// - [equatableProps]: Optional. A function that takes an argument of type [A] and
  ///                     returns a list of objects to be used for `Equatable`'s props.
  ///                     This ensures that factory instances created with equivalent arguments
  ///                     are considered equal.
  static ArgProviderFactory<T, A> withArgument<T, A>(
    T Function(StoreSpace space, A arg) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) => ArgProviderFactory(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Creates an [ArgProviderFactory2] for values that require two arguments at creation time.
  /// See [withArgument] for more details on parameters and usage.
  static ArgProviderFactory2<T, A, B> withArgument2<T, A, B>(
    T Function(StoreSpace space, A arg1, B arg2) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) => ArgProviderFactory2(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Creates an [ArgProviderFactory3] for values that require three arguments at creation time.
  /// See [withArgument] for more details on parameters and usage.
  static ArgProviderFactory3<T, A, B, C> withArgument3<T, A, B, C>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) => ArgProviderFactory3(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Creates an [ArgProviderFactory4] for values that require four arguments at creation time.
  /// See [withArgument] for more details on parameters and usage.
  static ArgProviderFactory4<T, A, B, C, D> withArgument4<T, A, B, C, D>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) => ArgProviderFactory4(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Creates an [ArgProviderFactory5] for values that require five arguments at creation time.
  /// See [withArgument] for more details on parameters and usage.
  static ArgProviderFactory5<T, A, B, C, D, E> withArgument5<T, A, B, C, D, E>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)? equatableProps,
  }) => ArgProviderFactory5(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Creates an [ArgProviderFactory6] for values that require six arguments at creation time.
  /// See [withArgument] for more details on parameters and usage.
  static ArgProviderFactory6<T, A, B, C, D, E, F>
  withArgument6<T, A, B, C, D, E, F>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5, F arg6) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)? equatableProps,
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
