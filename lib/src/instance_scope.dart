part of 'provider.dart';

class _InstanceScopeManager {
  late final Map<dynamic, DisposeStateNotifier> _instanceScopes =
      Map<dynamic, DisposeStateNotifier>.identity();

  void onInstanceCreated(dynamic instance, DisposeStateNotifier scope) {
    _instanceScopes[instance] = scope;
  }

  void onInstanceDisposed(dynamic instance) {
    var scope = _instanceScopes[instance];
    if (scope != null) {
      scope.dispose();
      _instanceScopes.remove(instance);
    }
  }
}

class _InstanceScopeManagerProvider
    extends ProviderBase<_InstanceScopeManager> {
  @override
  _InstanceScopeManager create(Store store) {
    return _InstanceScopeManager();
  }

  @override
  void dispose(Store store, _InstanceScopeManager instance) {}
}

final _instanceScopeManagerProvider = _InstanceScopeManagerProvider();
