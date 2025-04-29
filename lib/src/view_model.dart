import 'package:flutter/foundation.dart';
import 'package:store_scope/src/provider.dart' show Provider;

import 'dispose_state_notifier.dart';
import 'store.dart';
import 'store_space.dart';
import 'store_scope_config.dart';

abstract class ViewModel implements ScopeAware {
  final _viewModelScope = DisposeStateNotifier();
  final Map<String, VoidCallback> _keyToCloseables = {};
  final Set<VoidCallback> _closeables = {};

  @override
  Listenable get scope => _viewModelScope;

  bool get disposed => _viewModelScope.disposed;

  void init() {}

  @mustCallSuper
  void dispose() {
    _viewModelScope.dispose();
    StoreScopeConfig.log('ViewModel $runtimeType disposed');
  }

  @protected
  void addCloseable(VoidCallback closeable) {
    if (disposed) {
      closeable();
      return;
    }
    if (_closeables.contains(closeable)) {
      return;
    }
    _closeables.add(closeable);
    _viewModelScope.addListener(closeable);
  }

  @protected
  void addKeyedCloseable(String key, VoidCallback closeable) {
    if (disposed) {
      closeable();
      return;
    }
    var oldCloseable = _keyToCloseables[key];
    if (oldCloseable != null) {
      if (oldCloseable == closeable) return;
      _viewModelScope.removeListener(oldCloseable);
      oldCloseable.call();
    }
    _keyToCloseables[key] = closeable;
    _viewModelScope.addListener(closeable);
  }
}

class ViewModelProvider<T extends ViewModel> extends Provider<T> {
  final T Function(StoreSpace space) creator;
  final void Function(T instance)? disposer;

  ViewModelProvider(this.creator, {this.disposer});

  @override
  T createInstance(StoreSpace space) {
    final vm = creator(space);
    vm.init();
    return vm;
  }

  @override
  @mustCallSuper
  void disposeInstance(T instance) {
    instance.dispose();
    disposer?.call(instance);
  }
}
