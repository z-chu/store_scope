[![pub.dev Version (including pre-releases)](https://img.shields.io/pub/v/store_scope?include_prereleases)](https://pub.dev/packages/store_scope)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![zread](https://img.shields.io/badge/Ask_Zread-_.svg?style=flat&color=00b0aa&labelColor=000000&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQuOTYxNTYgMS42MDAxSDIuMjQxNTZDMS44ODgxIDEuNjAwMSAxLjYwMTU2IDEuODg2NjQgMS42MDE1NiAyLjI0MDFWNC45NjAxQzEuNjAxNTYgNS4zMTM1NiAxLjg4ODEgNS42MDAxIDIuMjQxNTYgNS42MDAxSDQuOTYxNTZDNS4zMTUwMiA1LjYwMDEgNS42MDE1NiA1LjMxMzU2IDUuNjAxNTYgNC45NjAxVjIuMjQwMUM1LjYwMTU2IDEuODg2NjQgNS4zMTUwMiAxLjYwMDEgNC45NjE1NiAxLjYwMDFaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00Ljk2MTU2IDEwLjM5OTlIMi4yNDE1NkMxLjg4ODEgMTAuMzk5OSAxLjYwMTU2IDEwLjY4NjQgMS42MDE1NiAxMS4wMzk5VjEzLjc1OTlDMS42MDE1NiAxNC4xMTM0IDEuODg4MSAxNC4zOTk5IDIuMjQxNTYgMTQuMzk5OUg0Ljk2MTU2QzUuMzE1MDIgMTQuMzk5OSA1LjYwMTU2IDE0LjExMzQgNS42MDE1NiAxMy43NTk5VjExLjAzOTlDNS42MDE1NiAxMC42ODY0IDUuMzE1MDIgMTAuMzk5OSA0Ljk2MTU2IDEwLjM5OTlaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik0xMy43NTg0IDEuNjAwMUgxMS4wMzg0QzEwLjY4NSAxLjYwMDEgMTAuMzk4NCAxLjg4NjY0IDEwLjM5ODQgMi4yNDAxVjQuOTYwMUMxMC4zOTg0IDUuMzEzNTYgMTAuNjg1IDUuNjAwMSAxMS4wMzg0IDUuNjAwMUgxMy43NTg0QzE0LjExMTkgNS42MDAxIDE0LjM5ODQgNS4zMTM1NiAxNC4zOTg0IDQuOTYwMVYyLjI0MDFDMTQuMzk4NCAxLjg4NjY0IDE0LjExMTkgMS42MDAxIDEzLjc1ODQgMS42MDAxWiIgZmlsbD0iI2ZmZiIvPgo8cGF0aCBkPSJNNCAxMkwxMiA0TDQgMTJaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00IDEyTDEyIDQiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K&logoColor=ffffff)](https://zread.ai/z-chu/store_scope)

# store_scope

**Flutter 版的 Jetpack ViewModel** —— 绑定到 Widget 树、自动析构的依赖注入,零 codegen、无全局单例、不绑定响应式方案。

> 📖 English docs: [README.md](README.md)

写过 Android / iOS 的人对这套心智模型很熟:一个绑定到页面的 `ViewModel`,创建时跑 `init()`,页面销毁时自动清理。`store_scope` 把它原样带到 Flutter —— 一个绑定在 Widget 树上的小型 DI 容器 —— 然后就到此为止:它不替你选响应式方案、不生成代码、也绝不把你的对象塞进全局定位器。

```dart
final counterProvider = ViewModelProvider<CounterVm>((space) => CounterVm());

class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
  const CounterPage({super.key});

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    final vm = space.bind(counterProvider); // 在此创建,随该 Widget 一起析构
    return ValueListenableBuilder<int>(
      valueListenable: vm.count,
      builder: (_, value, __) => Text('$value'),
    );
  }
}
```

## 为什么选 store_scope?

大多数 Flutter 状态方案是"全家桶":选了库,就连同它的响应式模型、codegen 或全局状态一起接受。`store_scope` 只把真正难的那块 —— **作用域生命周期 + 依赖注入** —— 单独做好,其余交给你。

| 能力 | store_scope | Riverpod | get_it | provider | GetX |
| --- | :---: | :---: | :---: | :---: | :---: |
| 绑树作用域自动析构 | ✅ | ✅ | ❌ | ⚠️ 手动 | ⚠️ |
| 真正的 DI 容器(可组合依赖) | ✅ | ✅ | ✅ | ❌ 仅按类型 | ✅ 全局 |
| Jetpack 式 `ViewModel`(`init`/`dispose`) | ✅ | ❌ | ❌ | ❌ | ⚠️ controller |
| 带参数族(family) | ✅ `withArgument` | ✅ `family` | ⚠️ 参数 | ❌ | ⚠️ |
| 零 codegen | ✅ | ❌ codegen 为主路径 | ✅ | ✅ | ✅ |
| 响应式无关 | ✅ | ❌ `AsyncValue`/`ref.watch` | ✅ 无 | ❌ `ChangeNotifier` | ❌ `Obx`/Rx |
| 无全局单例 | ✅ | ✅ | ❌ 定位器 | ✅ | ❌ 全局 |
| 测试注入 / override | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |

`store_scope` 是唯一同时满足这些的:绑树自动析构 **+** 真 DI 容器 **+** 熟悉的 ViewModel **+** 零 codegen **+** 响应式无关 **+** 无全局单例。喜欢 signals/bloc/ValueNotifier 的人继续用自己的响应式;原生转 Flutter 的人继续用自己的 ViewModel。

## 安装

```yaml
dependencies:
  store_scope: ^0.3.0
```

## 快速开始

**1. 在根部包一次 `StoreScope`。** 它为其下整棵子树持有一个 `Store`。

```dart
void main() => runApp(const StoreScope(child: MyApp()));
```

**2. 把状态放进 `ViewModel`**(或任意普通类)。响应式由你选 —— 这里用内置的 `ValueNotifier`。

```dart
class CounterVm extends ViewModel {
  final count = ValueNotifier(0);

  @override
  void init() {
    super.init();
    addCloseable(count.dispose); // 自动清理
  }

  void increment() => count.value++;
}
```

**3. 定义 Provider** —— 生命周期在这里一次性声明。

```dart
// 作用域级:最后一个绑定它的 Widget 销毁时自动析构。
final counterProvider = ViewModelProvider<CounterVm>((space) => CounterVm());
```

**4. 绑定到 Widget 的作用域**并响应式读取。

```dart
class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
  const CounterPage({super.key});

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    final vm = space.bind(counterProvider);
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: vm.count,
          builder: (_, value, __) => Text('Count: $value'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

`CounterPage` 离开 Widget 树时,它的作用域消亡,`CounterVm.dispose()` 自动执行,`ValueNotifier` 被关闭 —— 不需要手动清理,也不用在 `State` 里写 `dispose()` 样板。

## 核心概念

### Store 与 StoreScope

`Store` 是一个 DI 容器:provider 到其活跃实例的映射。`StoreScope` Widget 为其子树创建并持有一个 Store;当该 Widget 被移除时,Store **unmount**,它持有的所有实例都被析构。

```dart
StoreScope(child: MyApp());                  // 默认 store
StoreScope(overrides: [...], child: ...);    // 注入测试替身(见"测试")
StoreScope(storeOwner: myOwner, child: ...); // 自定义 store owner
```

在任意后代 context 中读取:

```dart
context.store;          // 最近的 Store(没有则抛错)
context.storeOrNull;    // 或 null
context.storeMounted;   // bool
```

### Provider 与生命周期

**provider** 是创建实例的"配方"。**生命周期是定义时的属性,不是调用点的选择** —— 声明时就定死一次。

```dart
// 作用域级 —— 引用计数,最后一个绑定它的作用域消亡时析构。
final repoProvider = Provider.from((space) => Repository());

// Store 级 —— 惰性单例,活到 StoreScope unmount。
final authProvider = Provider.shared((space) => Auth());
```

| 生命周期 | 定义方式 | 获取方式 |
| --- | --- | --- |
| **页面 / Widget 级** | `Provider.from` | `space.bind(p)` |
| **功能 / 流程级**(跨多个页面) | `Provider.from` | `store.bindWith(p, featureScope)` —— `featureScope` 是你持有的 `DisposeStateNotifier`,流程结束时 `dispose` |
| **App 级** | `Provider.shared` | `store.share(p)` / `context.share(p)` |

`Store.share` 在**编译期**只接受 Store 级 provider(类型限定为 `SharedProvider`),所以你永远不会不带作用域就误读一个作用域级 provider。

### 获取实例:`bind` 与 `share`

```dart
// 作用域级:由 scope 跟踪,最后一个 scope 析构时实例随之析构。
final repo = space.bind(repoProvider);
final repo = store.bindWith(repoProvider, someListenable);

// Store 级:无需作用域。
final auth = store.share(authProvider);
final auth = context.share(authProvider);
```

### 带参数(family)

`Provider.withArgument` 构建一个按参数**值**去重的族(深比较,所以 `List`/`Map`/`Set` 作为参数也能当 key)。`withArgument` ~ `withArgument6` 支持最多 6 个位置参数。

```dart
final userProvider = Provider.withArgument<User, int>(
  (space, id) => User(id),
);

final user = space.bind(userProvider(42)); // 作用域级
```

在定义时加上 **`.asShared`**,这个族就变成 Store 级 —— 每个不同参数一个实例,活到 unmount:

```dart
final userProvider =
    Provider.withArgument<User, int>((space, id) => User(id)).asShared;

final user = store.share(userProvider(42)); // 按 id 去重的单例
// userProvider(42) 与 userProvider(7) 是不同实例。
```

> 一个工厂要么是作用域级(`bind`)、要么是 Store 级(`.asShared`)—— 定义时定死一次,不在调用点混用。

### ViewModel

`ViewModel` 是 Jetpack 风格的状态持有者,带确定性清理。

```dart
class FeedVm extends ViewModel {
  final items = ValueNotifier<List<Item>>([]);
  Timer? _timer;

  @override
  void init() {
    super.init();

    // 自动取消订阅:
    addSubscription(repo.stream.listen(_onData));

    // 注册任意清理回调:
    addCloseable(items.dispose);

    // 带键清理 —— 添加同键会先把旧的清理掉:
    addKeyedCloseable('poll', () => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  @override
  void dispose() {
    // 你自己的清理,然后:
    super.dispose(); // 执行所有 closeable / subscription
  }
}

final feedProvider = ViewModelProvider<FeedVm>((space) => FeedVm());
final appFeedProvider = ViewModelProvider.shared<FeedVm>((space) => FeedVm());
```

`init()` 在创建时执行;`dispose()`(以及所有已注册的 closeable)在绑定作用域消亡或 store unmount 时执行。`ViewModelProvider` 同样支持 `.withArgument*` 和 `.asShared`,与 `Provider` 一致。

### 依赖组合(级联析构)

provider 的 body 会拿到一个 `StoreSpace`,因此可以 `bind` 自己的依赖。子实例被绑到**父实例的作用域**上,于是**它们随父一起析构** —— 组合就是普通 Dart 代码,没有图 DSL,可断点可调试。

```dart
final profileProvider = ViewModelProvider<ProfileVm>((space) {
  final user = space.bind(userProvider(42));     // 子依赖
  final settings = space.bind(settingsProvider); // 子依赖
  return ProfileVm(user, settings);
});
// ProfileVm 析构时,user 与 settings 也一并释放。
```

### Widget 树里的作用域

按你要写的 Widget 类型挑一个入口:

```dart
// StatelessWidget,拿到 StoreSpace:
class A extends StatelessWidget with ScopedSpaceStatelessMixin {
  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) =>
      Text(space.bind(p).label);
}

// StatefulWidget,通过 `space` getter 拿到 StoreSpace:
class B extends StatefulWidget { /* ... */ }
class _BState extends State<B> with ScopedSpaceStateMixin {
  @override
  Widget build(BuildContext context) => Text(space.bind(p).label);
}

// 内联,不新建类:
ScopedBuilder(
  builder: (context, space, child) => Text(space.bind(p).label),
);
```

`ScopedStatelessMixin` / `ScopedStateMixin` 暴露的是裸 `Listenable scope`(而非 `StoreSpace`),配合 `context.store.bindWith(p, scope)` 使用。

**`AutoStoreWidget`** 为自己的子树持有一个**全新的** `Store`(适合自包含的页面或流程):

```dart
class FeaturePage extends AutoStoreWidget {
  const FeaturePage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.share(featureVmProvider); // 活得和本页一样久
    return /* ... */;
  }
}
```

## 响应式由你决定

`store_scope` **不**自带任何响应式。它负责管理*有哪些对象、活多久*;*UI 怎么更新*完全由你选。几个范例:

**ValueNotifier**(内置):

```dart
class CounterVm extends ViewModel {
  final count = ValueNotifier(0);
  @override
  void init() { super.init(); addCloseable(count.dispose); }
}

ValueListenableBuilder<int>(
  valueListenable: space.bind(counterProvider).count,
  builder: (_, value, __) => Text('$value'),
);
```

**signals**([signals.dev](https://pub.dev/packages/signals)):

```dart
class CounterVm extends ViewModel {
  final count = signal(0);
  @override
  void init() { super.init(); addCloseable(count.dispose); }
}

Watch((_) => Text('${space.bind(counterProvider).count.value}'));
```

**flutter_bloc** —— 把 Bloc/Cubit 放进 ViewModel:

```dart
class CounterVm extends ViewModel {
  final cubit = CounterCubit();
  @override
  void init() { super.init(); addCloseable(cubit.close); }
}

BlocBuilder<CounterCubit, int>(
  bloc: space.bind(counterProvider).cubit,
  builder: (_, count) => Text('$count'),
);
```

套路始终一样:把你的响应式原语放进 `ViewModel`,用 `addCloseable` 注册它的清理,`store_scope` 保证它在正确的时机被释放。

## 测试:替换 Provider(override)

在不改动业务代码的前提下,把任意 provider 换成 fake/mock —— Widget 测试用 `StoreScope(overrides: ...)`,纯 Dart 测试用 `StoreImpl(overrides: ...)`。

```dart
final repositoryProvider =
    Provider.shared<Repository>((space) => RealRepository());

testWidgets('使用 fake 数据', (tester) async {
  await tester.pumpWidget(
    StoreScope(
      overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
      child: const MyApp(),
    ),
  );
  // ...
});

test('纯 Dart', () {
  final store = StoreImpl(
    overrides: [repositoryProvider.overrideWith((space) => FakeRepository())],
  );
  expect(store.share(repositoryProvider), isA<FakeRepository>());
});
```

**按意图选:**

| 我想干什么 | 就这么写 |
|---|---|
| 测真实 ViewModel —— 它的行为、`init()`、清理 | 换掉它的**依赖**,别换 ViewModel:<br>`repoProvider.overrideWithValue(FakeRepo())` |
| 往树里塞一个现成的 fake | `vmProvider.overrideWithValue(fake)` |
| fake 需要 `StoreSpace`,或它的初始化都在 `init()` 里 | `vmProvider.overrideWith(`<br>`  (space) => Fake(space)..init(),`<br>`  dispose: (vm) => vm.dispose(),`<br>`)` |

两个入口:

- **`overrideWithValue(fake)`** —— 直接给一个现成实例。注入 mock 的首选。
- **`overrideWith((space) => fake, dispose: ...)`** —— 用工厂替换创建逻辑,fake 因此可以 `space.bind` / `space.share` 自己的依赖(这是 `overrideWithValue` 做不到的)。

### 一条规则,没有例外

**override 交给 Store 的是一个惰性替身。** Store 只在原 provider 被请求的地方把它返回出去,**从不运行它的生命周期** —— 覆盖 `ViewModelProvider` 时,fake 的 `init()` / `dispose()` *不会*被调用。fake 是你造的,就归你管。没有任何开关能改变这一点。

这是刻意的:fake 天生会被复用 —— 在测试顶部 `final` 捕获一次、多个 case 共用、或者工厂在 Store 需要重建实例时再跑一遍。如果容器擅自 dispose 它,下一轮拿到的就是一个死对象,而报错的位置离病根十万八千里。

fake 的钩子真的要跑,自己调就是了。fake 不需要 `StoreSpace` 时,注入前调:

```dart
final fake = FakeUserVm();
fake.init();                 // fake 的 init() 里有初始状态就调
addTearDown(fake.dispose);   // 需要它的清理就调

StoreScope(
  overrides: [userVmProvider.overrideWithValue(fake)],
  child: const MyApp(),
);
```

**如果 fake 的初始化逻辑几乎都在 `init()` 里**(在里面绑依赖、起订阅),那它需要一个活的 `StoreSpace` —— 而 `StoreSpace` 只在工厂里存在。这时把钩子放进工厂:

```dart
StoreScope(
  overrides: [
    userVmProvider.overrideWith(
      (space) => FakeUserVm(space)..init(),  // 这里的 space 是活的
      dispose: (vm) => vm.dispose(),         // Store 会在销毁时执行这个
    ),
  ],
  child: const MyApp(),
);
```

这就是完整的生产生命周期,只不过摊开成两行看得见的代码,而不是藏在容器里。`init()` 里的 `space.bind` 照样挂在实例自己的 scope 上,销毁时正常级联。

代价也留在明处:用这个写法就在工厂里**造新实例**,别返回外面捕获的单例 —— `create` 可能被再次调用(scope 死掉后重新绑定),那样 `init()` 会跑第二遍。

### 想验证**真实**的生命周期

如果你要验的是 `init()` 有没有跑、`addCloseable` / `addSubscription` 有没有真的清理、ViewModel 有没有随作用域消亡 —— **那就根本别 override 这个 ViewModel。** 换掉它绑定的依赖,让真实 VM 跑起来,它走的就是完整的生产路径,钩子一个不落:

```dart
final repoProvider = Provider.shared<Repo>((space) => HttpRepo());

final userVmProvider = ViewModelProvider<UserVm>(
  (space) => UserVm(space.share(repoProvider)),  // 依赖走容器
);

// 只换叶子,保留真实 ViewModel:init() / dispose() 照常执行。
StoreScope(
  overrides: [repoProvider.overrideWithValue(FakeRepo())],
  child: const MyApp(),
);
```

一句话:想把 ViewModel **排除在**测试之外就 override 它;想把 ViewModel **放在**测试之下就 override 它的依赖。

> 带参数的 provider 按**值**匹配:`userProvider(42).overrideWithValue(...)` 只覆盖 `userProvider(42)`,`userProvider(7)` 仍走真实实现。
>
> override 在 Store 创建时读取一次;运行期更换需要给 `StoreScope` 一个新的 `key`(或新的 `storeOwner`)以重建 Store。

## 生命周期速览

- **作用域级**实例按所有绑定它的作用域做引用计数;只有**最后一个**作用域消亡时才析构。
- **Store 级**(`shared`)实例从不绑定 Widget 作用域,活到 `StoreScope` unmount。
- 移除 `StoreScope` 会 unmount 它的 store,并析构**所有**实例 —— shared 和 scoped 都一样。
- `ViewModel.dispose()` 以及所有 `addCloseable` / `addSubscription` / `addKeyedCloseable` 回调都在析构时确定性地执行。
- **由 scope 驱动的**析构是**由内向外**的:绑定 scope 死亡时,实例的依赖级联(创建时 `space.bind` 的所有东西)在它自己的 `dispose()` **之前**就已经释放完。所以别在关闭流程里再去碰绑定的依赖 —— 那时候它已经没了。(`unmount()` 不跑级联,按创建顺序逐个析构,所以那条路径上同样别依赖析构顺序。)
- **override 不在上述规则之内。** 上面说的全都是 Store **自己创建**的实例。注入的 fake 是你创建的,Store 只负责把它返回出去 —— 从不对它调 `init()` 或 `dispose()`。谁创建实例,谁持有它的生命周期(见上文「测试:替换 Provider」一节)。

## API 速查

| | |
| --- | --- |
| `StoreScope({child, overrides, storeOwner})` | 为子树持有一个 `Store` |
| `Provider.from((space) => x)` | 作用域级 provider |
| `Provider.shared((space) => x)` | Store 级 provider |
| `Provider.withArgument<T, A>(...)` | 参数族(`…2`–`…6`) |
| `factory.asShared` | 把参数族变成 Store 级 |
| `ViewModelProvider<T>((space) => vm)` | 作用域级 ViewModel(另有 `.shared`、`.withArgument*`、`.asShared`) |
| `space.bind(p)` | 绑定到当前 space 获取 |
| `store.bindWith(p, listenable)` | 绑定到任意 `Listenable` 获取 |
| `store.share(p)` / `context.share(p)` | 获取 Store 级实例 |
| `p.overrideWithValue(v)` / `p.overrideWith(...)` | 测试替身 |
| `ScopedSpaceStatelessMixin` / `ScopedSpaceStateMixin` | 在 Widget 里拿 `StoreSpace` |
| `ScopedStatelessMixin` / `ScopedStateMixin` | 拿裸 `Listenable scope` |
| `ScopedBuilder` | 内联作用域 builder |
| `AutoStoreWidget` / `AutoStoreStatefulWidget` | 自带独立 store 的 Widget |
| `DisposeStateNotifier` | 可作自定义作用域的可析构 `Listenable` |

## 示例

可运行的 demo 在 [`example/`](example)。覆盖全部功能的真机集成测试在
[`example/integration_test/`](example/integration_test),运行:

```bash
cd example && flutter test integration_test -d <device-id>
```

## 参与贡献

欢迎提 issue 和 PR。本包无 codegen,运行时依赖仅有 Flutter 和 `equatable`;`flutter test` 跑单元测试,`example/` 下的 `flutter test integration_test` 跑真机测试。

## 许可

[MIT](LICENSE)

## 了解更多

- 交互式文档与问答:<https://zread.ai/z-chu/store_scope>
- English docs: [README.md](README.md)
