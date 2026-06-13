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
