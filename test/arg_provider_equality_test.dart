import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

void main() {
  group('Unified arg provider equality (behavior preserved)', () {
    test('deep equality preserved for List arguments (withArgument2)', () {
      final f = Provider.withArgument2(
        (space, List<int> list, int page) => Object(),
      );
      // Different list instances, same content -> equal provider (same key).
      expect(f([1, 2], 0) == f([1, 2], 0), isTrue);
      expect(f([1, 2], 0).hashCode, f([1, 2], 0).hashCode);
      // Different content -> not equal.
      expect(f([1, 2], 0) == f([1, 3], 0), isFalse);
      expect(f([1, 2], 0) == f([1, 2], 1), isFalse);
    });

    test('deep equality preserved for Map arguments (withArgument)', () {
      final f = Provider.withArgument((space, Map<String, int> m) => Object());
      expect(f({'a': 1}) == f({'a': 1}), isTrue);
      expect(f({'a': 1}) == f({'a': 2}), isFalse);
    });

    test('primitive args (withArgument3)', () {
      final f = Provider.withArgument3(
        (space, String a, int b, bool c) => Object(),
      );
      expect(f('x', 1, true) == f('x', 1, true), isTrue);
      expect(f('x', 1, true) == f('x', 1, false), isFalse);
    });

    test('different factories with identical args are NOT equal', () {
      final f1 = Provider.withArgument2((space, int a, int b) => Object());
      final f2 = Provider.withArgument2((space, int a, int b) => Object());
      expect(f1(1, 2) == f2(1, 2), isFalse);
    });

    test('records style via single-arg withArgument still works', () {
      final f = Provider.withArgument<Object, (String, int)>(
        (space, args) => Object(),
      );
      expect(f(('x', 1)) == f(('x', 1)), isTrue);
      expect(f(('x', 1)) == f(('x', 2)), isFalse);
    });

    test('custom equatableProps is honored', () {
      // Only the first field participates in identity.
      final f = Provider.withArgument2(
        (space, String id, int ignored) => Object(),
        equatableProps: (id, ignored) => [id],
      );
      expect(f('a', 1) == f('a', 999), isTrue);
      expect(f('a', 1) == f('b', 1), isFalse);
    });

    test('store caches one instance for equal (deep) args', () {
      final store = StoreImpl();
      final f = Provider.withArgument2(
        (space, List<int> list, int page) => Object(),
      );
      final scope = DisposeStateNotifier();
      final a = store.bindWith(f([1, 2], 0), scope);
      final b = store.bindWith(f([1, 2], 0), scope); // different list instance
      expect(identical(a, b), isTrue);
    });

    test(
      'mutating a collection arg after binding does not corrupt the store',
      () {
        // The cache key is deep-frozen at construction, so mutating the caller's
        // collection afterwards must not change the provider's hashCode and
        // orphan its entry in the store's maps.
        final store = StoreImpl();
        var disposed = 0;
        final f = Provider.withArgument(
          (space, List<int> ids) => Object(),
          disposer: (_) => disposed++,
        );
        final key = [1, 2];
        final scope = DisposeStateNotifier();
        final p = f(key);
        final a = store.bindWith(p, scope);

        key.add(3); // mutate the caller's collection AFTER binding

        expect(store.exists(p), isTrue, reason: 'entry not orphaned');
        expect(
          identical(store.bindWith(f([1, 2]), scope), a),
          isTrue,
          reason: 'equal (original) args still resolve to the cached instance',
        );

        scope.dispose();
        expect(store.exists(p), isFalse, reason: 'unbind succeeded');
        expect(disposed, 1);
      },
    );

    test('ViewModelProvider.withArgument2 preserves List deep equality', () {
      final f = ViewModelProvider.withArgument2(
        (space, List<int> list, int page) => _ArgVm(),
      );
      expect(f([1, 2], 0) == f([1, 2], 0), isTrue);
      expect(f([1, 2], 0) == f([9, 9], 0), isFalse);
    });
  });
}

class _ArgVm extends ViewModel {}
