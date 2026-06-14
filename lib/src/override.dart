part of 'store.dart';

/// A substitution for a provider, used to inject fakes/mocks — primarily in
/// tests — via [StoreScope.overrides] or `StoreImpl(overrides: ...)`.
///
/// Create one with [ProviderOverride.overrideWithValue] or
/// [ProviderOverride.overrideWith]:
///
/// ```dart
/// StoreScope(
///   overrides: [
///     repositoryProvider.overrideWithValue(FakeRepository()),
///     userVmProvider.overrideWith((space) => FakeUserVm()),
///   ],
///   child: const MyApp(),
/// );
/// ```
class Override<T> {
  Override._(this.target, this.replacement);

  /// The provider being overridden (used as the lookup key).
  final ProviderBase<T> target;

  /// The provider used in place of [target] when the store resolves it.
  final ProviderBase<T> replacement;
}

/// A provider that always yields a fixed [value] and is never created or
/// disposed by the store — backs [ProviderOverride.overrideWithValue].
class _ValueProvider<T> extends ProviderBase<T> {
  _ValueProvider(this._value);

  final T _value;

  @override
  T create(Store store) => _value;

  @override
  void dispose(Store store, T instance) {}
}

/// Entry points for building an [Override] from a provider.
///
/// An override is matched by the provider used as its key. For an argument
/// provider that key is the **specific argument instance**, compared by value
/// via Equatable: `userProvider(42).overrideWithValue(...)` replaces only
/// `userProvider(42)`; a different argument such as `userProvider(7)` still
/// resolves to the real provider. An entire argument factory cannot be
/// overridden in one call.
extension ProviderOverride<T> on ProviderBase<T> {
  /// Overrides this provider with a fixed [value].
  ///
  /// The value is returned wherever this provider is requested and is **never
  /// created or disposed by the store** — the caller owns its lifecycle. This is
  /// the typical way to inject a ready-made mock in a test.
  Override<T> overrideWithValue(T value) =>
      Override._(this, _ValueProvider<T>(value));

  /// Overrides this provider's creation with [create] (and optional [dispose]).
  ///
  /// The replacement is built as a plain instance: for a [ViewModelProvider]
  /// target this means `init()` / `dispose()` are **not** called automatically,
  /// so the test stays in full control of the fake's lifecycle. To still run the
  /// fake's teardown, pass `dispose: (vm) => vm.dispose()`.
  Override<T> overrideWith(
    T Function(StoreSpace space) create, {
    void Function(T instance)? dispose,
  }) => Override._(this, Provider.from(create, disposer: dispose));
}
