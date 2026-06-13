import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

class _LeakVM extends ViewModel {
  bool closed = false;
  @override
  void init() {
    super.init();
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
}
