
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../store_scope.dart';

mixin ScopedStateMixin<T extends StatefulWidget> on State<T>
    implements ScopeAware {
  late final _disposeNotifier = DisposeStateNotifier();

  @override
  Listenable get scope => _disposeNotifier;

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
/// **Usage:** Override [buildScoped] instead of [build].
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with ScopedStatelessMixin {
///   @override
///   Widget buildScoped(BuildContext context, Listenable scope) {
///     final data = context.store.bindWith(dataProvider, scope);
///     return Text('Data: $data');
///   }
/// }
/// ```
mixin ScopedStatelessMixin on StatelessWidget {

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (context is! _DisposeAwareStatelessElement) {
      throw StateError(
        'ScopedStatelessMixin must be used with its own Element',
      );
    }
    return buildScoped(context, context.scope);
  }


  /// Build the widget with the given scope.
  ///
  /// **IMPORTANT:** 
  /// - Do NOT override the [build] method when using this mixin
  /// - Override this method instead to build your widget
  /// - The [scope] parameter will be automatically disposed when the widget is removed
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildScoped(BuildContext context, Listenable scope) {
  ///   final counter = context.store.bindWith(counterProvider, scope);
  ///   return Text('Counter: $counter');
  /// }
  /// ```
  @protected
  Widget buildScoped(BuildContext context, Listenable scope);

  @override
  StatelessElement createElement() => _DisposeAwareStatelessElement(this);
}

class _DisposeAwareStatelessElement extends StatelessElement
    implements ScopeAware {
  _DisposeAwareStatelessElement(ScopedStatelessMixin super.widget);

  final _disposeNotifier = DisposeStateNotifier();

  @override
  void unmount() {
    _disposeNotifier.dispose();
    super.unmount();
  }

  @override
  Listenable get scope => _disposeNotifier;
}


// ... existing code ...

/// A mixin that provides store space management capability for [StatelessWidget]s.
///
/// This mixin creates and manages a [StoreSpace] instance that will be automatically
/// updated when the store in the widget tree changes, and disposed when the widget
/// is removed from the tree.
///
/// The [StoreSpace] provides a scoped space for managing store-related state and
/// subscriptions that will be automatically cleaned up when the widget is disposed.
///
/// **Usage:** Override [buildWithSpace] instead of [build].
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with ScopedSpaceStatelessMixin {
///   @override
///   Widget buildScoped(BuildContext context, StoreSpace space) {
///     final counter = space.bind(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
mixin ScopedSpaceStatelessMixin on StatelessWidget {

  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (context is! _SpaceAwareStatelessElement) {
      throw StateError(
        'ScopedSpaceStatelessMixin must be used with its own Element',
      );
    }
    return buildWithSpace(context, context.space);
  }

  /// Build the widget with the given store space.
  ///
  /// **IMPORTANT:** 
  /// - Do NOT override the [build] method when using this mixin
  /// - Override this method instead to build your widget
  /// - The [space] parameter provides scoped access to the store and will be automatically disposed when the widget is removed
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildScoped(BuildContext context, StoreSpace space) {
  ///   final counter = space.bind(counterProvider);
  ///   return Text('Counter: $counter');
  /// }
  /// ```
  @protected
  Widget buildWithSpace(BuildContext context, StoreSpace space);

  @override
  StatelessElement createElement() => _SpaceAwareStatelessElement(this);
}

class _SpaceAwareStatelessElement extends StatelessElement
    implements ScopeAware {
  _SpaceAwareStatelessElement(ScopedSpaceStatelessMixin super.widget);

  final _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  @override
  Listenable get scope => _disposeNotifier;

  StoreSpace get space {
    if (_space == null) {
      _currentStore = store;
      _space = StoreSpace(_currentStore!, _disposeNotifier);
    }
    return _space!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_space != null) {
      final store = storeOrNull;
      if (store != null && _currentStore != store) {
        _currentStore = store;
        _space = StoreSpace(store, _disposeNotifier);
      }
    }
  }

  @override
  void unmount() {
    _disposeNotifier.dispose();
    _space = null;
    _currentStore = null;
    super.unmount();
  }
}

/// A mixin that provides store space management capability for [StatefulWidget]s.
///
/// This mixin creates and manages a [StoreSpace] instance that will be automatically
/// updated when the store in the widget tree changes, and disposed when the widget
/// is removed from the tree.
///
/// The [StoreSpace] provides a scoped space for managing store-related state and
/// subscriptions that will be automatically cleaned up when the widget is disposed.
///
/// Example:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with ScopedSpaceStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     // Access the store space
///     final storeSpace = space;
///
///     // Use the store space to manage store-related state
///     return Container();
///   }
/// }
/// ```
mixin ScopedSpaceStateMixin<T extends StatefulWidget> on State<T>
    implements ScopeAware {
  final _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  @override
  Listenable get scope => _disposeNotifier;

  StoreSpace get space {
    if (_space == null) {
      _currentStore = context.store;
      _space = StoreSpace(_currentStore!, _disposeNotifier);
    }
    return _space!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_space != null) {
      final store = context.storeOrNull;
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
