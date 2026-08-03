import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

/// Registers a subscription from *outside* [init] — the shape of a load that
/// only completes after the ViewModel is already gone.
class _LateSubscriptionVM extends ViewModel {
  final controller = StreamController<int>();

  void subscribeNow() => addSubscription(controller.stream.listen((_) {}));
}

/// A ViewModel whose [init] binds a dependency and *then* fails.
class _InitFailsVM extends ViewModel {
  _InitFailsVM(this._space, this._dep);

  final StoreSpace _space;
  final ProviderBase<Object> _dep;

  @override
  void init() {
    _space.bind(_dep); // the child is now registered in the store...
    throw StateError('init failed'); // ...and init dies before create() returns
  }
}

class _LeakVM extends ViewModel {
  bool closed = false;
  bool inited = false;
  @override
  void init() {
    super.init();
    inited = true;
    addCloseable(() => closed = true);
  }
}

class _ReentrantVM extends ViewModel {
  @override
  void init() {
    super.init();
    // 在 dispose 期间再注册 closeable,触发重入路径。
    addCloseable(() {
      addCloseable(() {});
      addKeyedCloseable('k', () {});
    });
  }
}

class _ThrowingCleanupVM extends ViewModel {
  bool laterCleanupRan = false;
  bool keyedCleanupRan = false;

  @override
  void init() {
    super.init();
    addCloseable(() => throw StateError('boom'));
    addCloseable(() => laterCleanupRan = true);
    addKeyedCloseable('k', () => keyedCleanupRan = true);
  }
}

class _MultiFailureVM extends ViewModel {
  @override
  void init() {
    super.init();
    addCloseable(() => throw StateError('first'));
    addCloseable(() => throw StateError('second'));
  }
}

class _KeyedVM extends ViewModel {
  bool replacementRan = false;

  void reg(String key, VoidCallback closeable) =>
      addKeyedCloseable(key, closeable);

  void markReplacementRan() => replacementRan = true;
}

void main() {
  group('Store / ViewModel lifecycle regressions', () {
    // 回归:一个抛异常的 closeable 曾直接从 dispose() 的循环里逃出去,导致
    // 后续所有 closeable、_keyToCloseables 整个循环、以及 super.dispose()
    // 全部被跳过 —— notifier 带着 listener 泄漏。析构必须先跑完再报错。
    test('a throwing closeable does not abort the rest of the teardown', () {
      final vm = _ThrowingCleanupVM()..init();

      // 失败仍然被上报,而且抛的是 closeable 原本抛的那个错(带原始堆栈),
      // 不是包了一层字符串的 Exception。
      expect(vm.dispose, throwsStateError);

      expect(vm.laterCleanupRan, isTrue, reason: '后面的 closeable 照样执行');
      expect(vm.keyedCleanupRan, isTrue, reason: 'keyed closeable 照样执行');
      expect(vm.disposed, isTrue);
      expect(
        () => vm.addListener(() {}),
        throwsFlutterError,
        reason: 'super.dispose() 已经跑过,notifier 不再泄漏',
      );
    });

    // 多个 closeable 同时失败时,只有一个能被抛出 —— 其余的必须各自成为一条
    // 日志,而不是被 join 成一坨(那样会埋掉除第一条以外的所有失败,也会破坏
    // 按行解析的日志管道)。
    test('every cleanup failure is reported, one entry each', () {
      final logged = <String>[];
      final oldLog = StoreScopeConfig.log;
      final oldThrow = StoreScopeConfig.throwOnCloseError;
      StoreScopeConfig.log = (text, {bool isError = false}) => logged.add(text);
      StoreScopeConfig.throwOnCloseError = false;
      addTearDown(() {
        StoreScopeConfig.log = oldLog;
        StoreScopeConfig.throwOnCloseError = oldThrow;
      });

      final vm = _MultiFailureVM()..init();
      expect(vm.dispose, returnsNormally);

      expect(logged, hasLength(2), reason: '两条失败 = 两条日志');
      expect(logged.where((t) => t.contains('first')), hasLength(1));
      expect(logged.where((t) => t.contains('second')), hasLength(1));
    });

    // throwOnCloseError 打开时抛第一条,但剩下的不能凭空消失。
    test('with throwOnCloseError, later failures are still logged', () {
      final logged = <String>[];
      final oldLog = StoreScopeConfig.log;
      StoreScopeConfig.log = (text, {bool isError = false}) => logged.add(text);
      addTearDown(() => StoreScopeConfig.log = oldLog);

      final vm = _MultiFailureVM()..init();
      expect(
        vm.dispose,
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'first')),
        reason: '抛的是第一条失败的原始错误',
      );
      expect(logged.where((t) => t.contains('second')), hasLength(1));
    });

    // 回归:StoreImpl._disposeProviderInstance 的 try/catch 曾把析构期的任何
    // 异常收成一行 log —— 这个库唯一的承诺出问题时完全不可见。
    test('the store reports a disposer failure instead of swallowing it', () {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      final store = StoreImpl();
      final p = ViewModelProvider<_ThrowingCleanupVM>(
        (s) => _ThrowingCleanupVM(),
      );
      final vm = store.bindWith(p, DisposeStateNotifier());

      store.unmount(); // 不抛,teardown 不能被一个坏 disposer 打断

      expect(vm.laterCleanupRan, isTrue);
      expect(errors, hasLength(1), reason: '失败被上报了一次');
      expect(errors.single.library, 'store_scope');
      expect('${errors.single.exception}', contains('boom'));
    });

    // 一个实例的 disposer 出错,不能连累 store 里其它实例的析构。
    //
    // 注意 onError 故意设成「重抛」:这是 app 层和 CI 里都很常见的写法,
    // 也是唯一能打穿这条保证的配置。改用 `(_) {}` 的话这条测试是空转的
    // —— 上报还写在 catch 块内部时它照样通过。
    test('one failing disposer does not strand the other instances', () {
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => throw details.exception;
      addTearDown(() => FlutterError.onError = previous);

      final store = StoreImpl();
      final bad = ViewModelProvider<_ThrowingCleanupVM>(
        (s) => _ThrowingCleanupVM(),
      );
      final good = ViewModelProvider<_LeakVM>((s) => _LeakVM());
      store.bindWith(bad, DisposeStateNotifier());
      final goodVm = store.bindWith(good, DisposeStateNotifier());

      expect(store.unmount, returnsNormally, reason: '上报不能打断 teardown');
      expect(goodVm.closed, isTrue, reason: '后面的实例照样被析构');
    });

    // 回归:closeable 抛出的失败在 super.dispose() 之后才上报,那一抛曾把
    // ViewModelProviderBase.disposeInstance 打断,provider 自己的 disposer:
    // 因此永远不执行 —— 于是「teardown 跑完」实际上取决于 throwOnCloseError。
    test('a throwing closeable does not skip the provider disposer', () {
      final previous = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = previous);

      var disposerRan = false;
      final store = StoreImpl();
      final p = ViewModelProvider<_ThrowingCleanupVM>(
        (s) => _ThrowingCleanupVM(),
        disposer: (_) => disposerRan = true,
      );
      final scope = DisposeStateNotifier();
      store.bindWith(p, scope);

      scope.dispose();
      expect(disposerRan, isTrue, reason: 'disposer: 不能被 closeable 的失败吃掉');
    });

    // 反过来也要成立:让 disposer: 也抛,ViewModel 自己的清理失败(信息量更大
    // 的那个)不能被它顶掉。一个 try/finally 会正好造成这个后果 —— finally 里
    // 抛出的异常会替换掉待抛的异常。
    test('a failing disposer does not mask the cleanup failure behind it', () {
      final reported = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = previous);

      final store = StoreImpl();
      final p = ViewModelProvider<_ThrowingCleanupVM>(
        (s) => _ThrowingCleanupVM(),
        disposer: (_) => throw ArgumentError('disposer down'),
      );
      final scope = DisposeStateNotifier();
      store.bindWith(p, scope);

      scope.dispose();
      expect(reported, hasLength(1));
      expect(
        '${reported.single.exception}',
        contains('boom'),
        reason: 'closeable 的原始失败才是要上报的那个',
      );
    });

    // 回归:同 key 覆盖时旧 closeable 是裸调用 —— 一抛异常就直接穿到调用
    // addKeyedCloseable 的业务代码里,而且新回调根本没进表(资源永远不释放),
    // 旧回调还赖在表里,dispose() 时再抛一次。
    test('a throwing keyed closeable does not swallow its replacement', () {
      final previous = FlutterError.onError;
      FlutterError.onError = (_) {};
      addTearDown(() => FlutterError.onError = previous);

      final old = StoreScopeConfig.throwOnCloseError;
      StoreScopeConfig.throwOnCloseError = false; // 失败按配置降级成日志
      addTearDown(() => StoreScopeConfig.throwOnCloseError = old);

      final vm = _KeyedVM();
      vm.reg('k', () => throw StateError('old boom'));

      expect(
        () => vm.reg('k', vm.markReplacementRan),
        returnsNormally,
        reason: '旧回调的失败走 StoreScopeConfig,不再是裸抛',
      );

      vm.dispose();
      expect(vm.replacementRan, isTrue, reason: '新回调必须已经登记并执行');
    });

    // 同一个修复的另一半:throwOnCloseError 是 debug 默认值时,旧回调的失败
    // 仍然会按配置抛给调用方 —— 但登记已经先发生了,所以新回调不会丢,旧回调
    // 也已经出表,dispose() 不会再抛第二次。
    test('...and the replacement survives even when the failure is thrown', () {
      expect(StoreScopeConfig.throwOnCloseError, isTrue, reason: 'debug 默认值');

      final vm = _KeyedVM();
      vm.reg('k', () => throw StateError('old boom'));

      expect(() => vm.reg('k', vm.markReplacementRan), throwsStateError);

      expect(vm.dispose, returnsNormally, reason: '旧回调已经出表,不会再抛一次');
      expect(vm.replacementRan, isTrue, reason: '新回调仍然登记成功并执行');
    });

    // 回归:unmount() 之前会把 _mounted 置 false,曾导致 Provider.dispose 的
    // mounted 守卫吞掉 disposeInstance,所有 ViewModel 都不被析构(资源泄漏)。
    test('unmount() disposes bound ViewModels (runs closeables)', () {
      final store = StoreImpl();
      final p = ViewModelProvider<_LeakVM>((s) => _LeakVM());
      final vm = store.bindWith(p, DisposeStateNotifier());
      expect(vm.closed, isFalse);
      store.unmount();
      expect(vm.closed, isTrue);
    });

    test('normal scope disposal runs closeables (control)', () {
      final store = StoreImpl();
      final p = ViewModelProvider<_LeakVM>((s) => _LeakVM());
      final notifier = DisposeStateNotifier();
      final vm = store.bindWith(p, notifier);
      notifier.dispose();
      expect(vm.closed, isTrue);
    });

    // 回归:DisposeStateNotifier.dispose() 曾无条件调用 super.dispose(),
    // 于是第二次调用在 debug 下触发 ChangeNotifier 断言、在 release 下静默通过。
    // 防御性的重复 teardown(拥有者自己 dispose 一次、别处已经释放过一次)
    // 因此只在开发期崩。
    test('DisposeStateNotifier.dispose() is idempotent', () {
      var notifications = 0;
      final notifier =
          DisposeStateNotifier()..addListener(() => notifications++);

      notifier.dispose();
      expect(notifier.disposed, isTrue);
      expect(notifications, 1);

      expect(notifier.dispose, returnsNormally, reason: '第二次是 no-op');
      expect(notifier.dispose, returnsNormally);
      expect(notifications, 1, reason: '通知恰好一次');
    });

    // `returnsNormally` alone is NOT enough here: ChangeNotifier.notifyListeners
    // catches whatever a listener throws and routes it to FlutterError.onError,
    // so the old "dispose() called during notifyListeners()" assertion never
    // reached the caller — a plain `test()` just printed it. The only way to
    // observe the bug is to watch that channel.
    test('a listener that re-disposes the scope does not assert', () {
      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      addTearDown(() => FlutterError.onError = previous);

      late final DisposeStateNotifier notifier;
      notifier = DisposeStateNotifier()..addListener(() => notifier.dispose());

      expect(notifier.dispose, returnsNormally);
      expect(errors, isEmpty, reason: '重入的 dispose 不该触发任何断言');
    });

    // 回归:_getOrCreateInstance 曾用 `instance == null` 判断有没有缓存,于是
    // T 可空、创建结果恰好是 null 的 provider 每次访问都重建 —— 每次都新建一个
    // instance scope,而 scope manager 按实例 identity 存,全部 null 互相覆盖,
    // 先前的 scope 再没人 dispose(级联泄漏),引用计数也跟着错。
    test('a provider whose value is null is created exactly once', () {
      var creates = 0;
      final nullable = Provider.from<String?>((space) {
        creates++;
        return null;
      });
      final store = StoreImpl();
      final scope = DisposeStateNotifier();

      store.bindWith(nullable, scope);
      store.bindWith(nullable, scope);
      store.bindWith(nullable, DisposeStateNotifier());
      expect(creates, 1);
      expect(store.exists(nullable), isTrue);
    });

    // 同一个 bug 的另一面,也是它真正的代价:重建实例意味着每次都新建一个
    // instance scope,而 scope manager 按 key 存,只有最后一个留得下来 ——
    // 于是 creator 里 space.bind 的子实例攒了 N 个 watcher,却只有 1 个会被
    // 释放,级联永远走不完。只断言 disposals==1 抓不到这一点(重建时旧实例
    // 恰好也是 null,disposer 照样只跑一次)。
    test(
      'a null-valued instance is disposed once, and its cascade with it',
      () {
        var disposals = 0;
        var childDisposals = 0;
        final child = Provider.from<Object>(
          (space) => Object(),
          disposer: (_) => childDisposals++,
        );
        final nullable = Provider.from<String?>((space) {
          space.bind(child);
          return null;
        }, disposer: (_) => disposals++);
        final store = StoreImpl();
        final first = DisposeStateNotifier();
        final second = DisposeStateNotifier();
        store.bindWith(nullable, first);
        store.bindWith(nullable, second);

        first.dispose();
        expect(disposals, 0, reason: '还有一个 scope 持有它');
        expect(childDisposals, 0);

        second.dispose();
        expect(disposals, 1);
        expect(childDisposals, 1, reason: '依赖级联必须跟着释放');
        expect(store.exists(nullable), isFalse);
        expect(store.exists(child), isFalse);
      },
    );

    // 回归:instance scope 曾按「实例 identity」存,而 Dart 会规范化字面量,
    // 于是两个各自返回 42 的普通 provider 撞成同一个 key —— 后注册的覆盖先注册
    // 的,销毁 A 会释放 B 的依赖级联(B 还活着),而 A 自己的级联永远没人释放。
    test('two providers yielding the same value keep separate cascades', () {
      var childA = false;
      var childB = false;
      final depA = Provider.from<Object>(
        (s) => Object(),
        disposer: (_) => childA = true,
      );
      final depB = Provider.from<Object>(
        (s) => Object(),
        disposer: (_) => childB = true,
      );
      // 两个毫不相干的 provider,只是恰好都返回 42(int 是规范化的)。
      final a = Provider.from<int>((s) {
        s.bind(depA);
        return 42;
      });
      final b = Provider.from<int>((s) {
        s.bind(depB);
        return 42;
      });

      final store = StoreImpl();
      final scopeA = DisposeStateNotifier();
      final scopeB = DisposeStateNotifier();
      store.bindWith(a, scopeA);
      store.bindWith(b, scopeB);

      scopeA.dispose();
      expect(childA, isTrue, reason: 'A 自己的依赖被释放');
      expect(childB, isFalse, reason: 'B 还活着,它的依赖不能被连累');

      scopeB.dispose();
      expect(childB, isTrue);
    });

    // 同一个族的 scoped 成员和 .asShared 成员相等(shared 包装把相等性转发给
    // delegate),但在同一个 store 里是两个不同的实例 —— 所以只按 provider 做
    // key 同样不行,必须 (provider, instance) 成对。
    test(
      'scoped and .asShared members of one family keep separate cascades',
      () {
        var scopedChild = false;
        var sharedChild = false;
        final depScoped = Provider.from<Object>(
          (s) => Object(),
          disposer: (_) => scopedChild = true,
        );
        final depShared = Provider.from<Object>(
          (s) => Object(),
          disposer: (_) => sharedChild = true,
        );
        var call = 0;
        final family = Provider.withArgument<Object, int>((s, id) {
          // 第一次解析绑 depScoped,第二次绑 depShared,便于分辨两条级联。
          s.bind(call++ == 0 ? depScoped : depShared);
          return Object();
        });

        final store = StoreImpl();
        final scope = DisposeStateNotifier();
        store.bindWith(family(42), scope); // scoped 成员
        store.share(family.asShared(42)); // shared 成员,同一个 arg

        scope.dispose();
        expect(scopedChild, isTrue, reason: 'scoped 成员的级联被释放');
        expect(sharedChild, isFalse, reason: 'shared 成员还活着');

        store.unmount();
        expect(sharedChild, isTrue);
      },
    );

    // 回归:dispose() 曾在迭代 _closeables 时被重入的 addCloseable 修改集合,
    // 抛 ConcurrentModificationError。
    test('re-entrant addCloseable during dispose does not throw', () {
      final vm = _ReentrantVM()..init();
      expect(vm.dispose, returnsNormally);
    });

    // 回归:_storeOwner 曾是 late final,didUpdateWidget 重新赋值抛
    // LateInitializationError。
    testWidgets('swapping storeOwner does not crash', (tester) async {
      await tester.pumpWidget(
        StoreScope(
          storeOwner: StoreOwnerImpl(StoreImpl()),
          child: const SizedBox(),
        ),
      );
      await tester.pumpWidget(
        StoreScope(
          storeOwner: StoreOwnerImpl(StoreImpl()),
          child: const SizedBox(),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SharedProvider lifetime', () {
    test('singleton; survives scope death; disposed at unmount', () {
      final store = StoreImpl();
      final p = ViewModelProvider.shared((s) => _LeakVM());
      final a = store.share(p);
      expect(identical(store.share(p), a), isTrue); // singleton

      // bindWith on a shared provider ignores the passed scope.
      final scope = DisposeStateNotifier();
      expect(identical(store.bindWith(p, scope), a), isTrue);
      scope.dispose();
      expect(a.closed, isFalse); // survives scope death
      expect(store.exists(p), isTrue);

      store.unmount();
      expect(a.closed, isTrue); // disposed at unmount
    });
  });

  group('shared argument providers (asShared)', () {
    test('per-argument singleton, keyed by value equality', () {
      final store = StoreImpl();
      var created = 0;
      final p =
          Provider.withArgument<int, int>((s, id) {
            created++;
            return id * 10;
          }).asShared;

      final a = store.share(p(1));
      expect(store.share(p(1)), a); // same arg -> cached, not recreated
      expect(created, 1);

      expect(
        store.share(p(2)),
        isNot(a),
      ); // different arg -> different instance
      expect(created, 2);
    });

    test('shared arg provider survives scope death; disposed at unmount', () {
      final store = StoreImpl();
      var disposed = 0;
      final p =
          Provider.withArgument<int, int>(
            (s, id) => id,
            disposer: (_) => disposed++,
          ).asShared;

      // bindWith on a shared provider ignores the passed scope.
      final scope = DisposeStateNotifier();
      final v = store.bindWith(p(7), scope);
      scope.dispose();
      expect(disposed, 0); // not tied to the scope
      expect(store.share(p(7)), v); // still cached after the scope died

      store.unmount();
      expect(disposed, 1); // disposed at unmount
    });

    test(
      'ViewModel.withArgument(...).asShared runs init and is a singleton',
      () {
        final store = StoreImpl();
        final p =
            ViewModelProvider.withArgument<_LeakVM, int>(
              (s, id) => _LeakVM(),
            ).asShared;

        final vm = store.share(p(1));
        expect(identical(store.share(p(1)), vm), isTrue); // singleton
        expect(vm.inited, isTrue); // init() ran (unlike an overridden provider)

        store.unmount();
        expect(vm.closed, isTrue); // disposed at unmount
      },
    );
  });

  // The headline feature: a provider's creator can `space.bind` a child, which
  // is tied to the parent instance's own scope and disposed together with it —
  // previously only covered by the on-device integration test.
  group('per-instance scope cascade', () {
    test('child bound inside a creator is disposed with its parent', () {
      final store = StoreImpl();
      var childDisposed = false;
      var parentDisposed = false;
      final childProvider = Provider.from(
        (space) => Object(),
        disposer: (_) => childDisposed = true,
      );
      final parentProvider = Provider.from((space) {
        space.bind(childProvider); // child tied to the parent's own scope
        return Object();
      }, disposer: (_) => parentDisposed = true);

      final scope = DisposeStateNotifier();
      store.bindWith(parentProvider, scope);
      expect(store.exists(parentProvider), isTrue);
      expect(store.exists(childProvider), isTrue);

      scope.dispose();
      expect(parentDisposed, isTrue);
      expect(childDisposed, isTrue, reason: 'child cascades with parent');
      expect(store.exists(childProvider), isFalse);
    });

    test('cascade also fires on store.unmount()', () {
      final store = StoreImpl();
      var childDisposed = false;
      final childProvider = Provider.from(
        (space) => Object(),
        disposer: (_) => childDisposed = true,
      );
      final parentProvider = Provider.from((space) {
        space.bind(childProvider);
        return Object();
      });
      store.bindWith(parentProvider, DisposeStateNotifier());
      expect(store.exists(childProvider), isTrue);

      store.unmount();
      expect(childDisposed, isTrue);
    });

    test('a child shared by two parents lives until the last parent dies', () {
      final store = StoreImpl();
      var childDisposed = 0;
      final childProvider = Provider.from(
        (space) => Object(),
        disposer: (_) => childDisposed++,
      );
      final parentA = Provider.from((space) {
        space.bind(childProvider);
        return Object();
      });
      final parentB = Provider.from((space) {
        space.bind(childProvider);
        return Object();
      });

      final scopeA = DisposeStateNotifier();
      final scopeB = DisposeStateNotifier();
      store.bindWith(parentA, scopeA);
      store.bindWith(parentB, scopeB);
      expect(store.exists(childProvider), isTrue);

      scopeA.dispose(); // parentA gone, but parentB still references the child
      expect(childDisposed, 0, reason: 'still referenced by parentB');
      expect(store.exists(childProvider), isTrue);

      scopeB.dispose(); // last parent gone
      expect(childDisposed, 1);
      expect(store.exists(childProvider), isFalse);
    });

    // 回归:addSubscription 没有 disposed 守卫,而它文档声称等价于
    // addCloseable(subscription.cancel) —— addCloseable 在已析构时会立即关闭,
    // addSubscription 却把闭包塞进再也不会被 drain 的 _closeables。晚完成的
    // 异步加载在 VM 死后订阅,于是订阅永不取消、继续 fire、还拽着 VM 不放。
    test('addSubscription after dispose cancels immediately', () {
      final vm = _LateSubscriptionVM()..init();
      addTearDown(vm.controller.close);
      vm.dispose();

      vm.subscribeNow();

      expect(vm.controller.hasListener, isFalse, reason: '已析构的 VM 不能留下活订阅');
    });

    // 回归:Provider.create 里 createInstance 抛异常时,onInstanceCreated 永远
    // 不执行 —— 这个实例的 scope 从没进过 _InstanceScopeManager,而 creator 已经
    // space.bind 上去的子实例就挂在那个 scope 上。子实例留在 _instances 里,
    // 直到 unmount 都不会被 dispose。
    test('a creator that throws after space.bind releases the child', () {
      var childDisposed = 0;
      final child = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => childDisposed++,
      );
      final parent = Provider.from<Object>((space) {
        space.bind(child);
        throw StateError('creator failed');
      });

      final store = StoreImpl();
      expect(
        () => store.bindWith(parent, DisposeStateNotifier()),
        throwsStateError,
        reason: '异常照常抛给调用方,行为不变',
      );

      expect(childDisposed, 1, reason: '半成品级联必须被收干净');
      expect(store.exists(child), isFalse);
    });

    // 同一个洞的 ViewModel 版本:init() 里 space.bind 之后再抛。
    test('a ViewModel whose init() throws releases its cascade', () {
      var childDisposed = 0;
      final child = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => childDisposed++,
      );
      final p = ViewModelProvider<_InitFailsVM>(
        (space) => _InitFailsVM(space, child),
      );

      final store = StoreImpl();
      expect(() => store.bindWith(p, DisposeStateNotifier()), throwsStateError);

      expect(childDisposed, 1);
      expect(store.exists(child), isFalse);
    });

    // 真正的代价不是单次泄漏,而是累积:每次失败的创建都新建一个 scope 并把它
    // 加进 _scopeWatchers[child],creator 一抛这个 scope 就再没人持有、永远不会
    // 被 dispose,于是 child 的引用计数每重试一次就永久 +1。widget 反复重建重试
    // 一个必然失败的 bind,这张表会无界增长。
    test('repeated failed creation does not accumulate child watchers', () {
      var childCreated = 0;
      var childDisposed = 0;
      final child = Provider.from<Object>((space) {
        childCreated++;
        return Object();
      }, disposer: (_) => childDisposed++);
      final parent = Provider.from<Object>((space) {
        space.bind(child);
        throw StateError('creator failed');
      });

      final store = StoreImpl();
      final scope = DisposeStateNotifier();
      for (var i = 0; i < 3; i++) {
        expect(() => store.bindWith(parent, scope), throwsStateError);
        expect(
          store.exists(child),
          isFalse,
          reason: '第 $i 次失败后 child 就该已经释放,而不是攒着',
        );
      }

      expect(childCreated, 3);
      expect(childDisposed, 3, reason: '每次失败各自配平,没有残留 watcher');
    });

    // 收拾半成品级联的那次 scope.dispose() 位于 catch 里、rethrow 之前 ——
    // 它一旦自己抛出,就会顶替掉 creator 的原始异常,调用方看到的是「清理时
    // 的次生错误」而不是「creator 为什么失败」。onError 设成重抛是唯一能让
    // 子实例的 disposer 失败escape出 notifyListeners 的配置。
    test('cleanup of a failed creation never masks the creator error', () {
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => throw details.exception;
      addTearDown(() => FlutterError.onError = previous);

      final child = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => throw ArgumentError('child teardown blew up'),
      );
      final parent = Provider.from<Object>((space) {
        space.bind(child);
        throw StateError('the real reason');
      });

      final store = StoreImpl();
      expect(
        () => store.bindWith(parent, DisposeStateNotifier()),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'the real reason',
          ),
        ),
        reason: '调用方必须看到 creator 的原始失败',
      );
    });
  });
}
