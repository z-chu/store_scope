part of 'store_scope.dart';

/// 自动包含 StoreScope 的 StatelessWidget 基类
///
/// 这个类为无状态组件提供了自动的状态管理能力。
/// 继承此类的组件会自动获得一个独立的 Store 实例，
/// 无需手动包装 StoreScope widget。
///
/// 使用示例：
/// ```dart
/// class MyPage extends AutoStoreWidget {
///   const MyPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // 可以直接使用 context.shared() 等方法访问 Store
///     final counter = context.shared(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
///
/// 注意：虽然名为 AutoStoreWidget，但它实际上继承自 AutoStoreStatefulWidget，
/// 这是为了能够管理 Store 的生命周期（创建和销毁）。
abstract class AutoStoreWidget extends AutoStoreStatefulWidget {
  const AutoStoreWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AutoStoreWidgetState();
  }

  /// 子类需要实现这个方法来构建UI
  /// 在这个方法中可以直接使用 context 访问 Store
  Widget build(BuildContext context);
}

/// AutoStoreWidget 的内部状态类
/// 负责将 build 方法委托给 widget
class _AutoStoreWidgetState extends State<AutoStoreWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

/// 自动包含 StoreScope 的 StatefulWidget 基类
///
/// 这个类为有状态组件提供了自动的状态管理能力。
/// 继承此类的组件会自动获得一个独立的 Store 实例，
/// 该实例会在组件的整个生命周期中保持存在，
/// 并在组件销毁时自动清理。
///
/// 使用示例：
/// ```dart
/// class MyStatefulPage extends AutoStoreStatefulWidget {
///   const MyStatefulPage({super.key});
///
///   @override
///   State<MyStatefulPage> createState() => _MyStatefulPageState();
/// }
///
/// class _MyStatefulPageState extends State<MyStatefulPage> {
///   @override
///   Widget build(BuildContext context) {
///     // 可以直接使用 context.shared() 等方法访问 Store
///     final counter = context.shared(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
///
/// 主要特性：
/// - 自动创建和管理 Store 实例
/// - Store 生命周期与组件生命周期绑定
/// - 组件销毁时自动清理 Store 资源
/// - 通过 InheritedWidget 向子组件提供 Store 访问
abstract class AutoStoreStatefulWidget extends StatefulWidget {
  const AutoStoreStatefulWidget({super.key});

  @override
  StatefulElement createElement() {
    // 创建自定义的 Element，用于管理 Store 生命周期
    return _AutoStoreStatefulElement(this);
  }
}

/// AutoStoreStatefulWidget 的自定义 Element 实现
///
/// 这个 Element 实现了 StoreOwner 接口，负责：
/// 1. 创建和管理 Store 实例
/// 2. 通过 InheritedWidget 向子组件提供 Store 访问
/// 3. 在组件卸载时清理 Store 资源
class _AutoStoreStatefulElement extends StatefulElement implements StoreOwner {
  _AutoStoreStatefulElement(AutoStoreStatefulWidget super.widget);

  /// Store 实例，延迟初始化
  /// 每个 AutoStoreStatefulWidget 都有自己独立的 Store
  late final StoreImpl _store = StoreImpl();

  @override
  Widget build() {
    // 使用 InheritedWidget 包装子组件，使 Store 可以被子组件访问
    // 这样子组件就可以通过 context.shared() 等方法使用 Store
    return _InheritedStoreScope(store: store, child: super.build());
  }

  @override
  void unmount() {
    // 在 Element 卸载时清理 Store 资源
    // 这确保了所有相关的 Provider 实例都会被正确清理
    unmountStore();
    super.unmount();
  }

  @override
  Store get store => _store;

  @override
  void unmountStore() {
    // 卸载 Store，清理所有相关资源
    _store.unmount();
  }
}
