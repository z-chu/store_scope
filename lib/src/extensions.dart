part of 'store_scope.dart';

/// Convenience accessors for reaching the nearest [Store] from a
/// [BuildContext].
///
/// These are the widget-side entry points into `store_scope`: from inside a
/// `build` method (or anywhere you hold a [BuildContext]) you can locate the
/// [Store] owned by the closest [StoreScope] ancestor and acquire
/// store-lifetime instances from it. The [Store] is owned by that [StoreScope]
/// and lives until the scope unmounts.
///
/// For *scoped*, reference-counted acquisition tied to a widget's lifetime,
/// pair these with a scope-aware mixin (e.g. [ScopedStateMixin]) and call
/// [Store.bindWith] / [StoreSpace.bind] instead of [share].
///
/// Example:
/// ```dart
/// final authProvider = Provider.shared((space) => Auth());
///
/// class Profile extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final auth = context.share(authProvider); // store-lifetime singleton
///     return Text(auth.userName);
///   }
/// }
/// ```
extension StoreContextExtension on BuildContext {
  /// Returns the nearest [Store] instance that encloses the given context.
  ///
  /// This is a **non-reactive** lookup: it locates the [StoreScope]'s store
  /// *without* registering an inherited-widget dependency, so it never rebuilds
  /// the caller when the store changes (the store reference is stable for the
  /// life of a [StoreScope], whose inherited widget reports
  /// `updateShouldNotify == false`). For reactive updates, listen to the
  /// [Listenable] / [ViewModel] you acquire from the store — not to this lookup.
  ///
  /// If no [StoreScope] is found, this will throw a [FlutterError]. Use
  /// [storeOrNull] instead when the absence of a [StoreScope] is expected and
  /// should be handled gracefully.
  Store get store {
    final scope = storeOrNull;
    if (scope == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No StoreScope found in context'),
        ErrorDescription(
          'BuildContext.store was called with a context that does not contain a StoreScope widget.',
        ),
        ErrorHint(
          'Make sure that StoreScope is an ancestor of the widget calling BuildContext.store.',
        ),
        describeElement('The context used was'),
      ]);
    }
    return scope;
  }

  /// Returns the nearest mounted [Store], or `null` if none is reachable.
  ///
  /// Resolution order:
  /// 1. If this context is itself a [StoreOwner] whose store is still
  ///    [Store.mounted], that store is returned directly.
  /// 2. Otherwise the closest [StoreScope] ancestor's store is returned.
  ///
  /// Unlike [store], this never throws — it returns `null` when there is no
  /// enclosing [StoreScope] (or its store has already unmounted). Use it when
  /// the presence of a store is optional.
  Store? get storeOrNull {
    if (this is StoreOwner) {
      var storeOwner = (this as StoreOwner);
      if (storeOwner.store.mounted) {
        return storeOwner.store;
      }
    }
    final element =
        getElementForInheritedWidgetOfExactType<_InheritedStoreScope>();
    final _InheritedStoreScope? scope =
        element?.widget as _InheritedStoreScope?;
    return scope?.store;
  }

  /// Whether a [Store] is reachable from this context and still
  /// [Store.mounted].
  ///
  /// Returns `false` when there is no enclosing [StoreScope] or its store has
  /// already unmounted (for example during teardown). Handy as a guard before
  /// touching the store from callbacks that may fire after a widget leaves the
  /// tree.
  bool get storeMounted => storeOrNull?.mounted ?? false;

  /// Gets or creates a store-lifetime instance from the nearest [Store].
  ///
  /// Delegates to [Store.share]: the instance is created lazily on first access
  /// and kept alive until the owning [StoreScope] unmounts — no widget scope is
  /// required, which is why it only accepts a [SharedProvider] (create one with
  /// [Provider.shared], [ViewModelProvider.shared], or a `factory.asShared`
  /// argument family). Throws if no [StoreScope] ancestor exists; see [store].
  ///
  /// Like [store], this is a **non-reactive** lookup — it registers no
  /// inherited-widget dependency, so it never rebuilds the caller on its own.
  /// Listen to the acquired instance for updates, not to this call.
  ///
  /// For scoped, reference-counted acquisition that is disposed with a widget,
  /// use [Store.bindWith] or [StoreSpace.bind] instead.
  ///
  /// Example:
  /// ```dart
  /// final authProvider = Provider.shared((space) => Auth());
  /// final auth = context.share(authProvider); // store-lifetime singleton
  /// ```
  T share<T>(SharedProvider<T> provider) => store.share(provider);
}
