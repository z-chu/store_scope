import 'package:flutter/foundation.dart' show nonVirtual;
import 'package:equatable/equatable.dart';

import 'arg_key.dart';
import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store.dart';
part 'arg_provider.dart';
part 'instance_scope.dart';

/// The lowest-level recipe contract shared by every kind of provider.
///
/// A provider is a *recipe* for producing and disposing an instance inside a
/// [Store]. [ProviderBase] only describes how the [Store] turns a recipe into a
/// live value ([create]) and how it tears that value down ([dispose]); the
/// *lifetime policy* — scoped vs. store-lifetime — is decided by the concrete
/// subtype, not by the call site.
///
/// You rarely use this type directly. Instead reach for the public factories on
/// [Provider] (and [ViewModelProvider]). The two concrete branches are:
///
/// * [Provider] — a SCOPED recipe acquired through a scope (via
///   [StoreSpace.bind] / [Store.bindWith]); reference-counted and disposed when
///   the last binding scope is gone.
/// * [SharedProvider] — a STORE-LIFETIME recipe acquired scope-free (via
///   [Store.share]); a lazy singleton kept until the [Store] unmounts.
///
/// [ProviderBase] is also the type accepted by [StoreSpace.bind] and
/// [Store.bindWith], so both branches can be bound through a scope.
abstract class ProviderBase<T> {
  /// Produces a live instance inside [store].
  ///
  /// Called by the [Store] the first time this recipe needs to be materialized.
  /// Implementations decide how the instance is built and what scope, if any, it
  /// is associated with. Do not call this directly — acquire instances through
  /// [Store.share], [Store.bindWith], or [StoreSpace.bind] so the [Store] can
  /// track lifetime and disposal.
  T create(Store store);

  /// Tears down an [instance] previously produced by [create].
  ///
  /// Invoked by the [Store] when the instance's lifetime ends — when the last
  /// binding scope dies (for a scoped [Provider]) or when the [Store] unmounts
  /// (for a [SharedProvider]). Implementations release any resources the
  /// instance holds. Do not call this directly.
  void dispose(Store store, T instance);
}

/// A provider whose instance lifetime follows the [Store] itself: it is created
/// lazily on first access and disposed when the Store is unmounted. Unlike a
/// scoped [Provider], it is never tied to a widget scope, so it is the only kind
/// accepted by the scope-free [Store.share].
///
/// Acquire its instance with [Store.share] (or `context.share`) — no scope is
/// required, and the resulting value is a lazy singleton kept alive until the
/// owning [StoreScope] unmounts.
///
/// Create one via [Provider.shared] or [ViewModelProvider.shared], or by marking
/// an argument family with `factory.asShared` (see [ArgProviderFactory.asShared]).
///
/// Example:
/// ```dart
/// final authProvider = Provider.shared((space) => Auth());
/// final auth = context.share(authProvider); // lives until the store unmounts
/// ```
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

  // Forward equality to the wrapped delegate so the Store caches by the
  // delegate's value identity. This is what makes a shared argument provider
  // (`factory.asShared`) dedupe: two wrappers around equal `_ArgProvider`s
  // compare equal and resolve to the same store-lifetime instance. For a plain
  // `Provider.shared(...)` the delegate uses identity equality, so the
  // singleton-stored-in-a-final behaviour is unchanged.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _SharedProvider<T> && other._delegate == _delegate);

  @override
  int get hashCode => _delegate.hashCode;
}

/// A SCOPED recipe for an instance: its instances are acquired through a scope
/// and reference-counted across every scope that binds the same provider, then
/// disposed only when the *last* binding scope is gone.
///
/// A provider's lifetime is declared where it is *defined*, not at the call
/// site. Bind one through a [StoreSpace] with [StoreSpace.bind], or directly via
/// [Store.bindWith] when you already hold a scope [Listenable]. When the creator
/// runs it receives a [StoreSpace], so it can compose dependencies by binding
/// child providers with `space.bind(...)`; those children attach to this
/// instance's own scope and are therefore disposed together with it (a cascade —
/// there is no separate graph DSL).
///
/// Build instances with the static factories rather than subclassing:
/// * [Provider.from] — a plain scoped instance.
/// * [Provider.shared] — promote to a store-lifetime [SharedProvider].
/// * [Provider.withArgument] … [Provider.withArgument6] — a FAMILY of instances
///   keyed by the argument value.
///
/// Example:
/// ```dart
/// final counterProvider = Provider.from((space) => Counter());
/// // Acquired through a scope; disposed when the last binding scope dies:
/// final counter = space.bind(counterProvider);
/// ```
abstract class Provider<T> extends ProviderBase<T> {
  /// Materializes the instance for [store] and wires up its scope bookkeeping.
  ///
  /// This is the [Store]-facing entry point and is final ([nonVirtual]): it
  /// allocates a fresh scope for the instance, calls [createInstance] with a
  /// [StoreSpace] baked to that scope, and registers the instance so its
  /// dependency cascade can be torn down deterministically. Override
  /// [createInstance] — not this method — to control how the value is built.
  @override
  @nonVirtual
  T create(Store store) {
    var instanceScopeManager = store.share(_instanceScopeManagerProvider);
    var scope = DisposeStateNotifier();
    final T instance;
    try {
      instance = createInstance(StoreSpace(store, scope));
    } catch (_) {
      // The creator failed part-way, so there is no instance to register and
      // `onInstanceCreated` below never runs — this scope would never reach the
      // manager, and therefore never be disposed. Anything the creator already
      // `space.bind`-ed is hanging off it, so releasing it here is the only
      // thing that can tear that half-built cascade down. Without it the child
      // sits in the store until unmount, and its refcount gains a permanent +1
      // per attempt — an unbounded leak when a failing bind is retried on
      // every rebuild.
      scope.dispose();
      rethrow;
    }
    instanceScopeManager.onInstanceCreated(this, instance, scope);
    return instance;
  }

  /// Tears down [instance] and releases its dependency cascade.
  ///
  /// Final ([nonVirtual]) and invoked by the [Store]: it runs the scope
  /// bookkeeping (so children bound by the creator are disposed too) and then
  /// unconditionally calls [disposeInstance]. Override [disposeInstance] — not
  /// this method — to release the instance's own resources.
  ///
  /// **Scope-driven teardown is inside-out:** when a binding scope dies, the
  /// dependency cascade is released *before* [disposeInstance] runs, so by the
  /// time an instance's own teardown executes, every child its creator
  /// `space.bind`-ed — for which this instance held the last binding — has
  /// already been disposed. Never reach for a bound dependency from
  /// [disposeInstance] (or from `ViewModel.dispose`); attach that work to the
  /// dependency instead.
  ///
  /// [UnmountableStore.unmount] does **not** give that guarantee. It flips `mounted` to
  /// `false` before destroying anything, so the `store.mounted` branch below is
  /// skipped and no cascade runs at all — instances are simply disposed in
  /// creation order. That order happens to be inside-out for a dependency bound
  /// while its owner was being created (the child is created, and therefore
  /// registered, first), but not for one bound later, which is destroyed *after*
  /// its owner. Do not rely on ordering during `unmount()`.
  @override
  @nonVirtual
  void dispose(Store store, T instance) {
    if (store.mounted) {
      var instanceScopeManager = store.share(_instanceScopeManagerProvider);
      instanceScopeManager.onInstanceDisposed(this, instance);
    }
    // disposeInstance must run unconditionally: unmount() sets _mounted to false
    // before destroying instances, so guarding it with if (store.mounted) would
    // leave every instance undisposed on Store teardown (a resource leak). Only
    // the instanceScopeManager bookkeeping above needs the mounted guard, since
    // the whole manager is cleared during unmount.
    disposeInstance(instance);
  }

  /// Builds the instance for this provider, given the [space] it belongs to.
  ///
  /// The [space] is a [StoreSpace] bound to this instance's own scope. Use
  /// `space.bind(childProvider)` here to compose dependencies: children are tied
  /// to this instance's scope and disposed together with it. Override this in a
  /// custom provider; most callers should prefer the [Provider.from] /
  /// [Provider.withArgument] factories instead of subclassing.
  T createInstance(StoreSpace space);

  /// Releases resources held by [instance] when its lifetime ends.
  ///
  /// Called from [dispose] when the last binding scope dies (scoped) or when the
  /// [Store] unmounts (shared). The default is a no-op; override it (or pass a
  /// `disposer` to [Provider.from]) to close streams, controllers, etc.
  ///
  /// **Teardown must not trigger a widget rebuild.** Every path into this method
  /// runs synchronously while Flutter is tearing the element tree down — the
  /// `State.dispose` / `Element.unmount` that releases a scope, and the
  /// [UnmountableStore.unmount] a departing `StoreScope` performs, both run inside
  /// `BuildOwner.finalizeTree`, which holds the tree locked. So calling
  /// `notifyListeners()`, `setState`, or anything else that reaches
  /// `markNeedsBuild` from here trips:
  ///
  /// ```text
  /// setState() or markNeedsBuild() called when widget tree was locked.
  /// ```
  ///
  /// It only actually throws when the widget being marked *survives* the
  /// teardown — a listener still mounted elsewhere on screen. One that unmounts
  /// alongside you is already inactive and absorbs the call silently, which is
  /// what makes this easy to miss in development and easy to ship. Keep teardown
  /// to pure release: cancel subscriptions, close streams and controllers, drop
  /// references. If something outside really has to hear about the disposal,
  /// emit it past the end of the frame with
  /// `WidgetsBinding.instance.addPostFrameCallback` instead of inline. This is
  /// the rule Flutter follows for itself — `ChangeNotifier.dispose()`
  /// deliberately does not notify.
  void disposeInstance(T instance) {}

  /// Creates a plain SCOPED provider from a [creator] callback.
  ///
  /// The instance is built lazily the first time it is bound through a scope
  /// (with [StoreSpace.bind] / [Store.bindWith]), reference-counted across all
  /// scopes that bind it, and disposed — running the optional [disposer] — when
  /// the last binding scope is gone. The `disposer` runs during widget-tree
  /// teardown; see [disposeInstance] for what it must not do.
  ///
  /// Example:
  /// ```dart
  /// final dbProvider = Provider.from(
  ///   (space) => Database(),
  ///   disposer: (db) => db.close(),
  /// );
  /// final db = space.bind(dbProvider);
  /// ```
  static Provider<T> from<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => _CallbackProvider(creator: creator, disposer: disposer);

  /// Creates a store-lifetime provider: the instance is created lazily on first
  /// [Store.share] and kept alive until the Store is unmounted (it is never tied
  /// to a widget scope).
  ///
  /// Returns a [SharedProvider], so it can only be acquired scope-free via
  /// [Store.share] (or `context.share`). The optional [disposer] runs once, when
  /// the owning [StoreScope] unmounts.
  ///
  /// Example:
  /// ```dart
  /// final authProvider = Provider.shared((space) => Auth());
  /// final auth = context.share(authProvider); // or store.share(authProvider)
  /// ```
  static SharedProvider<T> shared<T>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => SharedProvider.of(
    _CallbackProvider(creator: creator, disposer: disposer),
  );

  /// Creates an [ArgProviderFactory] for values that require an argument at creation time.
  ///
  /// The factory builds a FAMILY of providers keyed by the argument's *value*
  /// (deep-compared via `equatable`, so `List`/`Map`/`Set` arguments work as
  /// keys). Calling the factory, e.g. `p(42)`, yields a scoped [Provider] for
  /// that argument; equal arguments yield equal providers and therefore share
  /// one instance. Use [equatableProps] to customize what counts as the key.
  /// To make the family store-lifetime, declare it with
  /// [ArgProviderFactory.asShared] at the definition site.
  ///
  /// For 2–6 arguments use [Provider.withArgument2] … [Provider.withArgument6].
  ///
  /// Example:
  /// ```dart
  /// final userProvider = Provider.withArgument<User, int>(
  ///   (space, userId) => User(userId)
  /// );
  /// // Usage (scoped — acquire it through a scope):
  /// final user = space.bind(userProvider(42));
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

  /// Two-argument variant of [Provider.withArgument]; see
  /// [ArgProviderFactory] for the keying and lifetime semantics.
  static ArgProviderFactory2<T, A, B> withArgument2<T, A, B>(
    T Function(StoreSpace space, A, B) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) => ArgProviderFactory2(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Three-argument variant of [Provider.withArgument]; see
  /// [ArgProviderFactory] for the keying and lifetime semantics.
  static ArgProviderFactory3<T, A, B, C> withArgument3<T, A, B, C>(
    T Function(StoreSpace space, A, B, C) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) => ArgProviderFactory3(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Four-argument variant of [Provider.withArgument]; see
  /// [ArgProviderFactory] for the keying and lifetime semantics.
  static ArgProviderFactory4<T, A, B, C, D> withArgument4<T, A, B, C, D>(
    T Function(StoreSpace space, A, B, C, D) creator, {
    Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) => ArgProviderFactory4(
    creator,
    disposer: disposer,
    equatableProps: equatableProps,
  );

  /// Five-argument variant of [Provider.withArgument]; see
  /// [ArgProviderFactory] for the keying and lifetime semantics.
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

  /// Six-argument variant of [Provider.withArgument]; see
  /// [ArgProviderFactory] for the keying and lifetime semantics.
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
