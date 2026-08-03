import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'provider.dart';
import 'store.dart';

part 'extensions.dart';
part 'auto_store_widgets.dart';

/// The widget that creates and owns a [Store] for its subtree.
///
/// Place a [StoreScope] above the widgets that need dependency injection.
/// While the scope is mounted its [Store] is reachable from descendants (for
/// example through `context.share(...)` or the scoped widgets in this
/// package), and it acts as the lifetime boundary for everything the store
/// holds: removing the [StoreScope] from the tree unmounts the store and
/// deterministically disposes every instance it created.
///
/// Most apps wrap their root with a single store-lifetime scope:
/// ```dart
/// StoreScope(
///   child: MyApp(),
/// )
/// ```
///
/// For tests (or feature-local sandboxes) you can inject test doubles through
/// [overrides] without touching production provider definitions:
/// ```dart
/// StoreScope(
///   overrides: [
///     apiProvider.overrideWithValue(FakeApi()),
///     repoProvider.overrideWith((space) => InMemoryRepo()),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// Advanced callers can supply a custom [StoreOwner] to control how the
/// underlying store is built and torn down:
/// ```dart
/// StoreScope(
///   storeOwner: MyCustomStoreOwner(),
///   child: MyApp(),
/// )
/// ```
///
/// Lifetime: the store is created in `initState` and unmounted in `dispose`
/// (or when [storeOwner] changes on a rebuild). Provider instances bound or
/// shared through this store live no longer than the scope itself.
class StoreScope extends StatefulWidget {
  /// An optional, externally managed owner of the [Store].
  ///
  /// When supplied, this [StoreScope] uses the owner's store as-is instead of
  /// creating a default one, and delegates unmounting to the owner. Use this
  /// to share a single store across rebuilds, hoist store ownership outside the
  /// widget tree, or plug in a custom store implementation.
  ///
  /// When non-null, [overrides] are ignored (enforced by an assert in the
  /// constructor). Changing the owner on a rebuild rebuilds the store and
  /// unmounts the previous one.
  final StoreOwner? storeOwner;

  /// Provider overrides (e.g. fakes/mocks for tests) applied to the default
  /// store. Ignored when a custom [storeOwner] is supplied.
  ///
  /// Each [Override] is installed at creation time: `overrideWithValue(v)`
  /// injects a ready instance, while `overrideWith((space) => x)` replaces the
  /// provider's creation logic with a factory that can `space.bind` its own
  /// dependencies. In both cases the store only *returns* the instance — it
  /// runs no lifecycle on it, so an overridden `ViewModelProvider` does not
  /// `init()` or `dispose()` the fake. See `ProviderOverride` for the rule and
  /// for how to test the real lifecycle.
  ///
  /// Read **once** when the store is created; changing this list on a later
  /// rebuild has no effect. To swap overrides at runtime, give the [StoreScope]
  /// a new [key] (or [storeOwner]) so the store is rebuilt.
  final List<Override<dynamic>> overrides;

  /// The subtree that gains access to this scope's [Store].
  final Widget child;

  /// Creates a [StoreScope] with a default store implementation.
  ///
  /// Pass [overrides] to inject test doubles into the default store, or supply
  /// a [storeOwner] to provide a custom or shared store. The two are mutually
  /// exclusive: an assert fails if both [storeOwner] and a non-empty
  /// [overrides] list are given.
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
