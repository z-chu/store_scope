import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

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

void main() {
  group('Store / ViewModel lifecycle regressions', () {
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
  });
}
