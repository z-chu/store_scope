part of 'store.dart';

class StoreImpl implements UnmountableStore {
  final Map<ProviderBase<dynamic>, dynamic> _instances = {};
  final Map<ProviderBase<dynamic>, Set<Listenable>> _watchers = {};
  final _sharedProviders = <ProviderBase>{};

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

  T _read<T>(ProviderBase<T> provider, bool shared) {
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

  @override
  T shared<T>(ProviderBase<T> provider) {
    _checkMounted();
    _warnIfBound(provider);
    return _read(provider, true);
  }

  void _invalidate<T>(ProviderBase<T> provider) {
    // 检查是否是 shared provider，如果是则不清理
    if (_sharedProviders.contains(provider)) {
      return;
    }
    final instance = _instances[provider];
    provider.dispose(this, instance);
    _instances.remove(provider);
    _watchers.remove(provider);
    _log(
      '"${instance.runtimeType}" instance disposed',
    );
  }

  /// Watches a provider with the given notifier.
  /// When the notifier is disposed, it will automatically unwatch the provider.
  @override
  T bindWith<T>(ProviderBase<T> provider, Listenable scope) {
    _checkMounted();
    _warnIfShared(provider);
    final watchers = _watchers.putIfAbsent(provider, () => <Listenable>{});
    if (watchers.add(scope)) {
      // 只在第一次添加时创建并存储回调
      callback() => _unbind(provider, scope);
      scope.addListener(callback);
      _log('"${provider.runtimeType}" bindWith new scope');
    }
    return _read(provider, false);
  }

  /// Unwatches a provider for the given notifier.
  /// If there are no more watchers, the provider will be reset.
  void _unbind<T>(ProviderBase<T> provider, Listenable scope) {
    final watchers = _watchers[provider];
    if (watchers == null || watchers.isEmpty) return;
    if (watchers.remove(scope)) {
      if (watchers.isEmpty) {
        _watchers.remove(provider);
        _log(
          '"${provider.runtimeType}" all scopes unbound',
        );
        _invalidate(provider);
      }
    }
  }

  @override
  void unmount() {
    if (!_mounted) return;
    _mounted = false;
    _log('''
Store unmounted:
- Instances cleared: ${_instances.length}
- Watchers cleared: ${_watchers.length}
- Shared instances cleared: ${_sharedProviders.length}
''');
    _instances.clear();
    _watchers.clear();
    _sharedProviders.clear();
  }

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
    if (_watchers.containsKey(provider)) {
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
