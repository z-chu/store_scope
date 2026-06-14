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
