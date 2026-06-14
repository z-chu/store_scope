[![pub.dev Version (including pre-releases)](https://img.shields.io/pub/v/store_scope?include_prereleases)](https://pub.dev/packages/store_scope)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![zread](https://img.shields.io/badge/Ask_Zread-_.svg?style=flat&color=00b0aa&labelColor=000000&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTQuOTYxNTYgMS42MDAxSDIuMjQxNTZDMS44ODgxIDEuNjAwMSAxLjYwMTU2IDEuODg2NjQgMS42MDE1NiAyLjI0MDFWNC45NjAxQzEuNjAxNTYgNS4zMTM1NiAxLjg4ODEgNS42MDAxIDIuMjQxNTYgNS42MDAxSDQuOTYxNTZDNS4zMTUwMiA1LjYwMDEgNS42MDE1NiA1LjMxMzU2IDUuNjAxNTYgNC45NjAxVjIuMjQwMUM1LjYwMTU2IDEuODg2NjQgNS4zMTUwMiAxLjYwMDEgNC45NjE1NiAxLjYwMDFaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00Ljk2MTU2IDEwLjM5OTlIMi4yNDE1NkMxLjg4ODEgMTAuMzk5OSAxLjYwMTU2IDEwLjY4NjQgMS42MDE1NiAxMS4wMzk5VjEzLjc1OTlDMS42MDE1NiAxNC4xMTM0IDEuODg4MSAxNC4zOTk5IDIuMjQxNTYgMTQuMzk5OUg0Ljk2MTU2QzUuMzE1MDIgMTQuMzk5OSA1LjYwMTU2IDE0LjExMzQgNS42MDE1NiAxMy43NTk5VjExLjAzOTlDNS42MDE1NiAxMC42ODY0IDUuMzE1MDIgMTAuMzk5OSA0Ljk2MTU2IDEwLjM5OTlaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik0xMy43NTg0IDEuNjAwMUgxMS4wMzg0QzEwLjY4NSAxLjYwMDEgMTAuMzk4NCAxLjg4NjY0IDEwLjM5ODQgMi4yNDAxVjQuOTYwMUMxMC4zOTg0IDUuMzEzNTYgMTAuNjg1IDUuNjAwMSAxMS4wMzg0IDUuNjAwMUgxMy43NTg0QzE0LjExMTkgNS42MDAxIDE0LjM5ODQgNS4zMTM1NiAxNC4zOTg0IDQuOTYwMVYyLjI0MDFDMTQuMzk4NCAxLjg4NjY0IDE0LjExMTkgMS42MDAxIDEzLjc1ODQgMS42MDAxWiIgZmlsbD0iI2ZmZiIvPgo8cGF0aCBkPSJNNCAxMkwxMiA0TDQgMTJaIiBmaWxsPSIjZmZmIi8%2BCjxwYXRoIGQ9Ik00IDEyTDEyIDQiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIvPgo8L3N2Zz4K&logoColor=ffffff)](https://zread.ai/z-chu/store_scope)

# store_scope

**Flutter's Jetpack ViewModel** — widget-tree-scoped dependency injection with
automatic disposal, zero codegen, no global singletons, and bring-your-own
reactivity.

> 📖 中文文档见 [README.zh-CN.md](README.zh-CN.md)

If you've shipped Android or iOS, you already know the mental model: a
`ViewModel` that's tied to a screen, runs `init()`, and is cleaned up
automatically when the screen goes away. `store_scope` brings exactly that to
Flutter — a small DI container scoped to the widget tree — and stops there. It
doesn't pick your reactivity layer, doesn't generate code, and never puts your
objects in a global locator.

```dart
final counterProvider = ViewModelProvider<CounterVm>((space) => CounterVm());

class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
  const CounterPage({super.key});

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    final vm = space.bind(counterProvider); // created here, disposed with this widget
    return ValueListenableBuilder<int>(
      valueListenable: vm.count,
      builder: (_, value, __) => Text('$value'),
    );
  }
}
```

## Why store_scope?

Most Flutter state solutions force a package deal: pick the library and you also
inherit its reactivity model, its codegen, or its global state. `store_scope`
unbundles the one piece that's genuinely hard — **scoped lifetime and
dependency injection** — and leaves the rest to you.

| Capability | store_scope | Riverpod | get_it | provider | GetX |
| --- | :---: | :---: | :---: | :---: | :---: |
| Widget-tree-scoped auto-disposal | ✅ | ✅ | ❌ | ⚠️ manual | ⚠️ |
| Real DI container (compose deps) | ✅ | ✅ | ✅ | ❌ type-keyed | ✅ global |
| Jetpack-style `ViewModel` (`init`/`dispose`) | ✅ | ❌ | ❌ | ❌ | ⚠️ controller |
| Argument families | ✅ `withArgument` | ✅ `family` | ⚠️ params | ❌ | ⚠️ |
| Zero codegen | ✅ | ❌ codegen is the path | ✅ | ✅ | ✅ |
| Reactivity-agnostic | ✅ | ❌ `AsyncValue`/`ref.watch` | ✅ none | ❌ `ChangeNotifier` | ❌ `Obx`/Rx |
| No global singletons | ✅ | ✅ | ❌ locator | ✅ | ❌ global |
| Test injection / overrides | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ |

`store_scope` is the only option that ticks *all* of: tree-scoped auto-disposal
**+** a real DI container **+** a familiar ViewModel **+** zero codegen **+**
reactivity-agnostic **+** no global singletons. Signal/bloc/ValueNotifier fans
keep their reactivity; native developers keep their ViewModel.

## Install

```yaml
dependencies:
  store_scope: ^0.2.0
```

## Quick start

**1. Wrap your app once.** The `StoreScope` owns a `Store` for everything below
it.

```dart
void main() => runApp(const StoreScope(child: MyApp()));
```

**2. Hold state in a `ViewModel`** (or any plain class). Reactivity is yours —
here a built-in `ValueNotifier`.

```dart
class CounterVm extends ViewModel {
  final count = ValueNotifier(0);

  @override
  void init() {
    super.init();
    addCloseable(count.dispose); // cleaned up automatically
  }

  void increment() => count.value++;
}
```

**3. Define a provider** — its lifetime is declared here, once.

```dart
// Scoped: disposed when the last widget that bound it is gone.
final counterProvider = ViewModelProvider<CounterVm>((space) => CounterVm());
```

**4. Bind it to a widget's scope** and read reactively.

```dart
class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
  const CounterPage({super.key});

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    final vm = space.bind(counterProvider);
    return Scaffold(
      body: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: vm.count,
          builder: (_, value, __) => Text('Count: $value'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

When `CounterPage` leaves the tree, its scope dies, `CounterVm.dispose()` runs,
and the `ValueNotifier` is closed. No manual cleanup, no `dispose()` plumbing in
your `State`.

## Core concepts

### Store & StoreScope

A `Store` is a DI container: a map of providers to their live instances. A
`StoreScope` widget creates and owns one for its subtree; when that widget is
removed, the store **unmounts** and every instance it holds is disposed.

```dart
StoreScope(child: MyApp());                 // default store
StoreScope(overrides: [...], child: ...);   // with test doubles (see Testing)
StoreScope(storeOwner: myOwner, child: ...);// bring your own store owner
```

Read the store from any descendant context:

```dart
context.store;          // the nearest Store (throws if none)
context.storeOrNull;    // or null
context.storeMounted;   // bool
```

### Providers & lifetimes

A **provider** is a recipe for an instance. **Lifetime is a property of the
definition, not of the call site** — you decide once, when you declare it.

```dart
// Scoped — reference-counted, disposed when the last binding scope dies.
final repoProvider = Provider.from((space) => Repository());

// Store-lifetime — a lazy singleton kept until the StoreScope unmounts.
final authProvider = Provider.shared((space) => Auth());
```

| Lifetime | Define with | Acquire with |
| --- | --- | --- |
| **Widget / page** | `Provider.from` | `space.bind(p)` |
| **Feature / flow** (spans several pages) | `Provider.from` | `store.bindWith(p, featureScope)` — a `DisposeStateNotifier` you dispose when the flow ends |
| **App** | `Provider.shared` | `store.share(p)` / `context.share(p)` |

`Store.share` accepts only a store-lifetime provider (it's statically typed to a
`SharedProvider`), so you can never accidentally read a scoped provider without
a scope.

### Acquiring instances: `bind` vs `share`

```dart
// Scoped: tracked by `scope`; when the last scope is disposed, so is the instance.
final repo = space.bind(repoProvider);
final repo = store.bindWith(repoProvider, someListenable);

// Store-lifetime: no scope required.
final auth = store.share(authProvider);
final auth = context.share(authProvider);
```

### Arguments (families)

`Provider.withArgument` builds a family keyed by the argument's **value**
(deep-compared, so `List`/`Map`/`Set` arguments work as keys). `withArgument`
through `withArgument6` cover up to six positional arguments.

```dart
final userProvider = Provider.withArgument<User, int>(
  (space, id) => User(id),
);

final user = space.bind(userProvider(42)); // scoped to this widget
```

Add **`.asShared`** at the definition site to make the family store-lifetime —
one instance per distinct argument, kept until the store unmounts:

```dart
final userProvider =
    Provider.withArgument<User, int>((space, id) => User(id)).asShared;

final user = store.share(userProvider(42)); // per-id singleton
// userProvider(42) and userProvider(7) are different instances.
```

> A given factory is either scoped (`bind`) or shared (`.asShared`) — chosen
> once at definition, never mixed at call sites.

### ViewModel

`ViewModel` is a Jetpack-style holder with deterministic teardown.

```dart
class FeedVm extends ViewModel {
  final items = ValueNotifier<List<Item>>([]);
  Timer? _timer;

  @override
  void init() {
    super.init();

    // Auto-cancel a subscription:
    addSubscription(repo.stream.listen(_onData));

    // Run any teardown callback:
    addCloseable(items.dispose);

    // Keyed teardown — adding the same key disposes the previous one first:
    addKeyedCloseable('poll', () => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refresh());
  }

  @override
  void dispose() {
    // your own cleanup, then:
    super.dispose(); // runs every closeable / subscription
  }
}

final feedProvider = ViewModelProvider<FeedVm>((space) => FeedVm());
final appFeedProvider = ViewModelProvider.shared<FeedVm>((space) => FeedVm());
```

`init()` runs on creation; `dispose()` (and every registered closeable) runs
when the binding scope dies or the store unmounts. `ViewModelProvider` also
supports `.withArgument*` and `.asShared`, exactly like `Provider`.

### Dependency composition (cascade disposal)

A provider's body receives a `StoreSpace`, so it can `bind` its own
dependencies. Children are bound to the *parent instance's* scope, which means
**they're disposed together with the parent** — composition is just plain Dart,
no graph DSL, fully debuggable.

```dart
final profileProvider = ViewModelProvider<ProfileVm>((space) {
  final user = space.bind(userProvider(42));     // child
  final settings = space.bind(settingsProvider); // child
  return ProfileVm(user, settings);
});
// When ProfileVm is disposed, `user` and `settings` are released too.
```

### Scopes in the widget tree

Pick whichever entry point fits the widget you're writing:

```dart
// StatelessWidget, get a StoreSpace:
class A extends StatelessWidget with ScopedSpaceStatelessMixin {
  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) =>
      Text(space.bind(p).label);
}

// StatefulWidget, get a StoreSpace via the `space` getter:
class B extends StatefulWidget { /* ... */ }
class _BState extends State<B> with ScopedSpaceStateMixin {
  @override
  Widget build(BuildContext context) => Text(space.bind(p).label);
}

// Inline, no new class:
ScopedBuilder(
  builder: (context, space, child) => Text(space.bind(p).label),
);
```

`ScopedStatelessMixin` / `ScopedStateMixin` expose a raw `Listenable scope`
instead of a `StoreSpace`, for use with `context.store.bindWith(p, scope)`.

**`AutoStoreWidget`** owns a *fresh* `Store` for its own subtree (handy for a
self-contained page or flow):

```dart
class FeaturePage extends AutoStoreWidget {
  const FeaturePage({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.share(featureVmProvider); // lives as long as this page
    return /* ... */;
  }
}
```

## Reactivity is yours

`store_scope` ships **no** reactivity. It manages *what* objects exist and *for
how long*; *how the UI updates* is entirely your choice. A few recipes:

**ValueNotifier** (built in):

```dart
class CounterVm extends ViewModel {
  final count = ValueNotifier(0);
  @override
  void init() { super.init(); addCloseable(count.dispose); }
}

ValueListenableBuilder<int>(
  valueListenable: space.bind(counterProvider).count,
  builder: (_, value, __) => Text('$value'),
);
```

**signals** ([signals.dev](https://pub.dev/packages/signals)):

```dart
class CounterVm extends ViewModel {
  final count = signal(0);
  @override
  void init() { super.init(); addCloseable(count.dispose); }
}

Watch((_) => Text('${space.bind(counterProvider).count.value}'));
```

**flutter_bloc** — hold a Bloc/Cubit in a ViewModel:

```dart
class CounterVm extends ViewModel {
  final cubit = CounterCubit();
  @override
  void init() { super.init(); addCloseable(cubit.close); }
}

BlocBuilder<CounterCubit, int>(
  bloc: space.bind(counterProvider).cubit,
  builder: (_, count) => Text('$count'),
);
```

The pattern is always the same: keep your reactive primitive inside a
`ViewModel`, register its teardown with `addCloseable`, and `store_scope`
guarantees it's released at the right time.

## Testing: override providers

Swap any provider for a fake/mock without touching production code, via
`StoreScope(overrides: ...)` (widget tests) or `StoreImpl(overrides: ...)`
(pure-Dart tests).

```dart
final repositoryProvider =
    Provider.shared<Repository>((space) => RealRepository());

testWidgets('renders fake data', (tester) async {
  await tester.pumpWidget(
    StoreScope(
      overrides: [repositoryProvider.overrideWithValue(FakeRepository())],
      child: const MyApp(),
    ),
  );
  // ...
});

test('pure Dart', () {
  final store = StoreImpl(
    overrides: [repositoryProvider.overrideWith((space) => FakeRepository())],
  );
  expect(store.share(repositoryProvider), isA<FakeRepository>());
});
```

- **`overrideWithValue(fake)`** — returns a ready-made instance. The store
  **never creates or disposes it**; you own its lifecycle. The usual way to
  inject a mock.
- **`overrideWith((space) => fake, dispose: ...)`** — replaces the creation
  logic with a plain instance. Note: when overriding a `ViewModelProvider`,
  `init()` / `dispose()` are **not** called automatically — pass
  `dispose: (vm) => vm.dispose()` if you want teardown.

> Argument providers match by **value**: `userProvider(42).overrideWithValue(...)`
> overrides only `userProvider(42)`; `userProvider(7)` still uses the real one.
>
> Overrides are read once when the store is created. To swap them at runtime,
> give the `StoreScope` a new `key` (or `storeOwner`) so the store is rebuilt.

## Lifecycle at a glance

- **Scoped** instances are reference-counted across every scope that binds
  them; the instance is disposed only when the **last** scope is gone.
- **Store-lifetime** (`shared`) instances are never tied to a widget scope; they
  live until the `StoreScope` unmounts.
- Removing a `StoreScope` unmounts its store and disposes **every** instance —
  shared and scoped alike.
- `ViewModel.dispose()` and all `addCloseable` / `addSubscription` /
  `addKeyedCloseable` callbacks run deterministically at disposal.

## API cheatsheet

| | |
| --- | --- |
| `StoreScope({child, overrides, storeOwner})` | Owns a `Store` for the subtree |
| `Provider.from((space) => x)` | Scoped provider |
| `Provider.shared((space) => x)` | Store-lifetime provider |
| `Provider.withArgument<T, A>(...)` | Argument family (`…2`–`…6`) |
| `factory.asShared` | Make an argument family store-lifetime |
| `ViewModelProvider<T>((space) => vm)` | Scoped ViewModel (+ `.shared`, `.withArgument*`, `.asShared`) |
| `space.bind(p)` | Acquire scoped to this space |
| `store.bindWith(p, listenable)` | Acquire scoped to any `Listenable` |
| `store.share(p)` / `context.share(p)` | Acquire a store-lifetime instance |
| `p.overrideWithValue(v)` / `p.overrideWith(...)` | Test doubles |
| `ScopedSpaceStatelessMixin` / `ScopedSpaceStateMixin` | Get a `StoreSpace` in a widget |
| `ScopedStatelessMixin` / `ScopedStateMixin` | Get a raw `Listenable scope` |
| `ScopedBuilder` | Inline scoped builder |
| `AutoStoreWidget` / `AutoStoreStatefulWidget` | A widget that owns its own store |
| `DisposeStateNotifier` | A disposable `Listenable` to use as a custom scope |

## Example

A runnable demo lives in [`example/`](example). On-device integration tests
covering every feature are in
[`example/integration_test/`](example/integration_test) — run them with:

```bash
cd example && flutter test integration_test -d <device-id>
```

## Contributing

Issues and PRs are welcome. The package has no codegen and no runtime
dependencies beyond Flutter and `equatable`; `flutter test` runs the unit suite,
and `flutter test integration_test` (in `example/`) runs the on-device suite.

## License

[MIT](LICENSE)

## Learn more

- Interactive docs & Q&A: <https://zread.ai/z-chu/store_scope>
- 中文文档: [README.zh-CN.md](README.zh-CN.md)
