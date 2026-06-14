part of 'store.dart';

/// The concrete, default implementation of [UnmountableStore] (and therefore
/// [Store]) used throughout `store_scope`.
///
/// A [StoreImpl] is a dependency-injection container: a map from providers to
/// the single live instance each currently resolves to. It is normally created
/// and owned by a [StoreScope] widget and lives until that scope unmounts — you
/// rarely construct it directly except in tests or non-widget hosts.
///
/// Responsibilities:
/// - Lazily create instances on first [share] / [bindWith] and cache them so a
///   provider always resolves to the same instance within this store.
/// - Track which scopes (Listenables) have bound each scoped provider and
///   reference-count them, disposing an instance only when the *last* binding
///   scope is gone.
/// - Keep store-lifetime [SharedProvider] instances alive — scope-free — until
///   [unmount] is called.
/// - Apply any [Override]s passed to the constructor so resolution returns the
///   replacement instead of the real provider.
///
/// Lifetime / disposal: every instance the store holds is disposed when
/// [unmount] runs (or, for scoped providers, earlier when their last scope is
/// released). After unmounting, the store is dead — [mounted] is `false` and
/// [share] / [bindWith] throw.
///
/// ```dart
/// // Stand up a store outside the widget tree (e.g. for a unit test).
/// final store = StoreImpl(overrides: [
///   repositoryProvider.overrideWithValue(FakeRepository()),
/// ]);
///
/// final auth = store.share(authProvider); // store-lifetime singleton
///
/// store.unmount(); // disposes every instance the store holds
/// ```
class StoreImpl implements UnmountableStore {
  final Map<ProviderBase<dynamic>, dynamic> _instances = {};
  final Map<ProviderBase<dynamic>, Set<Listenable>> _scopeWatchers = {};
  final Map<ProviderBase<dynamic>, Map<Listenable, VoidCallback>>
  _listenerCallbacks = {};

  /// Replacement providers keyed by the provider they override (test/DI doubles).
  final Map<ProviderBase<dynamic>, ProviderBase<dynamic>> _overrides;

  /// Creates a store, optionally pre-installing [overrides].
  ///
  /// Each [Override] redirects resolution of its target provider to a
  /// replacement — typically a fake or mock. Build overrides with
  /// [ProviderOverride.overrideWithValue] (injects a ready instance the store
  /// never disposes) or [ProviderOverride.overrideWith] (replaces creation with
  /// a plain instance). The same provider may be overridden at most once;
  /// passing duplicate targets throws in debug via the assertion.
  ///
  /// ```dart
  /// final store = StoreImpl(overrides: [
  ///   userVmProvider.overrideWith((space) => FakeUserVm()),
  /// ]);
  /// ```
  StoreImpl({List<Override<dynamic>> overrides = const []})
    : assert(
        overrides.map((o) => o.target).toSet().length == overrides.length,
        'Duplicate override target: each provider can be overridden at most once.',
      ),
      _overrides = {for (final o in overrides) o.target: o.replacement};

  bool _mounted = true;

  /// Whether this store is still active.
  ///
  /// `true` from construction until [unmount] is called; afterwards `false`,
  /// at which point the store holds no instances and [share] / [bindWith]
  /// throw a [StateError].
  @override
  bool get mounted => _mounted;

  /// Whether an instance for [provider] currently exists in this store.
  ///
  /// Returns `false` for a provider that has never been resolved (or whose
  /// instance was already disposed), and `false` once the store is unmounted.
  /// This is a pure query — it never triggers creation.
  @override
  bool exists<T>(ProviderBase<T> provider) {
    if (!_mounted) return false;
    return _instances.containsKey(provider);
  }

  /// Returns the existing instance of [provider], or `null` if none has been
  /// created yet (or the store is unmounted).
  ///
  /// Like [exists], this never creates an instance; use [share] or [bindWith]
  /// when you want the store to build one on demand.
  @override
  T? find<T>(ProviderBase<T> provider) {
    if (!_mounted) return null;
    return _instances[provider] as T?;
  }

  /// Resolves a store-lifetime [SharedProvider], creating its instance lazily
  /// on first access and caching it for the life of the store.
  ///
  /// No scope is required: the instance is *not* reference-counted and is kept
  /// until [unmount]. This is the store-lifetime counterpart to [bindWith]
  /// (which is scoped). Throws a [StateError] if the store is unmounted.
  ///
  /// ```dart
  /// final auth = store.share(authProvider); // same singleton every time
  /// ```
  @override
  T share<T>(SharedProvider<T> provider) {
    _checkMounted();
    return _getOrCreateInstance(provider);
  }

  /// Acquires [provider] scoped to [scope], creating its instance lazily and
  /// tracking [scope] as one of the bindings that keep it alive.
  ///
  /// Binding is reference-counted across every scope that binds the same
  /// provider: when [scope] is disposed (it notifies its listeners) the store
  /// releases this binding, and the instance is disposed only once the *last*
  /// binding scope is gone. This is the scoped, reference-counted counterpart
  /// to [share]. Prefer [StoreSpace.bind], which feeds the space's own scope to
  /// this method automatically.
  ///
  /// A [SharedProvider] follows the store lifetime and is never tied to a
  /// scope; for it [bindWith] behaves like [share] and the passed [scope] is
  /// ignored. Throws a [StateError] if the store is unmounted.
  ///
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> with ScopedStateMixin {
  ///   Counter get counter => context.store.bindWith(counterProvider, scope);
  ///   // Counter is disposed when this widget's scope dies (if no other
  ///   // scope still binds counterProvider).
  /// }
  /// ```
  @override
  T bindWith<T>(ProviderBase<T> provider, Listenable scope) {
    _checkMounted();
    // A SharedProvider follows the Store lifetime and is never tied to a scope;
    // for it, bindWith behaves like read (the passed scope is ignored).
    if (provider is! SharedProvider) {
      _bindProviderToScope(provider, scope);
    }
    return _getOrCreateInstance(provider);
  }

  /// Tears the store down: disposes every instance it still holds and marks it
  /// as no longer [mounted].
  ///
  /// Called when the owning [StoreScope] unmounts. All bound scope listeners
  /// are detached first, then each cached instance is disposed through its
  /// provider's `dispose` (overridden providers via their override). Idempotent
  /// — calling it again on an already-unmounted store is a no-op. After this
  /// runs the store is dead and further [share] / [bindWith] calls throw.
  @override
  void unmount() {
    if (!_mounted) return;
    _mounted = false;
    // First remove all listeners.
    for (final entry in _listenerCallbacks.entries) {
      for (final callbackEntry in entry.value.entries) {
        callbackEntry.key.removeListener(callbackEntry.value);
      }
    }
    // Then dispose all instances.
    for (final entry in _instances.entries) {
      _disposeProviderInstance(entry.key, entry.value);
    }
    _log('''
Store unmounted:
- Instances cleared: ${_instances.length}
- Watchers cleared: ${_scopeWatchers.length}
''');
    _instances.clear();
    _scopeWatchers.clear();
    _listenerCallbacks.clear();
  }

  // === Private Instance Management ===

  T _getOrCreateInstance<T>(ProviderBase<T> provider) {
    var instance = _instances[provider];
    if (instance == null) {
      instance = (_overrides[provider] ?? provider).create(this);
      _instances[provider] = instance;
      _log('"${instance.runtimeType}" instance created');
    }
    return instance as T;
  }

  void _invalidateProvider<T>(ProviderBase<T> provider) {
    final instance = _instances[provider];

    // Always clean up watchers and callbacks.
    _scopeWatchers.remove(provider);
    final callbacks = _listenerCallbacks.remove(provider);
    if (callbacks != null) {
      for (final entry in callbacks.entries) {
        entry.key.removeListener(entry.value);
      }
    }

    _disposeProviderInstance(provider, instance);
    _instances.remove(provider);
    _log('"${instance.runtimeType}" instance disposed');
  }

  // === Private Scope Management ===

  void _bindProviderToScope<T>(ProviderBase<T> provider, Listenable scope) {
    // Debug-only guard: binding against an already-disposed DisposeStateNotifier
    // is always a mistake. Such a scope schedules its unbind in a microtask (see
    // DisposeStateNotifier.addListener), so the freshly-created instance returned
    // here would be disposed one microtask later, handing the caller a value
    // that is about to become invalid. We only flag the canonical scope type
    // that exposes its disposed state; runtime behavior is unchanged.
    assert(
      scope is! DisposeStateNotifier || !scope.disposed,
      'bindWith was called with an already-disposed scope. The instance would '
      'be created and then disposed one microtask later. Bind against a live '
      'scope (e.g. a ScopeAware whose scope has not yet been disposed).',
    );
    final watchers = _scopeWatchers.putIfAbsent(provider, () => <Listenable>{});

    if (watchers.add(scope)) {
      // ignore: prefer_function_declarations_over_variables
      final unbindCallback = () => _unbindProviderFromScope(provider, scope);
      scope.addListener(unbindCallback);

      _listenerCallbacks.putIfAbsent(
        provider,
        () => <Listenable, VoidCallback>{},
      );
      _listenerCallbacks[provider]![scope] = unbindCallback;

      _log('"${provider.runtimeType}" bindWith new scope');
    }
  }

  /// Unwatches a provider for the given notifier.
  /// If there are no more watchers, the provider will be reset.
  void _unbindProviderFromScope<T>(ProviderBase<T> provider, Listenable scope) {
    final watchers = _scopeWatchers[provider];
    if (watchers == null || watchers.isEmpty) return;
    if (watchers.remove(scope)) {
      _log('"${provider.runtimeType}" unbind a scope');
      final callback = _listenerCallbacks[provider]?.remove(scope);
      if (callback != null) {
        scope.removeListener(callback);
      }

      if (watchers.isEmpty) {
        _scopeWatchers.remove(provider);
        _listenerCallbacks.remove(provider);
        _log('"${provider.runtimeType}" all scopes unbound');
        _invalidateProvider(provider);
      }
    }
  }

  void _disposeProviderInstance<T>(ProviderBase<T> provider, T instance) {
    try {
      (_overrides[provider] ?? provider).dispose(this, instance);
    } catch (e) {
      _log('Error disposing ${instance.runtimeType}: $e', isError: true);
    }
  }

  // === Private Validation ===

  void _checkMounted() {
    if (!_mounted) {
      throw StateError('Cannot use a disposed Store');
    }
  }

  void _log(String text, {bool isError = false}) {
    StoreScopeConfig.log(text, isError: isError);
  }
}
