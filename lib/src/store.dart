import 'package:flutter/foundation.dart';

import 'dispose_state_notifier.dart';
import 'provider.dart';
import 'store_scope_config.dart';

part 'store_impl.dart';

/// A Store is responsible for managing provider instances and their dependencies.
/// It acts as a central repository for shared state management.
abstract class Store {
  /// Whether the store is currently mounted and active.
  /// Returns true if the store is mounted and can handle provider operations.
  bool get mounted;

  /// Checks if a provider instance has already been created in the store.
  ///
  /// Example:
  /// ```dart
  /// final counterProvider = Provider((store) => 0);
  /// store.exists(counterProvider) // returns false
  /// store.shared(counterProvider) // or store.bind(counterProvider, disposeNotifier);
  /// store.exists(counterProvider) // returns true
  /// ```
  bool exists<T>(ProviderBase<T> provider);

  /// Finds an existing provider instance in the store.
  /// Returns null if the provider instance hasn't been created yet.
  ///
  /// Example:
  /// ```dart
  /// final counterProvider = Provider((store) => 0);
  /// final value = store.find(counterProvider);
  /// print(value == null); // true
  /// store.shared(counterProvider); // or store.bind(counterProvider, disposeNotifier);
  /// print(value == null); // false
  /// ```
  T? find<T>(ProviderBase<T> provider);

  /// Gets or creates a provider instance.
  /// If the instance doesn't exist, it will be created and cached.
  /// This method is typically used for accessing global shared state.
  ///
  /// Example:
  /// ```dart
  /// final counterProvider = Provider((store) => 0);
  /// final counter = store.shared(counterProvider); // Gets or creates counter instance
  /// ```
  T shared<T>(ProviderBase<T> provider);

  /// Binds a provider to a [Listenable] `scope`.
  ///
  /// The provider instance will be created if it doesn't exist, and then tracked.
  /// It will be automatically disposed when the `scope` notifies its listeners
  /// (e.g., when a `ChangeNotifier` calls `notifyListeners` or `dispose`, or a
  /// `DisposeStateNotifier` is disposed).
  ///
  /// This method is typically used to create provider instances whose lifecycles
  /// are tied to another object's lifecycle, such as a widget or a `ViewModel`.
  ///
  /// Example:
  /// ```dart
  /// // Assuming 'myViewModel' has a 'scope' property that is a Listenable (e.g., DisposeStateNotifier)
  /// // And 'userProvider' is a Provider.
  /// final user = store.bindWith(userProvider, myViewModel.scope);
  ///
  /// // 'user' instance will be disposed when myViewModel.scope notifies disposal.
  /// ```
  T bindWith<T>(ProviderBase<T> provider, Listenable scope);
}

/// An interface for objects that expose their own lifecycle scope.
///
/// Implement this interface to allow the object's lifecycle to be observed externally
/// via the [scope] property. When the scope becomes invalid (e.g., the object
/// is disposed), listeners of the [scope] will be notified.
///
/// Using [DisposeStateNotifier] is a common way to implement this interface,
/// providing a straightforward mechanism for managing and signaling disposal.
abstract class ScopeAware {
  /// A [Listenable] that notifies listeners when this object's lifecycle scope
  /// ends, typically signifying that the object has been disposed.
  Listenable get scope;
}

/// Defines an entity that owns and manages a [Store] instance.
///
/// This interface provides access to the [store] and a method to [unmountStore],
/// allowing for the controlled teardown and cleanup of the store and its resources.
abstract class StoreOwner {
  /// The [Store] instance managed by this owner.
  Store get store;

  /// Unmounts the store, performing necessary cleanup operations.
  /// This typically involves disposing of all provider instances within the store.
  void unmountStore();
}

/// An extension of [Store] that includes an explicit [unmount] method.
///
/// This is used for stores that require a formal teardown process,
/// ensuring all resources are released correctly.
abstract class UnmountableStore extends Store {
  /// Unmounts the store, disposing all its provider instances and resources.
  void unmount();
}

/// Default implementation of [StoreOwner].
///
/// Manages an [UnmountableStore] and facilitates its unmounting.
/// This class is not typically used directly by consumers of the library
/// but serves as an internal concrete implementation.
class StoreOwnerImpl extends StoreOwner {
  final UnmountableStore _store;

  /// Creates a [StoreOwnerImpl] with the given [UnmountableStore].
  StoreOwnerImpl(this._store);

  @override
  Store get store => _store;

  @override
  void unmountStore() => _store.unmount();
}

/// Extension methods for [Store] to provide convenient ways to bind providers.
extension StoreExtension on Store {
  /// Binds a [provider] to the lifecycle of a [ScopeAware] object.
  ///
  /// This is a convenience method that calls [Store.bindWith], using the `scope`
  /// provided by the [scopeAware] object. The provider instance will be disposed
  /// when `scopeAware.scope` notifies its listeners.
  ///
  /// - [provider]: The [ProviderBase] to bind.
  /// - [scopeAware]: The [ScopeAware] object whose lifecycle will control the provider instance.
  ///
  /// Returns the instance of type [T] from the provider.
  T bindWithScoped<T>(ProviderBase<T> provider, ScopeAware scopeAware) {
    return bindWith(provider, scopeAware.scope);
  }
}