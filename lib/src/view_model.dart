import 'package:flutter/foundation.dart';
import 'package:store_scope/src/provider.dart' show BindableProvider;

import 'dispose_state_notifier.dart';
import 'store_space.dart';
import 'store_scope_config.dart';

abstract class ViewModel implements DisposeStateAware {
  final _disposeNotifier = DisposeStateNotifier();

  @override
  Listenable get disposeNotifier => _disposeNotifier;

  bool get disposed => _disposeNotifier.disposed;

  void init() {}

  @mustCallSuper
  void dispose() {
    _disposeNotifier.dispose();
    StoreScopeConfig.log('ViewModel $runtimeType disposed');
  }
}

class ViewModelProvider<T extends ViewModel> extends BindableProvider<T> {
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
