import 'package:flutter/foundation.dart';

import 'dispose_state_notifier.dart';
import 'provider.dart';
import 'store_scope_config.dart';
import 'store_space.dart';

part 'store_impl.dart';
part 'override.dart';

/// A dependency-injection container: a map of [ProviderBase]s to the live
/// instances they produce.
///
/// A [Store] is owned by a [StoreScope] widget and lives until that scope
/// unmounts; when it unmounts, every instance the store still holds is
/// disposed. You rarely construct a store yourself — [StoreScope] creates one
/// for its subtree, and you reach it through the `context` extensions
/// (e.g. `context.store`) or through a [StoreSpace] handed to a provider's
/// creator.
///
/// There are two ways an instance enters a store:
///
/// * **scoped / reference-counted** acquisition via [bindWith] (or
///   [StoreSpace.bind]): the instance is tied to a scope and disposed when
///   the last scope that bound it is gone.
/// * **store-lifetime** acquisition via [share]: a lazy singleton that needs no
///   scope and is kept until the store unmounts.
///
/// Example:
/// ```dart
/// // A store-lifetime singleton.
/// final authProvider = Provider.shared((space) => Auth());
///
/// // Anywhere with access to the store:
/// final auth = store.share(authProvider);
///
/// // A scoped instance tied to some Listenable scope:
/// final counterProvider = Provider.from((space) => Counter());
/// final counter = store.bindWith(counterProvider, scope);
/// ```
abstract class Store {
  /// Whether the store is currently mounted and active.
  ///
  /// Returns `true` while the owning [StoreScope] is still in the tree and the
  /// store can serve provider operations. Once the scope unmounts the store,
  /// every held instance is disposed and `mounted` becomes `false`; binding or
  /// sharing against an unmounted store is no longer valid.
  bool get mounted;

  /// Checks if a provider instance has already been created in the store.
  ///
  /// Returns `true` only if the instance currently exists; it does not create
  /// one. Use it to probe without triggering lazy creation.
  ///
  /// Example:
  /// ```dart
  /// final counterProvider = Provider.shared((space) => 0);
  /// store.exists(counterProvider) // returns false
  /// store.share(counterProvider);
  /// store.exists(counterProvider) // returns true
  /// ```
  bool exists<T>(ProviderBase<T> provider);

  /// Finds an existing provider instance in the store without creating one.
  ///
  /// Returns `null` if the provider's instance hasn't been created yet. Unlike
  /// [share] / [bindWith], this never triggers lazy creation, so it is safe to
  /// call for inspection.
  ///
  /// [find] registers no binding, so it grants no lifetime: the instance it
  /// returns lives exactly as long as whoever *does* hold a binding, and nothing
  /// tells you when that ends. That makes it right for a one-shot read — a tap
  /// handler calling a method, a diagnostic, a test — and wrong for anything
  /// that outlives the call. A stored field or an attached listener keeps
  /// pointing at an instance that may already be disposed, and it fails quietly:
  /// the listener simply stops firing (a disposed [ChangeNotifier] has no
  /// listeners left to notify), so the UI freezes on its last value with no
  /// error anywhere.
  ///
  /// To *observe* an instance, bind it instead — `space.bind(provider)` or
  /// [bindWith] with your own scope. Binding is reference-counted, so it costs
  /// nothing when someone else already holds the instance, and it guarantees the
  /// instance outlives the scope doing the observing.
  ///
  /// Example:
  /// ```dart
  /// final counterProvider = Provider.shared((space) => 0);
  /// print(store.find(counterProvider) == null); // true
  /// store.share(counterProvider);
  /// print(store.find(counterProvider) == null); // false
  /// ```
  T? find<T>(ProviderBase<T> provider);

  /// Gets or creates the instance of a store-lifetime [SharedProvider].
  ///
  /// The instance is created lazily on first access and kept alive until the
  /// [Store] is unmounted — it is *not* reference-counted and never disposed
  /// before unmount. No scope is required, which is why this only accepts a
  /// [SharedProvider]; a scoped [Provider] must instead be acquired via
  /// [bindWith] (or [StoreSpace.bind]).
  ///
  /// A [SharedProvider] is produced by [Provider.shared], by
  /// [ViewModelProvider.shared], or by marking an argument family
  /// `factory.asShared` (then calling the factory with a value).
  ///
  /// Example:
  /// ```dart
  /// final authProvider = Provider.shared((space) => Auth());
  /// final auth = store.share(authProvider); // gets or creates the singleton
  ///
  /// // An argument provider marked shared is also accepted, keyed by its arg:
  /// final userProvider =
  ///     Provider.withArgument<User, int>((space, id) => User(id)).asShared;
  /// final user = store.share(userProvider(42));
  /// ```
  T share<T>(SharedProvider<T> provider);

  /// Acquires a scoped provider instance bound to the given [scope].
  ///
  /// This is the low-level, reference-counted acquisition that backs
  /// [StoreSpace.bind]. The instance is shared across every scope that binds
  /// the same provider and is disposed only when the *last* such scope is gone
  /// (i.e. when its [Listenable] notifies disposal). Pass the [scope] of a
  /// widget, a [ScopeAware] object, or a [StoreSpace] so the instance is
  /// cleaned up together with that owner.
  ///
  /// For a store-lifetime singleton that needs no scope, use [share] instead.
  ///
  /// Example:
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> with ScopedStateMixin {
  ///   Counter get counter => context.store.bindWith(counterProvider, scope);
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
/// The exposed [scope] is exactly what [Store.bindWith] /
/// [StoreExtension.bindWithScoped] expect, so a [ScopeAware] can act as the
/// owner of a reference-counted, scoped instance: when its scope notifies
/// disposal, the bound instance is released.
///
/// It is recommended to use [DisposeStateNotifier] to implement this interface,
/// as it provides a convenient way to manage and notify disposal state.
///
/// Example:
/// ```dart
/// class MyController implements ScopeAware {
///   final _notifier = DisposeStateNotifier();
///   @override
///   Listenable get scope => _notifier;
///   void dispose() => _notifier.dispose();
/// }
/// ```
abstract class ScopeAware {
  /// A [Listenable] that notifies listeners when this object's scope becomes invalid,
  /// typically when the object is disposed.
  Listenable get scope;
}

/// Interface for objects that own a [Store] instance and control its lifetime.
///
/// A [StoreScope] resolves a [StoreOwner] (by default a [StoreOwnerImpl]
/// wrapping a freshly created store) to obtain the [store] it exposes to its
/// subtree, and calls [unmountStore] when the scope leaves the tree. Provide a
/// custom implementation to [StoreScope.storeOwner] when you need to control
/// how the store is created or torn down.
abstract class StoreOwner {
  /// The [Store] owned by this object and exposed to the owning scope's subtree.
  Store get store;

  /// Unmounts the owned [store], disposing every instance it still holds.
  ///
  /// Called by [StoreScope] when the scope is removed from the tree. After
  /// this, [Store.mounted] reports `false`.
  void unmountStore();
}

/// A [Store] that can be explicitly unmounted to release all held instances.
///
/// This is the concrete store contract used internally (e.g. by [StoreImpl] and
/// wrapped by [StoreOwnerImpl]). Calling [unmount] disposes every live instance
/// and flips [Store.mounted] to `false`.
abstract class UnmountableStore extends Store {
  /// Unmounts the store, disposing every instance it currently holds.
  void unmount();
}

/// The default [StoreOwner], wrapping an [UnmountableStore] so a [StoreScope]
/// can mount and later unmount it.
///
/// Delegates [store] to the wrapped store and routes [unmountStore] to its
/// [UnmountableStore.unmount].
class StoreOwnerImpl extends StoreOwner {
  final UnmountableStore _store;

  /// Creates an owner for the given [UnmountableStore].
  StoreOwnerImpl(this._store);

  @override
  Store get store => _store;

  @override
  void unmountStore() => _store.unmount();
}

/// Convenience acquisition helpers layered on top of [Store].
extension StoreExtension on Store {
  /// Binds a scoped provider using the scope exposed by a [ScopeAware] owner.
  ///
  /// Shorthand for `bindWith(provider, scopeAware.scope)`: the instance is
  /// reference-counted and released when `scopeAware`'s [ScopeAware.scope]
  /// notifies disposal. See [Store.bindWith] for the semantics.
  T bindWithScoped<T>(ProviderBase<T> provider, ScopeAware scopeAware) {
    return bindWith(provider, scopeAware.scope);
  }

  /// Acquires a scoped instance whose lifetime is tied to *garbage collection*
  /// of the returned value rather than to an explicit scope.
  ///
  /// Use this when you need a one-off instance and have no convenient
  /// [Listenable] scope to bind it to. The instance is bound to an internal,
  /// self-disposing scope that fires once the value becomes unreachable and is
  /// collected, at which point the instance is disposed like any other scoped
  /// binding. Because GC timing is non-deterministic, prefer [bindWith] /
  /// [StoreSpace.bind] (or [share] for singletons) whenever a real scope is
  /// available; reserve [temporary] for short-lived, throwaway instances.
  T temporary<T>(ProviderBase<T> provider) {
    // Debug-only guard: a SharedProvider is store-lifetime and ignores any
    // scope, so the GC-triggered listener would never release it — temporary()
    // would silently behave like share() and keep the instance alive until the
    // store unmounts. Flag that misuse in debug; runtime behavior is unchanged.
    assert(
      provider is! SharedProvider,
      'temporary() requires a scoped Provider. A SharedProvider is '
      'store-lifetime and ignores the GC scope, so the instance would live '
      'until the store unmounts instead of being released on collection. '
      'Use share() for store-lifetime instances.',
    );
    var autoGCListenable = _AutoGCListenable();
    var result = bindWith(provider, autoGCListenable);
    autoGCListenable.start();
    return result;
  }
}

/// A GC-triggered scope listener that disposes its binding once the
/// observed target is collected.
class _AutoGCListenable extends ChangeNotifier {
  // ignore: unused_field
  Finalizer<_AutoGCListenable>? _finalizer;
  // ignore: unused_field
  WeakReference<Object>? _weakTarget;
  bool _disposed = false;

  _AutoGCListenable();

  void start() {
    Finalizer<_AutoGCListenable> finalizer = Finalizer((listenable) {
      if (!listenable._disposed) {
        listenable.notifyListeners();
        listenable.dispose();
      }
    });
    _finalizer = finalizer;
    final target = Object();
    _weakTarget = WeakReference(target);
    finalizer.attach(target, this);
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      super.dispose();
    }
  }
}
