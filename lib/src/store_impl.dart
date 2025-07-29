part of 'store.dart';

class StoreImpl implements UnmountableStore {
  final Map<ProviderBase<dynamic>, dynamic> _instances = {};
  final Map<ProviderBase<dynamic>, Set<Listenable>> _scopeWatchers = {};
  final Map<ProviderBase<dynamic>, Map<Listenable, VoidCallback>>
  _listenerCallbacks = {};

  final Set<ProviderBase<dynamic>> _sharedProviders = <ProviderBase>{};

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
  T shared<T>(ProviderBase<T> provider) {
    _checkMounted();
    _warnIfBound(provider);
    return _getOrCreateInstance(provider, true);
  }

  /// Watches a provider with the given notifier.
  /// When the notifier is disposed, it will automatically unwatch the provider.
  @override
  T bindWith<T>(ProviderBase<T> provider, Listenable scope) {
    _checkMounted();
    _warnIfShared(provider);
    _bindProviderToScope(provider, scope);
    return _getOrCreateInstance(provider, false);
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
- Shared instances cleared: ${_sharedProviders.length}
''');
    _instances.clear();
    _scopeWatchers.clear();
    _sharedProviders.clear();
    _listenerCallbacks.clear();
  }

  // === Private Instance Management ===

  T _getOrCreateInstance<T>(ProviderBase<T> provider, bool shared) {
    var instance = _instances[provider];
    if (instance == null) {
      instance = provider.create(this);
      _instances[provider] = instance;
      if (shared) {
        _sharedProviders.add(provider);
        _log('"${instance.runtimeType}" shared instance created');
      } else {
        _log('"${instance.runtimeType}" bound instance created');
      }
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

    // 只有非shared provider才dispose instance
    if (!_sharedProviders.contains(provider)) {
      _disposeProviderInstance(provider, instance);
      _instances.remove(provider);
      _log('"${instance.runtimeType}" instance disposed');
    } else {
      _log('"${instance.runtimeType}" watchers cleared (shared instance kept)');
    }
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
      provider.dispose(this, instance);
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

  void _warnIfShared<T>(ProviderBase<T> provider) {
    if (_sharedProviders.contains(provider)) {
      assert(() {
        _log('''
Warning: Provider "${provider.runtimeType}" is already registered as a shared instance.
The lifecycle binding will have no effect on instance disposal.
''', isError: true);
        return true;
      }());
    }
  }

  void _warnIfBound<T>(ProviderBase<T> provider) {
    if (_scopeWatchers.containsKey(provider)) {
      assert(() {
        _log('''
Warning: Provider "${provider.runtimeType}" is already bound with lifecycle.
Converting to a shared instance might not be the behavior you want.
''', isError: true);
        return true;
      }());
    }
  }

  void _log(String text, {bool isError = false}) {
    StoreScopeConfig.log(text, isError: isError);
  }
}
