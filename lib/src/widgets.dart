part of 'store_scope.dart';

/// 自动包含 StoreScope 的 StatelessWidget 基类
abstract class StoreScopeWidget extends StoreScopeStatefulWidget {
  const StoreScopeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _StoreScopeWidgetState();
  }

  Widget build(BuildContext context);
}

class _StoreScopeWidgetState extends State<StoreScopeWidget> {
  @override
  Widget build(BuildContext _) {
    return widget.build(context);
  }
}

abstract class StoreScopeStatefulWidget extends StatefulWidget {
  const StoreScopeStatefulWidget({super.key});

  @override
  StatefulElement createElement() {
    return _StoreScopeStatefulElement(this);
  }
}

class _StoreScopeStatefulElement extends StatefulElement implements StoreOwner {
  _StoreScopeStatefulElement(StoreScopeStatefulWidget super.widget);

  late final StoreImpl _store = StoreImpl();

  @override
  Widget build() {
    return _InheritedStoreScope(store: store, child: super.build());
  }

  @override
  void unmount() {
    unmountStore();
    super.unmount();
  }

  @override
  Store get store => _store;

  @override
  void unmountStore() {
    _store.unmount();
  }
}
