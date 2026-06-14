[![pub.dev Version (including pre-releases)](https://img.shields.io/pub/v/store_scope?include_prereleases)](https://pub.dev/packages/store_scope)
[![zread](https://img.shields.io/badge/Ask_Zread-_.svg?style=flat&color=00b0aa&labelColor=000000&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQuOTYxNTYgMS42MDAxSDIuMjQxNTZDMS44ODgxIDEuNjAwMSAxLjYwMTU2IDEuODg2NjQgMS42MDE1NiAyLjI0MDFWNC45NjAxQzEuNjAxNTYgNS4zMTM1NiAxLjg4ODEgNS42MDAxIDIuMjQxNTYgNS42MDAxSDQuOTYxNTZDNS4zMTUwMiA1LjYwMDEgNS42MDE1NiA1LjMxMzU2IDUuNjAxNTYgNC45NjAxVjIuMjQwMUM1LjYwMTU2IDEuODg2NjQgNS4zMTUwMiAxLjYwMDEgNC45NjE1NiAxLjYwMDFaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00Ljk2MTU2IDEwLjM5OTlIMi4yNDE1NkMxLjg4ODEgMTAuMzk5OSAxLjYwMTU2IDEwLjY4NjQgMS42MDE1NiAxMS4wMzk5VjEzLjc1OTlDMS42MDE1NiAxNC4xMTM0IDEuODg4MSAxNC4zOTk5IDIuMjQxNTYgMTQuMzk5OUg0Ljk2MTU2QzUuMzE1MDIgMTQuMzk5OSA1LjYwMTU2IDE0LjExMzQgNS42MDE1NiAxMy43NTk5VjExLjAzOTlDNS42MDE1NiAxMC42ODY0IDUuMzE1MDIgMTAuMzk5OSA0Ljk2MTU2IDEwLjM5OTlaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik0xMy43NTg0IDEuNjAwMUgxMS4wMzg0QzEwLjY4NSAxLjYwMDEgMTAuMzk4NCAxLjg4NjY0IDEwLjM5ODQgMi4yNDAxVjQuOTYwMUMxMC4zOTg0IDUuMzEzNTYgMTAuNjg1IDUuNjAwMSAxMS4wMzg0IDUuNjAwMUgxMy43NTg0QzE0LjExMTkgNS42MDAxIDE0LjM5ODQgNS4zMTM1NiAxNC4zOTg0IDQuOTYwMVYyLjI0MDFDMTQuMzk4NCAxLjg4NjY0IDE0LjExMTkgMS42MDAxIDEzLjc1ODQgMS42MDAxWiIgZmlsbD0iI2ZmZiIvPgo8cGF0aCBkPSJNNCAxMkwxMiA0TDQgMTJaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00IDEyTDEyIDQiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K&logoColor=ffffff)](https://zread.ai/z-chu/store_scope)

# StoreScope

一个轻量级的 Flutter 状态管理库，专注于提供简洁的状态生命周期管理和局部状态管理。

## 特性

- 🚀 简洁的状态生命周期管理
- 🔄 基于 Widget 树的局部状态管理
- 🔗 支持状态之间的相互依赖
- 🧹 自动管理状态的生命周期和资源释放
- 🎯 专注于状态管理，不包含响应式机制

## 快速开始


### 1. 在应用的根 Widget 中添加 StoreScope:

```dart
void main() {
  runApp(
    StoreScope(
      child: MyApp(),
    ),
  );
}
```

### 2. 创建简单的状态类:

 使用 ValueNotifier 创建响应式状态:

```dart
class Counter {
  final _count = ValueNotifier<int>(0);
  ValueNotifier<int> get count => _count;
  
  void increment() {
    _count.value++;
  }
}
```

### 3. 创建 Provider:

```dart
// 作用域实例：跟随绑定它的页面/Widget，最后一个使用者销毁时自动析构（见方式二）
final counterProvider = Provider.from(
  (space) => Counter(),
);

// 全局实例：跟随 Store 生命周期，直到 StoreScope 被移除；用 context.read 读取（见方式一）
final sharedCounterProvider = Provider.shared(
  (space) => Counter(),
);
```


### 4. 在页面中使用响应式状态:

#### 方式一：使用 Provider.shared + context.read（全局状态）

```dart
class Home extends StatelessWidget {

  @override
  Widget build(context) {
    // 用 read 读取全局实例，它会一直存在于内存中，直到 StoreScope 被移除
    var counter = context.read(sharedCounterProvider);
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: counter.count,
          builder: (_, count, __) {
            return Text('Count: $count');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add), 
        onPressed: counter.increment
      ),
    );
  }
}


class Other extends StatelessWidget {

   @override
  Widget build(BuildContext context) {
    // 在其他页面中也可以访问同一个全局状态
    final counter = context.read(sharedCounterProvider);
    
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: counter.count,
          builder: (_, count, __) {
            return Text('Count: $count');
          },
        ),
      ),
    );
  }
}
```

#### 方式二：使用 bind（自动销毁）

```dart
class Home extends StatelessWidget with ScopedSpaceStatelessMixin{

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    // 在所有绑定的页面销毁时自动释放counter
    var counter = space.bind(counterProvider);
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: counter.count,
          builder: (_, count, __) {
            return Text('Count: $count');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add), 
        onPressed: counter.increment
      ),
    );
  }
}


class Other extends StatelessWidget with ScopedSpaceStatelessMixin{

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    // 在所有绑定的页面销毁时自动释放counter
    var counter = space.bind(counterProvider);
    
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: counter.count,
          builder: (_, count, __) {
            return Text('Count: $count');
          },
        ),
      ),
    );
  }
}
```




## 高级用法

### 带参数的 Provider
```dart
// 定义带参数的 Provider
final userProvider = Provider.withArgument<User, int>((space, int userId) {
  return User(userId: userId);
});
 
// 使用
final user = space.bind(userProvider(42));
```

### 状态依赖
```dart
final userProfileProvider = ViewModelProvider((space) {
  final user = space.bind(userProvider(42));
  final settings = space.bind(settingsProvider);
  return UserProfileViewModel(user, settings);
});
```

## ViewModel
ViewModel 是 StoreScope 中的核心组件，它提供了完整的状态生命周期管理和资源清理机制.

#### 1. 生命周期管理
```dart
class CounterViewModel extends ViewModel {
  final _count = ValueNotifier<int>(0);
  ValueNotifier<int> get count => _count;
  
  @override
  void init() {
    super.init();
    // 初始化逻辑，比如订阅数据流、初始化状态等
    _count.value = 10; // 设置初始值
  }
  
  void increment() => _count.value++;
  
  @override
  void dispose() {
    _count.dispose(); // 清理资源
    super.dispose(); // 必须调用 super.dispose()
  }
}
```

#### 2. 资源自动管理
ViewModel 提供了多种方式管理资源的生命周期：

```dart
class NetworkViewModel extends ViewModel {
  Timer? _timer;
  StreamSubscription? _subscription;
  
  @override
  void init() {
    super.init();
    
    // 方式一：添加订阅，自动取消
    _subscription = someStream.listen((data) {
      // 处理数据
    });
    addSubscription(_subscription!);
    
    // 方式二：添加任意可关闭资源
    addCloseable(() {
      print('清理自定义资源');
    });
    
    // 方式三：带键的资源管理
    addKeyedCloseable('timer', () {
      _timer?.cancel();
    });
    
    // 如果添加了同键的资源，旧的会被立即清理
    addKeyedCloseable('timer', () {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        // 新的定时器逻辑
      });
    });
  }
}
```
#### 3. 使用ViewModelProvider：
```dart
final viewModelProvider = ViewModelProvider((space) => CounterViewModel());
 
// 使用
final viewModel = space.bind(viewModelProvider);
// 这将自动调用 ViewModel 的 init() 
// 当销毁时也会自动调用 ViewModel 的 dispose()
```
#### 4.带参数的 ViewModelProvide
```dart
// 单参数
final userViewModelProvider = ViewModelProvider.withArgument<UserViewModel, int>(
  (space, int userId) => UserViewModel(userId),
);
 
// 双参数
final productViewModelProvider = ViewModelProvider.withArgument2<ProductViewModel, String, int>(
  (space, String category, int page) => ProductViewModel(category, page),
);

//更多参数也支持
 
// 使用
final userVM = space.bind(userViewModelProvider(42));
final productVM = space.bind(productViewModelProvider('electronics', 1));
```
## 测试：替换 Provider（Override）

在测试中，可以用 override 把任意 Provider 替换成 fake/mock，无需改动业务代码。Override 通过 `StoreScope(overrides: ...)`（Widget 测试）或 `StoreImpl(overrides: ...)`（纯 Dart 测试）注入。

```dart
abstract class Repository {
  Future<String> fetch();
}

class FakeRepository implements Repository {
  @override
  Future<String> fetch() async => 'fake data';
}

final repositoryProvider =
    Provider.shared<Repository>((space) => RealRepository());

testWidgets('使用 fake 数据', (tester) async {
  await tester.pumpWidget(
    StoreScope(
      overrides: [
        repositoryProvider.overrideWithValue(FakeRepository()),
      ],
      child: const MyApp(),
    ),
  );
  // ...
});
```

两种构造方式：

- `overrideWithValue(fake)`：直接返回一个现成实例，**Store 不会创建也不会析构它**，生命周期由你自己掌控。注入 mock 的首选。
- `overrideWith((space) => fake, dispose: ...)`：替换创建逻辑，按普通实例处理。注意替换 `ViewModelProvider` 时，fake 的 `init()` / `dispose()` **不会**被自动调用——如需析构，显式传 `dispose: (vm) => vm.dispose()`。

> 带参数的 Provider 按**具体参数**匹配：`userProvider(42).overrideWithValue(...)` 只覆盖 `userProvider(42)`，`userProvider(7)` 仍走真实实现。
>
> override 在 Store 创建时读取一次；运行期更换需要给 `StoreScope` 一个新的 `key`（或新的 `storeOwner`）以重建 Store。

## 关于响应式

StoreScope 本身不包含任何响应式机制。它专注于状态管理，让响应式库可以专注于它们擅长的部分。你可以：

1. 使用内置的响应式类：
   - ValueNotifier
   - ChangeNotifier

2. 使用第三方响应式库：
   - solidart
   - signals
   - flutter_bloc
   - 等等

这样的设计让 StoreScope 保持简单和专注，同时又能与任何响应式库完美配合。

## 更多介绍

请查看 https://zread.ai/z-chu/store_scope
