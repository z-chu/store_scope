part of 'store.dart';

class StoreImpl implements UnmountableStore {
  final Map<ProviderBase<dynamic>, dynamic> _instances = {};
  final Map<ProviderBase<dynamic>, Set<Listenable>> _scopeWatchers = {};
  final Map<ProviderBase<dynamic>, Map<Listenable, VoidCallback>>
  _listenerCallbacks = {};

  /// Replacement providers keyed by the provider they override (test/DI doubles).
  final Map<ProviderBase<dynamic>, ProviderBase<dynamic>> _overrides;

  StoreImpl({List<Override<dynamic>> overrides = const []})
    : assert(
        overrides.map((o) => o.target).toSet().length == overrides.length,
        'Duplicate override target: each provider can be overridden at most once.',
      ),
      _overrides = {for (final o in overrides) o.target: o.replacement};

  bool _mounted = true;

  @override
  bool get mounted => _mounted;

  @override
  bool exists<T>(ProviderBase<T> provider) {
    if (!_mounted) return false;
    return _instances.containsKey(provider);
  }

  @override
  T? find<T>(ProviderBase<T> provider) {
    if (!_mounted) return null;
    return _instances[provider] as T?;
  }

  @override
  T read<T>(SharedProvider<T> provider) {
    _checkMounted();
    return _getOrCreateInstance(provider);
  }

  /// Watches a provider with the given notifier.
  /// When the notifier is disposed, it will automatically unwatch the provider.
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

  @override
  void unmount() {
    if (!_mounted) return;
    _mounted = false;
    // 先移除所有listeners
    for (final entry in _listenerCallbacks.entries) {
      for (final callbackEntry in entry.value.entries) {
        callbackEntry.key.removeListener(callbackEntry.value);
      }
    }
    // 然后dispose所有instances
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

    // 总是清理watchers和callbacks
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
