part of 'store_scope.dart';

extension StoreContextExtension on BuildContext {
  /// Returns the nearest [Store] instance that encloses the given context.
  ///
  /// Calling this method will create a dependency on the closest [StoreScope]
  /// ancestor.
  ///
  /// If no [StoreScope] is found, this will throw a [FlutterError].
  Store get store {
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

  Store? get storeOrNull {
    if (this is StoreOwner) {
      return (this as StoreOwner).store;
    }
    final scope = dependOnInheritedWidgetOfExactType<_InheritedStoreScope>();
    return scope?.store;
  }

  bool get storeMounted => storeOrNull?.mounted ?? false;
}
