## 0.3.0

No public API was removed or changed — but four behaviour changes below are marked **BREAKING**: they can turn a previously green build red without any code change on your side. Read the `Changed` section before upgrading.

### Fixed
* `ViewModel.dispose()` no longer abandons a teardown mid-way. A cleanup callback that throws used to escape the loop, skipping every later `addCloseable` / `addKeyedCloseable` callback **and** `super.dispose()` — leaving the notifier alive with its listeners attached, while the Store's `catch` reduced the whole thing to one log line. Failures are now collected, the teardown (including the owning provider's `disposer`) runs to completion, and only then is the failure surfaced per `StoreScopeConfig.throwOnCloseError`.
* `addKeyedCloseable` no longer loses the replacement callback when the closeable it replaces throws. The old callback was invoked unguarded *before* the new one was stored, so the exception escaped into caller code, the new callback was never registered (its resource leaked), and the old one stayed in the map to throw again at `dispose()`.
* `DisposeStateNotifier.dispose()` is now fully idempotent. A second call used to reach `ChangeNotifier.dispose()` again, tripping a debug-only assertion — so defensive double-teardown (and re-entrant disposal from inside `notifyListeners()`) crashed in development and passed silently in release.
* A provider whose value is legitimately `null` (nullable `T`) is created exactly once. Cache lookup tested the value instead of key presence, so such a provider was rebuilt on every access — allocating a fresh instance scope each time, all registered under the same key, so every earlier scope was orphaned and its dependency cascade never released.
* Per-instance dependency scopes are keyed by `(provider, instance)` instead of instance identity alone. Dart canonicalizes values, so two unrelated providers that each returned `42` (or a `const` object, or the same enum value) collided: the second registration evicted the first, and disposing one provider tore down the *other's* cascade while it was still in use.
* `Store.unmount()` and scope teardown are no longer aborted by the error reporting itself — see below.
* `addSubscription` now honours the disposed state, as its docs always claimed. It appended straight to the internal set instead of going through `addCloseable`, so a subscription registered after the ViewModel was disposed landed in a collection nothing drains again — never cancelled, still firing, still holding the ViewModel alive. This is reachable on the happy path: a load kicked off in `init()` that only completes after the binding scope died. It also takes `subscription.cancel` as a tear-off now, so de-duplication actually applies to it.
* A provider creator that throws no longer orphans the dependencies it had already bound. `Provider.create` allocated the instance scope, ran the creator, and only then registered the scope with the instance-scope manager — so when the creator (or a `ViewModel.init()`) failed after a `space.bind`, that scope never reached the manager and could never be disposed. The child stayed in the store until `unmount()`, and its refcount gained a permanent `+1` on every attempt, which grows without bound when a failing bind is retried on each rebuild. The scope is now released before the original error is rethrown; callers still see the creator's exception, unchanged.

### Changed
* **BREAKING**: an exception escaping a provider's `dispose` is now reported through `FlutterError.reportError` instead of being swallowed into a log line. A widget test with a throwing disposer that used to pass silently now **fails** — that is the intent, but expect previously green tests to go red. Migration: fix the disposer, or scope the expectation with `expectLater(tester.takeException(), ...)`. It reaches the console with a stack trace and **fails widget tests**, which is the point: a silent failure here hides the one guarantee this package exists to provide. The store still catches, so one bad disposer cannot strand the rest; if `FlutterError.onError` itself throws (e.g. `(d) => throw d.exception`), reporting falls back to `StoreScopeConfig.log` rather than breaking the teardown loop.
  * **BREAKING** consequence: these failures no longer pass through `StoreScopeConfig.log`, so a custom log sink (crash reporting, log collection) will stop seeing them and the loss is silent. Migration: hook `FlutterError.onError` instead.
* **BREAKING**: during scope-driven teardown, the instance is removed from the store *before* its `dispose` runs. `store.exists(p)` / `store.find(p)` observed from inside `p`'s own disposer now report "gone" rather than "still there", matching what the `unmount()` path already reported.
* `StoreScopeConfig` is exported from `package:store_scope/store_scope.dart` (was reachable only via an implementation import). Exported with `show StoreScopeConfig` on purpose: the top-level `LogWriterCallback` typedef and `defaultLogWriterCallback` function carry GetX's exact names and would make any file importing both packages unprefixed fail with `ambiguous_import`.
* **BREAKING**: when `StoreScopeConfig.throwOnCloseError` surfaces a cleanup failure, the **original error is rethrown with its original stack trace** instead of an `Exception` wrapping a stringified one. Tests can now match on the type the callback actually threw, and the stack points at the callback instead of at `ViewModel.dispose` — but an existing `throwsA(isA<Exception>())` now **fails** for a callback that threw an `Error` subtype (`StateError` is an `Error`, not an `Exception`). Migration: match the real type, e.g. `throwsStateError`.
* When several cleanup callbacks fail in one teardown, each is reported as its own `StoreScopeConfig.log` entry rather than being joined into a single blob (which buried everything after the first and broke line-oriented log parsing). Only one error can be thrown, so with `throwOnCloseError` the first is rethrown and the rest are logged.

### Docs
* Documented the override rule as a single rule with no exceptions: the store *returns* an overridden instance but never runs its lifecycle — no `init()`, no `dispose()`, even for a `ViewModelProvider` target. Added the two recipes (run the hooks yourself; or `overrideWith((space) => Fake(space)..init(), dispose: (vm) => vm.dispose())` when the fake's setup needs a live `StoreSpace`) and the guidance to override a ViewModel's *dependencies* when the real lifecycle is what's under test.
* Documented that a `StoreScopeConfig.log` implementation **must not throw**. It is called from the middle of binding and teardown — including the last-resort branch that runs after `FlutterError.onError` has already failed — and those call sites are deliberately unguarded, so a throwing sink would break `bindWith` outright and could strand a teardown half-finished.
* Documented that **scope-driven** teardown is inside-out — an instance's dependency cascade is released before its own `dispose()`. `unmount()` is explicitly excluded: it runs no cascade and disposes in creation order, so teardown order must not be relied on there.

## 0.2.0
* Add provider overrides for tests/DI. Inject fakes via `StoreScope(overrides: [...])` or `StoreImpl(overrides: [...])`, built with `provider.overrideWithValue(fake)` (caller owns the instance's lifecycle) or `provider.overrideWith((space) => fake, dispose: ...)`.
* **BREAKING**: acquiring a store-lifetime instance is now `Store.share` / `StoreSpace.share` / `context.share` (was `read`). It accepts only a `SharedProvider` and pairs with the `Provider.shared(...)` definition. Migration: replace `read(` with `share(` at those call sites.
* Added store-lifetime **argument** providers: mark a `withArgument` factory `.asShared` at the definition site, then acquire per-argument singletons with `store.share(p(arg))`. Keyed by the argument's value and alive until the Store is unmounted; available on every arity (`withArgument`..`withArgument6`) for both `Provider` and `ViewModelProvider`. Example: `final userProvider = Provider.withArgument<User, int>((s, id) => User(id)).asShared;`
* **BREAKING** (low impact): the per-arity argument-provider factories were unified into a single internal provider class; their public `createInstance` / `createViewModel` helper methods were removed. Acquire instances the usual way — call the factory (`factory(arg)`) then `space.bind(...)` / `store.share(...)`. Code that called those helpers directly must drop them.
* Fixed dartdoc examples that referenced removed/incorrect APIs (`store.shard`, `context.bindWith`, a non-existent `DisposeStateAwareMixin`).

## 0.1.0
* **BREAKING**: Instance lifetime is now declared on the provider. `Store.shared()` is removed — define store-lifetime instances with `Provider.shared(...)` / `ViewModelProvider.shared(...)` and read them via the scope-free, statically typed `Store.read` / `context.read`. Scoped providers keep using `bind` / `bindWith`.
* Fix: `Store.unmount()` now disposes every instance; ViewModels and their subscriptions were previously leaked on teardown.
* Fix: `ViewModel.dispose()` no longer throws `ConcurrentModificationError` when a closeable registers another closeable.
* Fix: swapping `StoreScope.storeOwner` no longer throws `LateInitializationError`.
* Remove the internal shared-instances tracking and the assert-only shared/bind misuse warnings.

## 0.0.11
* ViewModel add addSubscription method
* Add temporary method of Store to support creation of temporary instances
* Introducing ScopedBuilder to simplify the interaction between components and Store


## 0.0.10
* Introducing AutoStoreWidget and AutoStoreStatefulWidget to simplify state management and automatically handle the Store lifecycle

## 0.0.9

* Make viewModel inherit from ChangeNotifier to optimize resource destruction processing

## 0.0.8

* Refactor ArgProvider and ArgViewModelProvider to support custom equality

## 0.0.7

* Add instance scope manager to optimize instance creation and destruction process

## 0.0.6

* Provide a default implementation for the disposeViewModel method

## 0.0.5

* Support passing in parameters when creating a provider

## 0.0.4

* Allow access to store in initState; widget tree rebuilds on store changes

## 0.0.3

* Refactor code to use the new ScopeAware interface, optimizing binding and lifecycle management

## 0.0.2

* fix: change the parameter name

## 0.0.1

* Initial version. 
