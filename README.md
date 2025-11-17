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
final counterProvider = Provider.from(
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
    var counter = context.store.shared(counterProvider);
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
    final counter = context.store.shared(counterProvider);
    
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
class Home extends StatelessWidget with ScopedStatelessMixin{

  @override
  Widget build(context) {
    // 在所有绑定的页面销毁时自动释放counter
    var counter = context.store.bindWithScoped(counterProvider,this);
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


class Other extends StatelessWidget with ScopedStatelessMixin{

  @override
  Widget build(context){
    // 在所有绑定的页面销毁时自动释放counter
    final counter = context.bindWithScoped(counterProvider, this);
    
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

## 更多介绍

请查看 https://zread.ai/z-chu/store_scope
