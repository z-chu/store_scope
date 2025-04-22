import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:store_scope/src/dispose_state_notifier.dart';

import 'provider.dart';
import 'store.dart';

part 'extensions.dart';
part 'widgets.dart';

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
  final Widget child;

  /// Creates a [StoreScope] with a default store implementation.
  const StoreScope({super.key, this.storeOwner, required this.child});

  @override
  State<StoreScope> createState() => _StoreScopeState();
}

class _StoreScopeState extends State<StoreScope> {
  late final StoreOwner _storeOwner;

  @override
  void initState() {
    super.initState();
    _storeOwner = widget.storeOwner ?? StoreOwnerImpl(StoreImpl());
  }

  Store get _store => _storeOwner.store;

  @override
  Widget build(BuildContext context) =>
      _InheritedStoreScope(store: _store, child: widget.child);

  @override
  void didUpdateWidget(StoreScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storeOwner != oldWidget.storeOwner) {
      final oldStoreOwner = _storeOwner;
      _storeOwner = widget.storeOwner ?? StoreOwnerImpl(StoreImpl());

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

  const _InheritedStoreScope({required this.store, required super.child});

  @override
  bool updateShouldNotify(covariant _InheritedStoreScope oldWidget) {
    return oldWidget.store != store;
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
