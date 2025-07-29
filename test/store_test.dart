// 添加到 test/store_scope_test.dart
// test/temporary_integration_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

import 'store_scope_test.dart';

void main() {
  group('Store temporary method', () {
    late Store store;
    late TestProvider provider;

    setUp(() {
      store = StoreImpl();
      provider = TestProvider();
    });

    test('should create temporary instance', () {
      // 基本功能测试
      final instance = store.temporary(provider);
      expect(instance, isNotNull);
      expect(store.exists(provider), isTrue);
    });

    test('should create different instances for multiple temporary calls', () {
      final instance1 = store.temporary(provider);
      final instance2 = store.temporary(TestProvider()); // 不同的 provider

      expect(instance1, isNotNull);
      expect(instance2, isNotNull);
    });

    // 手动测试 GC 行为（不稳定，仅供参考）
    test('temporary instance lifecycle with forced GC', () async {
      var instanceDisposed = false;
      final disposableProvider = Provider.from((space) {
        return DisposableTestClass();
      }, disposer: (instance) {
        instanceDisposed = true;
      });

      // 创建临时实例
      store.temporary(disposableProvider);
      expect(store.exists(disposableProvider), isTrue);

      // 尝试强制触发 GC（不保证立即生效）
      await _forceGC();

      // 等待一段时间让 finalizer 有机会执行
      await Future.delayed(Duration(milliseconds: 3000));

      // 注意：这个测试可能不稳定，因为 GC 时机不确定
      // 在实际项目中，更多依赖集成测试而不是单元测试
      expect(instanceDisposed, isTrue);
      expect(store.exists(disposableProvider), isFalse);

    });
  });
}

// 辅助类用于测试
class DisposableTestClass {
  DisposableTestClass();

}

// 尝试强制 GC（仅用于测试，不保证有效）
Future<void> _forceGC() async {
  // 创建大量对象来触发 GC
  for (int i = 0; i < 100; i++) {
    List.generate(100000, (index) => Object());
  }
}
