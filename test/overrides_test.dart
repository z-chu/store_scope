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

/// A *real* ViewModel that takes its dependency from the store — the shape the
/// README recommends when the lifecycle itself is what you want to test.
class GreetVm extends ViewModel {
  GreetVm(this.greeter);

  final Greeter greeter;
  bool inited = false;
  bool closed = false;

  @override
  void init() {
    inited = true;
    addCloseable(() => closed = true);
  }
}

final greetVmProvider = ViewModelProvider<GreetVm>(
  (space) => GreetVm(space.share(greeterProvider)),
);

/// A fake whose setup lives in [init] and needs a live [StoreSpace] to bind
/// dependencies — the case that forces `..init()` into the override factory.
class SpaceVm extends ViewModel {
  SpaceVm(this._space, this._dep);

  final StoreSpace _space;
  final ProviderBase<Greeter> _dep;
  late final Greeter greeter;
  bool inited = false;

  @override
  void init() {
    inited = true;
    greeter = _space.bind(_dep); // the binding happens inside init()
  }
}

final spaceVmProvider = ViewModelProvider<SpaceVm>(
  (space) => throw StateError('always overridden in these tests'),
);

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

    test('overrideWithValue on a ViewModelProvider stays caller-owned', () {
      final vmProvider = ViewModelProvider.shared<CountVm>(
        (space) => CountVm(),
      );
      final fake = CountVm();
      final store = StoreImpl(overrides: [vmProvider.overrideWithValue(fake)]);
      expect(store.share(vmProvider).inited, isFalse);
      store.unmount();
      expect(fake.disposed, isFalse);
    });

    test('a reused fake survives a bind -> unbind -> rebind cycle', () {
      // The reason the store must never run an overridden instance's
      // lifecycle: capturing one fake in a `final` and returning it from the
      // factory is the normal test idiom, and a scoped provider is rebuilt
      // every time it is bound anew. If the store disposed the fake on the
      // first teardown, the second bind would hand out a dead ViewModel.
      final vmProvider = ViewModelProvider<CountVm>((space) => CountVm());
      final fake = CountVm();
      final store = StoreImpl(
        overrides: [vmProvider.overrideWith((space) => fake)],
      );

      final first = DisposeStateNotifier();
      expect(identical(store.bindWith(vmProvider, first), fake), isTrue);
      first.dispose();
      expect(fake.disposed, isFalse);

      final second = DisposeStateNotifier();
      final again = store.bindWith(vmProvider, second);
      expect(identical(again, fake), isTrue);
      expect(again.disposed, isFalse, reason: 'still usable on the way back');
      again.addListener(() {}); // a ScopedBuilder would do exactly this
    });

    test('overriding a dependency keeps the REAL ViewModel lifecycle', () {
      // The executable version of the advice in the README / ProviderOverride
      // dartdoc: to exercise init() / addCloseable / dispose(), do not override
      // the ViewModel — override what it binds and let the real one run.
      final store = StoreImpl(
        overrides: [greeterProvider.overrideWithValue(FakeGreeter())],
      );
      final scope = DisposeStateNotifier();
      final vm = store.bindWith(greetVmProvider, scope);

      expect(vm.greeter.hello(), 'fake', reason: 'the leaf was swapped');
      expect(vm.inited, isTrue, reason: 'real VM: init() ran');

      scope.dispose();
      expect(vm.disposed, isTrue, reason: 'real VM: disposed with its scope');
      expect(vm.closed, isTrue, reason: 'real VM: addCloseable fired');
    });

    test('a fake whose setup lives in init(): run it in the factory', () {
      // The documented recipe for "my ViewModel initializes in init()":
      //   overrideWith((space) => Fake(space)..init(), dispose: (vm) => vm.dispose())
      // The space handed to the factory is the instance's own scope, so a
      // space.bind performed inside init() still cascades on teardown.
      var depDisposed = false;
      final dep = Provider.from<Greeter>(
        (space) => FakeGreeter(),
        disposer: (_) => depDisposed = true,
      );
      final store = StoreImpl(
        overrides: [
          spaceVmProvider.overrideWith(
            (space) => SpaceVm(space, dep)..init(),
            dispose: (vm) => vm.dispose(),
          ),
        ],
      );

      final scope = DisposeStateNotifier();
      final vm = store.bindWith(spaceVmProvider, scope);
      expect(vm.inited, isTrue);
      expect(vm.greeter.hello(), 'fake', reason: 'init() bound its dependency');

      scope.dispose();
      expect(vm.disposed, isTrue, reason: 'dispose: ran the teardown');
      expect(depDisposed, isTrue, reason: 'the dep bound in init() cascaded');
    });

    test('overrideWith factory gets a space that can bind dependencies', () {
      // The only reason to reach for overrideWith over overrideWithValue.
      final vmProvider = ViewModelProvider.shared<CountVm>(
        (space) => CountVm(),
      );
      late Greeter resolvedDep;
      final store = StoreImpl(
        overrides: [
          vmProvider.overrideWith((space) {
            resolvedDep = space.share(greeterProvider);
            return CountVm();
          }),
        ],
      );
      store.share(vmProvider);
      expect(resolvedDep.hello(), 'real');
    });

    test('scoped and .asShared members of one family are distinct keys', () {
      // SharedProvider wrappers forward == / hashCode to their delegate, so
      // a wrapper and the bare arg-provider it wraps share a hash bucket.
      // They must still never match each other as override targets.
      final factory = Provider.withArgument<Greeter, int>(
        (space, id) => RealGreeter(),
      );
      final sharedFactory = factory.asShared;
      // Typed as ProviderBase: the point is that these two are compared as
      // override-map keys, where the static type is erased.
      final ProviderBase<Greeter> scopedTarget = factory(42);
      final ProviderBase<Greeter> sharedTarget = sharedFactory(42);

      expect(scopedTarget == sharedTarget, isFalse);
      expect(sharedTarget == scopedTarget, isFalse);
      expect(sharedFactory(42) == sharedTarget, isTrue); // equal args dedupe

      final store = StoreImpl(
        overrides: [
          scopedTarget.overrideWithValue(FakeGreeter()),
          sharedTarget.overrideWith((space) => FakeGreeter()),
        ],
      );
      expect(
        store.bindWith(factory(42), DisposeStateNotifier()).hello(),
        'fake',
      );
      expect(store.share(sharedFactory(42)).hello(), 'fake');
      // ...and a different argument is still untouched on both paths.
      expect(
        store.bindWith(factory(7), DisposeStateNotifier()).hello(),
        'real',
      );
      expect(store.share(sharedFactory(7)).hello(), 'real');
    });

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
