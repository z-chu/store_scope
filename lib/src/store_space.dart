import 'package:flutter/widgets.dart';
import 'package:store_scope/src/provider.dart';
import 'package:store_scope/src/store.dart';

/// A [Store] paired with a baked-in lifecycle [scope].
///
/// A [StoreSpace] is the object handed to provider and [ViewModel] creators and
/// to scoped widgets. It wraps a [Store] together with a single [scope]
/// [Listenable], so that any provider acquired through [bind] is automatically
/// reference-counted against that scope. When the scope dies (for example when
/// the owning [StoreScope] unmounts), every instance bound through this space is
/// released.
///
/// Because it implements both [Store] and [ScopeAware], a [StoreSpace] can be
/// used anywhere a plain [Store] is expected ([exists], [find], [share],
/// [bindWith]) while also exposing the convenient scope-free [bind] shortcut.
///
/// This is the foundation of dependency composition / cascade: when a provider's
/// creator calls `space.bind(childProvider)`, the child is bound to the parent
/// instance's own scope, so the child is disposed together with the parent —
/// without any explicit dependency-graph DSL.
///
/// Example:
/// ```dart
/// final repositoryProvider = Provider.from((space) => Repository());
///
/// // A provider whose creator composes a child onto its own scope:
/// final userServiceProvider = Provider.from((space) {
///   final repo = space.bind(repositoryProvider); // bound to this instance's scope
///   return UserService(repo);
/// });
/// ```
class StoreSpace implements ScopeAware, Store {
  final Store _store;

  /// The lifecycle [Listenable] baked into this space.
  ///
  /// Instances acquired via [bind] are reference-counted against this scope and
  /// are disposed when it signals — typically when the owning [StoreScope]
  /// unmounts or the parent instance that created this space is disposed.
  @override
  final Listenable scope;

  /// Creates a space that pairs the given [Store] with a [scope].
  ///
  /// You rarely construct this yourself; instances are provided by the framework
  /// to provider/[ViewModel] creators and to scoped widgets.
  const StoreSpace(this._store, this.scope);

  /// Binds a provider within the current space scope.
  ///
  /// This is the recommended way to acquire a scoped provider inside a space.
  /// The instance is reference-counted against the space's own [scope] and is
  /// disposed when that scope dies — so children bound this way are cleaned up
  /// together with the instance that created the space.
  ///
  /// This is the scope-bound counterpart to [share]: use [bind] for scoped,
  /// reference-counted acquisition and [share] for store-lifetime singletons.
  ///
  /// Teardown runs **inside-out**: when this space's scope dies, everything
  /// bound through it is disposed *before* the owner's own teardown (its
  /// `disposer`, or `ViewModel.dispose`). So an owner must never use a bound
  /// dependency while shutting down — by then the dependency is already gone.
  /// ([Store.unmount] is the exception: it disposes everything in creation
  /// order without running cascades — see [Provider.dispose].)
  ///
  /// Example:
  /// ```dart
  /// final myState = space.bind(myProvider);
  /// ```
  T bind<T>(ProviderBase<T> provider) {
    return _store.bindWith(provider, scope);
  }

  /// Binds [provider] against an explicit [scope] rather than this space's
  /// baked-in [scope].
  ///
  /// Delegates to the underlying [Store.bindWith]. Prefer [bind] unless you need
  /// to tie the instance's lifetime to a different scope than this space's.
  @override
  T bindWith<T>(ProviderBase<T> provider, Listenable scope) {
    return _store.bindWith(provider, scope);
  }

  /// Whether an instance for [provider] has already been created in the
  /// underlying [Store]. Delegates to [Store.exists].
  @override
  bool exists<T>(ProviderBase<T> provider) {
    return _store.exists(provider);
  }

  /// Returns the existing instance for [provider], or `null` if it has not been
  /// created yet. Delegates to [Store.find] and never creates an instance.
  @override
  T? find<T>(ProviderBase<T> provider) {
    return _store.find(provider);
  }

  /// Whether the underlying [Store] is still mounted and able to serve provider
  /// operations. Delegates to [Store.mounted].
  @override
  bool get mounted => _store.mounted;

  /// Gets or lazily creates the store-lifetime instance of [provider].
  ///
  /// Delegates to [Store.share]: the instance requires no scope and is kept
  /// until the store unmounts. Use this for singletons; use [bind] for scoped,
  /// reference-counted acquisition.
  @override
  T share<T>(SharedProvider<T> provider) {
    return _store.share(provider);
  }
}
