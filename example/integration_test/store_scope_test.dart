// On-device integration tests for store_scope.
//
// Run on a connected device:
//   flutter test integration_test/store_scope_test.dart -d <device-id>
//
// Covers: Provider.shared + context.share, scoped Provider.withArgument + bind,
// the new `.asShared` argument providers (Provider & ViewModel), ViewModel
// lifecycle (init / closeable / dispose), the unmount-disposes-everything fix,
// StoreScope(overrides:), and the scoped mixins.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:store_scope/store_scope.dart';

/// A shared, mutable event log so tests can observe create/init/dispose order.
final List<String> events = <String>[];

// ---------------------------------------------------------------------------
// Providers / ViewModels under test
// ---------------------------------------------------------------------------

class Counter {
  int value = 0;
}

final counterProvider = Provider.shared<Counter>((s) => Counter());

/// Scoped argument provider (acquired with `space.bind`).
final scopedUserProvider = Provider.withArgument<String, int>((s, id) {
  events.add('create scoped $id');
  return 'user#$id';
}, disposer: (u) => events.add('dispose scoped $u'));

class Box {
  Box(this.id);
  final int id;
}

/// Shared argument provider declared `.asShared` at definition.
final sharedBoxProvider =
    Provider.withArgument<Box, int>((s, id) {
      events.add('create shared $id');
      return Box(id);
    }, disposer: (b) => events.add('dispose shared ${b.id}')).asShared;

class CounterVm extends ViewModel {
  final count = ValueNotifier(0);
  bool initialized = false;

  @override
  void init() {
    super.init();
    initialized = true;
    events.add('vm init');
    addCloseable(count.dispose);
  }

  void inc() => count.value++;

  @override
  void dispose() {
    events.add('vm dispose');
    super.dispose();
  }
}

final counterVmProvider = ViewModelProvider<CounterVm>((s) => CounterVm());
final appVmProvider = ViewModelProvider.shared<CounterVm>((s) => CounterVm());
final argVmProvider =
    ViewModelProvider.withArgument<CounterVm, int>(
      (s, id) => CounterVm(),
    ).asShared;

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

final greeterProvider = Provider.shared<Greeter>((s) => RealGreeter());

/// Multi-arity shared arg provider (withArgument2 + .asShared).
final shared2Provider =
    Provider.withArgument2<Box, String, int>((s, a, b) {
      events.add('create2 $a-$b');
      return Box(b);
    }).asShared;

/// Collection-argument provider: proves deep (value) equality through .asShared.
final listArgProvider =
    Provider.withArgument<Box, List<int>>((s, ids) {
      events.add('create list');
      return Box(ids.length);
    }).asShared;

/// A child provider bound inside a parent ViewModel's creator (cascade scope).
final childProvider = Provider.withArgument<String, int>((s, id) {
  events.add('child create $id');
  return 'child#$id';
}, disposer: (c) => events.add('child dispose $c'));

class ParentVm extends ViewModel {
  ParentVm(this.child);
  final String child;

  @override
  void dispose() {
    events.add('parent dispose');
    super.dispose();
  }
}

/// The parent's creator binds the child into the parent instance's own scope,
/// so disposing the parent cascade-disposes the child (no graph DSL).
final parentVmProvider = ViewModelProvider<ParentVm>(
  (space) => ParentVm(space.bind(childProvider(100))),
);

// ---------------------------------------------------------------------------
// Widgets exercising the mixins
// ---------------------------------------------------------------------------

/// ScopedStatelessMixin: binds an arg provider in its own space scope.
class ScopedUserWidget extends StatelessWidget with ScopedStatelessMixin {
  const ScopedUserWidget(this.id, {super.key});
  final int id;

  @override
  Widget buildScoped(BuildContext context, StoreSpace space) {
    final u = space.bind(scopedUserProvider(id));
    return Text(u, textDirection: TextDirection.ltr);
  }
}

/// ScopedStateMixin: binds a scoped ViewModel and drives it via a button.
class VmCounterWidget extends StatefulWidget {
  const VmCounterWidget({super.key});
  @override
  State<VmCounterWidget> createState() => _VmCounterWidgetState();
}

class _VmCounterWidgetState extends State<VmCounterWidget>
    with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    final vm = space.bind(counterVmProvider);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: vm.count,
            builder: (_, v, __) => Text('vm:$v'),
          ),
          ElevatedButton(
            key: const Key('inc'),
            onPressed: vm.inc,
            child: const Text('inc'),
          ),
        ],
      ),
    );
  }
}

/// ScopedStatelessMixin: binds via `context.store.bindWith(p, space.scope)`,
/// exercising the raw-scope escape hatch rather than `space.bind`.
class ScopedStatelessUser extends StatelessWidget with ScopedStatelessMixin {
  const ScopedStatelessUser(this.id, {super.key});
  final int id;

  @override
  Widget buildScoped(BuildContext context, StoreSpace space) {
    final u = context.store.bindWith(scopedUserProvider(id), space.scope);
    return Text('sl:$u', textDirection: TextDirection.ltr);
  }
}

/// ScopedStateMixin: a State that is itself a scope (ScopeAware); binds via the
/// raw `scope` getter instead of `space`.
class ScopedStateUser extends StatefulWidget {
  const ScopedStateUser(this.id, {super.key});
  final int id;
  @override
  State<ScopedStateUser> createState() => _ScopedStateUserState();
}

class _ScopedStateUserState extends State<ScopedStateUser>
    with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    final u = context.store.bindWith(scopedUserProvider(widget.id), scope);
    return Text('ss:$u', textDirection: TextDirection.ltr);
  }
}

/// ScopedStateMixin widget that binds the cascade parent ViewModel.
class ParentVmWidget extends StatefulWidget {
  const ParentVmWidget({super.key});
  @override
  State<ParentVmWidget> createState() => _ParentVmWidgetState();
}

class _ParentVmWidgetState extends State<ParentVmWidget> with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    final vm = space.bind(parentVmProvider);
    return Text(vm.child, textDirection: TextDirection.ltr);
  }
}

/// AutoStoreWidget owns its own Store.
class AutoPage extends AutoStoreWidget {
  const AutoPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.share(counterProvider);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text('auto:${c.value}'),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(events.clear);

  testWidgets('Provider.shared + context.share: same instance, persists', (
    tester,
  ) async {
    late Counter c1;
    late Counter c2;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            c1 = ctx.share(counterProvider);
            c1.value = 5;
            return Builder(
              builder: (ctx2) {
                c2 = ctx2.share(counterProvider);
                return const SizedBox();
              },
            );
          },
        ),
      ),
    );
    expect(identical(c1, c2), isTrue);
    expect(c2.value, 5);
  });

  testWidgets('shared arg provider (.asShared): per-argument singleton', (
    tester,
  ) async {
    late Store store;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            store = ctx.store;
            return const SizedBox();
          },
        ),
      ),
    );
    final a = store.share(sharedBoxProvider(42));
    final b = store.share(sharedBoxProvider(42));
    final c = store.share(sharedBoxProvider(7));
    expect(identical(a, b), isTrue); // same arg -> same instance
    expect(identical(a, c), isFalse); // different arg -> different instance
    expect(
      events.where((e) => e.startsWith('create shared')).length,
      2, // only 42 and 7 created
    );
  });

  testWidgets('shared arg provider survives scope death; disposed at unmount', (
    tester,
  ) async {
    late Store store;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            store = ctx.store;
            return const SizedBox();
          },
        ),
      ),
    );
    final scope = DisposeStateNotifier();
    final box = store.bindWith(sharedBoxProvider(9), scope); // ignores scope
    scope.dispose();
    await tester.pump();
    expect(events, isNot(contains('dispose shared 9'))); // not tied to scope
    expect(identical(store.share(sharedBoxProvider(9)), box), isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox())); // unmount
    await tester.pumpAndSettle();
    expect(events, contains('dispose shared 9'));
  });

  testWidgets('scoped bind: disposed when its widget leaves the tree', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: ScopedUserWidget(1))),
    );
    await tester.pumpAndSettle();
    expect(find.text('user#1'), findsOneWidget);
    expect(events, contains('create scoped 1'));
    expect(events, isNot(contains('dispose scoped user#1')));

    // Same StoreScope (store persists), child removed -> scope dies -> dispose.
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: SizedBox())),
    );
    await tester.pumpAndSettle();
    expect(events, contains('dispose scoped user#1'));
  });

  testWidgets('unmount disposes a shared ViewModel (P0 regression)', (
    tester,
  ) async {
    late CounterVm vm;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            vm = ctx.share(appVmProvider);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(vm.initialized, isTrue);
    expect(vm.disposed, isFalse);

    await tester.pumpWidget(
      const MaterialApp(home: SizedBox()),
    ); // remove scope
    await tester.pumpAndSettle();
    expect(vm.disposed, isTrue); // unmount disposed the un-scoped shared VM
    expect(events, contains('vm dispose'));
  });

  testWidgets('scoped ViewModel: init, increment via tap, dispose closeable', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: VmCounterWidget())),
    );
    await tester.pumpAndSettle();
    expect(events, contains('vm init'));
    expect(find.text('vm:0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('inc')));
    await tester.pumpAndSettle();
    expect(find.text('vm:1'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(events, contains('vm dispose'));
  });

  testWidgets(
    'ViewModel.withArgument(...).asShared: init + per-arg singleton',
    (tester) async {
      late Store store;
      await tester.pumpWidget(
        StoreScope(
          child: Builder(
            builder: (ctx) {
              store = ctx.store;
              return const SizedBox();
            },
          ),
        ),
      );
      final vmA = store.share(argVmProvider(1));
      final vmB = store.share(argVmProvider(1));
      final vmC = store.share(argVmProvider(2));
      expect(identical(vmA, vmB), isTrue);
      expect(identical(vmA, vmC), isFalse);
      expect(vmA.initialized, isTrue); // init() ran (unlike an override)
      expect(vmA.disposed, isFalse);
    },
  );

  testWidgets('StoreScope(overrides:) injects a fake', (tester) async {
    late String greeting;
    await tester.pumpWidget(
      StoreScope(
        overrides: [greeterProvider.overrideWithValue(FakeGreeter())],
        child: Builder(
          builder: (ctx) {
            greeting = ctx.share(greeterProvider).hello();
            return const SizedBox();
          },
        ),
      ),
    );
    expect(greeting, 'fake');
  });

  testWidgets('ScopedStatelessMixin binds and disposes with its scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: ScopedStatelessUser(2))),
    );
    await tester.pumpAndSettle();
    expect(find.text('sl:user#2'), findsOneWidget);
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: SizedBox())),
    );
    await tester.pumpAndSettle();
    expect(events, contains('dispose scoped user#2'));
  });

  testWidgets('ScopedStateMixin binds and disposes with its scope', (
    tester,
  ) async {
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: ScopedStateUser(3))),
    );
    await tester.pumpAndSettle();
    expect(find.text('ss:user#3'), findsOneWidget);
    await tester.pumpWidget(
      StoreScope(child: const MaterialApp(home: SizedBox())),
    );
    await tester.pumpAndSettle();
    expect(events, contains('dispose scoped user#3'));
  });

  testWidgets('AutoStoreWidget owns its own store', (tester) async {
    await tester.pumpWidget(const AutoPage());
    await tester.pumpAndSettle();
    expect(find.text('auto:0'), findsOneWidget);
  });

  testWidgets('ref-counting: disposed only when the last scope dies', (
    tester,
  ) async {
    Widget build(List<Widget> kids) => StoreScope(
      child: MaterialApp(home: Scaffold(body: Column(children: kids))),
    );
    // Two independent scopes bind the SAME scopedUserProvider(5).
    await tester.pumpWidget(
      build(const [
        ScopedStatelessUser(5, key: ValueKey('A')),
        ScopedStateUser(5, key: ValueKey('B')),
      ]),
    );
    await tester.pumpAndSettle();
    expect(
      events.where((e) => e == 'create scoped 5').length,
      1, // one instance shared by two scopes
    );

    // Drop one scope (keyed match keeps B alive) -> still one watcher.
    await tester.pumpWidget(
      build(const [ScopedStateUser(5, key: ValueKey('B'))]),
    );
    await tester.pumpAndSettle();
    expect(events, isNot(contains('dispose scoped user#5')));

    // Drop the last scope -> ref count hits zero -> disposed.
    await tester.pumpWidget(build(const []));
    await tester.pumpAndSettle();
    expect(events, contains('dispose scoped user#5'));
  });

  testWidgets('overrideWith replaces creation', (tester) async {
    late String greeting;
    await tester.pumpWidget(
      StoreScope(
        overrides: [greeterProvider.overrideWith((space) => FakeGreeter())],
        child: Builder(
          builder: (ctx) {
            greeting = ctx.share(greeterProvider).hello();
            return const SizedBox();
          },
        ),
      ),
    );
    expect(greeting, 'fake');
  });

  testWidgets(
    'overriding a ViewModel provider yields a plain instance (no init)',
    (tester) async {
      final fake = CounterVm();
      late CounterVm got;
      await tester.pumpWidget(
        StoreScope(
          overrides: [appVmProvider.overrideWith((space) => fake)],
          child: Builder(
            builder: (ctx) {
              got = ctx.share(appVmProvider);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(got, fake), isTrue);
      expect(fake.initialized, isFalse); // overrideWith builds a plain instance
    },
  );

  testWidgets('multi-arg .asShared (withArgument2): per-argument singleton', (
    tester,
  ) async {
    late Store store;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            store = ctx.store;
            return const SizedBox();
          },
        ),
      ),
    );
    final x = store.share(shared2Provider('a', 1));
    final y = store.share(shared2Provider('a', 1));
    final z = store.share(shared2Provider('a', 2));
    expect(identical(x, y), isTrue);
    expect(identical(x, z), isFalse);
    expect(events.where((e) => e.startsWith('create2')).length, 2);
  });

  testWidgets('collection argument uses deep equality through .asShared', (
    tester,
  ) async {
    late Store store;
    await tester.pumpWidget(
      StoreScope(
        child: Builder(
          builder: (ctx) {
            store = ctx.store;
            return const SizedBox();
          },
        ),
      ),
    );
    final a = store.share(listArgProvider([1, 2, 3]));
    final b = store.share(
      listArgProvider([1, 2, 3]),
    ); // distinct list, equal content
    expect(identical(a, b), isTrue);
    expect(events.where((e) => e == 'create list').length, 1);
  });

  testWidgets(
    'dependency composition: child cascade-disposed with its parent',
    (tester) async {
      await tester.pumpWidget(
        StoreScope(child: const MaterialApp(home: ParentVmWidget())),
      );
      await tester.pumpAndSettle();
      expect(find.text('child#100'), findsOneWidget);
      expect(events, contains('child create 100'));

      // Remove the parent widget (store persists) -> parent VM disposed ->
      // its scope fires -> the child it bound is cascade-disposed.
      await tester.pumpWidget(
        StoreScope(child: const MaterialApp(home: SizedBox())),
      );
      await tester.pumpAndSettle();
      expect(events, contains('parent dispose'));
      expect(events, contains('child dispose child#100'));
    },
  );
}
