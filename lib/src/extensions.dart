part of 'store_scope.dart';

extension StoreContextExtension on BuildContext {
  /// Returns the nearest [Store] instance that encloses the given context.
  ///
  /// Calling this method will create a dependency on the closest [StoreScope]
  /// ancestor.
  ///
  /// If no [StoreScope] is found, this will throw a [FlutterError].
  Store get requireStore {
    if (this is StoreOwner) {
      return (this as StoreOwner).store;
    }
    final scope = dependOnInheritedWidgetOfExactType<_InheritedStoreScope>();
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
    return scope.store;
  }

  Store? get store {
    if (this is StoreOwner) {
      return (this as StoreOwner).store;
    }
    final scope = dependOnInheritedWidgetOfExactType<_InheritedStoreScope>();
    return scope?.store;
  }

  T read<T>(Provider<T> provider) => requireStore.shared(provider);

  T bind<T>(Provider<T> provider, Listenable disposeNotifier) =>
      requireStore.bind(provider, disposeNotifier);

  T bindWith<T>(Provider<T> provider, DisposeStateAware disposeStateAware) =>
      bind(provider, disposeStateAware.disposeNotifier);

  bool exists<T>(Provider<T> provider) => requireStore.exists(provider);

  bool get storeMounted => store?.mounted ?? false;
}
