<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# StoreScope

一个轻量级的 Flutter 状态管理库，专注于提供简洁的状态生命周期管理和局部状态管理。

## 特性

- 🚀 简洁的状态生命周期管理
- 🔄 基于 Widget 树的局部状态管理
- 🔗 支持状态之间的相互依赖
- 🧹 自动管理状态的生命周期和资源释放
- 🎯 专注于状态管理，不包含响应式机制

## 快速开始


1. 在应用的根 Widget 中添加 StoreScope:

```dart
void main() {
  runApp(
    StoreScope(
      child: MyApp(),
    ),
  );
}
```

2. 创建简单的状态类:

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

3. 创建 Provider:

```dart
// 创建一个可绑定的 Provider，用于管理 Counter 实例
final counterProvider = Provider.bindable(
  (space) => Counter(),
);
```


4. 在页面中使用响应式状态:

#### 方式一：使用 shared（全局状态）

```dart
class Home extends StatelessWidget {

  @override
  Widget build(context) {
    // 使用 shared 方法会让 counter 一直存在于内存中，直到 StoreScope 被移除
    var counter = context.shared(counterProvider);
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
    final counter = context.shared(counterProvider);
    
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
class Home extends StatelessWidget with DisposeStateAwareStatelessMixin{

  @override
  Widget build(context) {
    // 使用 bind 方法获取状态，该状态会在所有绑定的页面销毁时自动释放
    var counter = context.bindWith(counterProvider,this);
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


class Other extends StatelessWidget with DisposeStateAwareStatelessMixin{

  @override
  Widget build(context){
    // bind方法会在所有绑定的页面销毁时自动释放counter
    final counter = context.bindWith(counterProvider, this);
    
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




## StoreScope 的使用场景

1. 页面级 StoreScope
   - 每个页面都应该有自己的 StoreScope
   - 用于管理页面内的局部状态
   - 页面销毁时自动清理相关资源

2. 应用级 StoreScope
   - 在应用的根 Widget 中使用
   - 用于管理跨页面共享的状态
   - 只有当多个页面需要共享同一个状态时才使用

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

