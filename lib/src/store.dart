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

  /// Binds a provider to a disposable widget or object.
  /// The provider instance will be tracked and cleaned up when the disposeNotifier signals disposal.
  /// This method is used to create scoped provider instances that are tied to widget lifecycle.
  ///
  /// Example:
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> with DisposeStateAwareMixin {
  ///   Counter get counter => context.bindWith(counterProvider, this);
  ///   // Counter instance will be cleaned up when widget is disposed
  /// }
  /// ```
  T bindWith<T>(ProviderBase<T> provider, Listenable scope);
}

/// An interface for objects that expose their own lifecycle scope.
///
/// Implement this interface to allow external listeners to observe the lifecycle
/// of the object via the [scope] property. When the scope becomes invalid (for example,
/// when the object is disposed), all listeners will be notified.
///
/// It is recommended to use [DisposeStateNotifier] to implement this interface,
/// as it provides a convenient way to manage and notify disposal state.
abstract class ScopeAware {
  /// A [Listenable] that notifies listeners when this object's scope becomes invalid,
  /// typically when the object is disposed.
  Listenable get scope;
}


/// Interface for objects that own a Store instance.
/// Provides access to the store and ability to unmount it.
abstract class StoreOwner {
  Store get store;
  void unmountStore();
}

/// A store that can be unmounted, typically used for cleanup operations.
abstract class UnmountableStore extends Store {
  void unmount();
}

class StoreOwnerImpl extends StoreOwner {
  final UnmountableStore _store;

  StoreOwnerImpl(this._store);

  @override
  Store get store => _store;

  @override
  void unmountStore() => _store.unmount();
}


extension StoreExtension on Store {
  T bindWithScoped<T>(ProviderBase<T> provider, ScopeAware scopeAware) {
    return bindWith(provider, scopeAware.scope);
  }
}