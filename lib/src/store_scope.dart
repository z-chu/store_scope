import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'provider.dart';
import 'store.dart';

part 'extensions.dart';
part 'auto_store_widgets.dart';

/// A widget that provides a [Store] implementation for the widget tree.
///
/// You can either use the default store implementation:
/// ```dart
/// StoreScope(
///   child: MyApp(),
/// )
/// ```
///
/// Or provide a custom [StoreOwner]:
/// ```dart
/// StoreScope(
///   storeOwner: MyCustomStoreOwner(),
///   child: MyApp(),
/// )
/// ```
class StoreScope extends StatefulWidget {
  final StoreOwner? storeOwner;

  /// Provider overrides (e.g. fakes/mocks for tests) applied to the default
  /// store. Ignored when a custom [storeOwner] is supplied.
  ///
  /// Read **once** when the store is created; changing this list on a later
  /// rebuild has no effect. To swap overrides at runtime, give the [StoreScope]
  /// a new [key] (or [storeOwner]) so the store is rebuilt.
  final List<Override<dynamic>> overrides;

  final Widget child;

  /// Creates a [StoreScope] with a default store implementation.
  const StoreScope({
    super.key,
    this.storeOwner,
    this.overrides = const [],
    required this.child,
  }) : assert(
         storeOwner == null || overrides.length == 0,
         'StoreScope.overrides are ignored when a custom storeOwner is provided.',
       );

  @override
  State<StoreScope> createState() => _StoreScopeState();
}

class _StoreScopeState extends State<StoreScope> {
  late StoreOwner _storeOwner;

  /// Resolves the store owner from the current widget: the supplied
  /// [StoreScope.storeOwner], or a default store carrying the widget's
  /// [StoreScope.overrides].
  StoreOwner _resolveStoreOwner() =>
      widget.storeOwner ??
      StoreOwnerImpl(StoreImpl(overrides: widget.overrides));

  @override
  void initState() {
    super.initState();
    _storeOwner = _resolveStoreOwner();
  }

  Store get _store => _storeOwner.store;

  @override
  Widget build(BuildContext context) {
    // We use ValueKey(_store) to force the entire subtree to rebuild
    // whenever the store instance changes. This ensures that all dependent
    // widgets (including their State) are recreated, and their initState
    // methods are called again.
    return _InheritedStoreScope(
      key: ValueKey(_store),
      store: _store,
      child: widget.child,
    );
  }

  @override
  void didUpdateWidget(StoreScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storeOwner != oldWidget.storeOwner) {
      final oldStoreOwner = _storeOwner;
      _storeOwner = _resolveStoreOwner();

      if (oldStoreOwner.store.mounted) {
        oldStoreOwner.unmountStore();
      }
    }
  }

  @override
  void dispose() {
    if (_store.mounted) {
      _storeOwner.unmountStore();
    }
    super.dispose();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Store>('store', _store))
      ..add(
        FlagProperty(
          'mounted',
          value: _store.mounted,
          ifTrue: 'mounted',
          ifFalse: 'unmounted',
        ),
      );
  }
}

class _InheritedStoreScope extends InheritedWidget {
  final Store store;

  const _InheritedStoreScope({
    required this.store,
    required super.child,
    super.key,
  });

  @override
  bool updateShouldNotify(covariant _InheritedStoreScope oldWidget) {
    // This InheritedWidget is only used for dependency injection (sharing the store).
    // It does NOT provide any reactive update mechanism.
    // All updates are handled by rebuilding the entire subtree via key changes.
    return false;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Store>('store', store));
    properties.add(
      FlagProperty(
        'mounted',
        value: store.mounted,
        ifTrue: 'mounted',
        ifFalse: 'unmounted',
      ),
    );
  }
}
