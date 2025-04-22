import 'package:flutter/widgets.dart';

import '../store_scope.dart';

mixin DisposeStateAwareMixin<T extends StatefulWidget> on State<T>
    implements DisposeStateAware {
  late final _disposeNotifier = DisposeStateNotifier();

  @override
  Listenable get disposeNotifier => _disposeNotifier;

  @override
  void dispose() {
    _disposeNotifier.dispose();
    super.dispose();
  }
}

/// A mixin that provides dispose state tracking capability for [StatelessWidget]s.
///
/// This mixin creates and manages a [DisposeStateNotifier] that will be disposed
/// when the widget is removed from the tree.
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with DisposeStateAwareStatelessMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Container();
///   }
/// }
/// ```
mixin DisposeStateAwareStatelessMixin on StatelessWidget
    implements DisposeStateAware {
  late final _disposeNotifier = DisposeStateNotifier();

  @override
  Listenable get disposeNotifier => _disposeNotifier;

  @override
  StatelessElement createElement() => _DisposeAwareStatelessElement(this);
}

class _DisposeAwareStatelessElement extends StatelessElement {
  _DisposeAwareStatelessElement(DisposeStateAwareStatelessMixin super.widget);

  @override
  void unmount() {
    (widget as DisposeStateAwareStatelessMixin)._disposeNotifier.dispose();
    super.unmount();
  }
}

mixin StoreSpaceStateMixin<T extends StatefulWidget> on State<T>
    implements DisposeStateAware {
  final _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  @override
  Listenable get disposeNotifier => _disposeNotifier;

  StoreSpace get space {
    if (_space == null) {
      _currentStore = context.requireStore;
      _space = StoreSpace(_currentStore!, _disposeNotifier);
    }
    return _space!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_space != null) {
      final store = context.store;
      if (store != null && _currentStore != store) {
        _currentStore = store;
        _space = StoreSpace(store, _disposeNotifier);
      }
    }
  }

  @override
  void dispose() {
    _disposeNotifier.dispose();
    _space = null;
    _currentStore = null;
    super.dispose();
  }
}
