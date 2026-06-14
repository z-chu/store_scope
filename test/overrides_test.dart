import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

abstract class Greeter {
  String hello();
}

class RealGreeter implements Greeter {
  @override
  String hello() => 'real';
}

class FakeGreeter implements Greeter {
  @override
  String hello() => 'fake';
}

class CountVm extends ViewModel {
  bool inited = false;

  @override
  void init() => inited = true;
}

final greeterProvider = Provider.shared<Greeter>((space) => RealGreeter());

void main() {
  group('overrides', () {
    test('overrideWithValue substitutes the instance (pure Dart)', () {
      final store = StoreImpl(
        overrides: [greeterProvider.overrideWithValue(FakeGreeter())],
      );
      expect(store.share(greeterProvider).hello(), 'fake');
    });

    test('overrideWith replaces creation', () {
      final store = StoreImpl(
        overrides: [greeterProvider.overrideWith((space) => FakeGreeter())],
      );
      expect(store.share(greeterProvider).hello(), 'fake');
    });

    test('no override -> the real provider is used', () {
      final store = StoreImpl();
      expect(store.share(greeterProvider).hello(), 'real');
    });

    test('duplicate override targets throw (debug assert)', () {
      expect(
        () => StoreImpl(
          overrides: [
            greeterProvider.overrideWithValue(FakeGreeter()),
            greeterProvider.overrideWithValue(RealGreeter()),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('overrideWithValue is NOT disposed by the store', () {
      var realDisposed = false;
      final p = Provider.from<Greeter>(
        (space) => RealGreeter(),
        disposer: (_) => realDisposed = true,
      );
      final store = StoreImpl(overrides: [p.overrideWithValue(FakeGreeter())]);
      final scope = DisposeStateNotifier();
      store.bindWith(p, scope);
      scope.dispose(); // would dispose a real scoped instance
      expect(realDisposed, isFalse);
    });

    test('overrideWith dispose callback runs on scope teardown', () {
      var fakeDisposed = false;
      final p = Provider.from<Greeter>((space) => RealGreeter());
      final store = StoreImpl(
        overrides: [
          p.overrideWith(
            (space) => FakeGreeter(),
            dispose: (_) => fakeDisposed = true,
          ),
        ],
      );
      final scope = DisposeStateNotifier();
      store.bindWith(p, scope);
      scope.dispose();
      expect(fakeDisposed, isTrue);
    });

    test('overrideWith dispose runs on store.unmount()', () {
      var fakeDisposed = false;
      final p = Provider.shared<Greeter>((space) => RealGreeter());
      final store = StoreImpl(
        overrides: [
          p.overrideWith(
            (space) => FakeGreeter(),
            dispose: (_) => fakeDisposed = true,
          ),
        ],
      );
      store.share(p); // create the overridden instance
      store.unmount();
      expect(fakeDisposed, isTrue);
    });

    test('override matches an arg provider by its equatable key', () {
      final greeterFactory = Provider.withArgument<Greeter, int>(
        (space, id) => RealGreeter(),
      );
      final store = StoreImpl(
        overrides: [greeterFactory(42).overrideWithValue(FakeGreeter())],
      );
      // A fresh, equal arg-provider instance resolves to the override...
      expect(
        store.bindWith(greeterFactory(42), DisposeStateNotifier()).hello(),
        'fake',
      );
      // ...while a different argument is left untouched.
      expect(
        store.bindWith(greeterFactory(7), DisposeStateNotifier()).hello(),
        'real',
      );
    });

    test('overriding a ViewModelProvider skips init() (plain instance)', () {
      final vmProvider = ViewModelProvider.shared<CountVm>(
        (space) => CountVm(),
      );
      final store = StoreImpl(
        overrides: [vmProvider.overrideWith((space) => CountVm())],
      );
      expect(store.share(vmProvider).inited, isFalse);
    });

    test('overriding a ViewModelProvider does NOT auto-dispose the fake', () {
      // overrideWith wraps the fake in a plain Provider, so on teardown the
      // store runs only the (here absent) disposer — the fake's own
      // ViewModel.dispose() is intentionally NOT invoked. The test owns the
      // fake's lifecycle.
      final vmProvider = ViewModelProvider.shared<CountVm>(
        (space) => CountVm(),
      );
      final fake = CountVm();
      final store = StoreImpl(
        overrides: [vmProvider.overrideWith((space) => fake)],
      );
      store.share(vmProvider);
      store.unmount();
      expect(fake.disposed, isFalse);
    });

    test(
      'overriding a ViewModelProvider with dispose: tears the fake down',
      () {
        final vmProvider = ViewModelProvider.shared<CountVm>(
          (space) => CountVm(),
        );
        final fake = CountVm();
        final store = StoreImpl(
          overrides: [
            vmProvider.overrideWith(
              (space) => fake,
              dispose: (vm) => vm.dispose(),
            ),
          ],
        );
        store.share(vmProvider);
        store.unmount();
        expect(fake.disposed, isTrue);
      },
    );

    testWidgets('StoreScope(overrides:) injects fake into the tree', (
      tester,
    ) async {
      late Greeter resolved;
      await tester.pumpWidget(
        StoreScope(
          overrides: [greeterProvider.overrideWithValue(FakeGreeter())],
          child: Builder(
            builder: (context) {
              resolved = context.share(greeterProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.hello(), 'fake');
    });
  });
}
