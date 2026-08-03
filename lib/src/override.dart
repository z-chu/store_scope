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
///
/// An override makes the store *return a different instance*. It never changes
/// how that instance is managed — see [ProviderOverride] for the rule.
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
/// **One rule, no exceptions: an override hands the store an inert stand-in.**
/// The store returns it wherever the target provider was requested and **never
/// runs its lifecycle** — for a [ViewModelProvider] target, the fake's `init()`
/// and `dispose()` are *not* called. You built the fake, so you own it. There
/// is no flag that changes this.
///
/// That is deliberate: a fake is routinely reused — captured in a `final` at
/// the top of a test, shared across cases, rebuilt whenever the store needs the
/// instance anew. A container that disposed it would hand out a dead object on
/// the next round, failing far from the cause.
///
/// **To test the real lifecycle, don't override the ViewModel.** If what you
/// want to verify is that `init()` ran, that [ViewModel.addCloseable] cleaned
/// up, or that the ViewModel died with its scope, override the *dependencies*
/// it binds and let the real one run the production path. Overriding the
/// ViewModel is for when you want it *out* of the test; overriding its
/// dependencies is for when you want it *under* test. The README's Testing
/// section spells both shapes out.
///
/// **Matching** is by the provider used as the key. For an argument provider
/// that key is the **specific argument instance**, compared by value via
/// Equatable: `userProvider(42).overrideWithValue(...)` replaces only
/// `userProvider(42)`; `userProvider(7)` still resolves to the real provider.
/// An entire argument factory cannot be overridden in one call.
extension ProviderOverride<T> on ProviderBase<T> {
  /// Overrides this provider with a fixed [value].
  ///
  /// The value is returned wherever this provider is requested and is **never
  /// created or disposed by the store** — you built it, you own it. This is the
  /// usual way to inject a ready-made mock. If the fake's hooks matter, run
  /// them yourself (`fake.init()`, `addTearDown(fake.dispose)`).
  ///
  /// Use [overrideWith] instead when the fake needs a [StoreSpace] to
  /// `space.bind` dependencies of its own.
  Override<T> overrideWithValue(T value) =>
      Override._(this, _ValueProvider<T>(value));

  /// Overrides this provider's creation with the [create] factory.
  ///
  /// Ownership is the same as [overrideWithValue] — the store hands out
  /// whatever [create] returns and runs no lifecycle on it — but the factory
  /// receives a live [StoreSpace], so the fake can `space.bind` / `space.share`
  /// dependencies of its own. That is the only reason to prefer this over
  /// [overrideWithValue], and it is also the only place a fake whose setup
  /// lives in `init()` can run it:
  ///
  /// ```dart
  /// userVmProvider.overrideWith(
  ///   (space) => FakeUserVm(space)..init(),
  ///   dispose: (vm) => vm.dispose(),
  /// )
  /// ```
  ///
  /// [dispose] is the only teardown the store runs on the returned instance.
  /// (Anything the factory acquired through `space.bind` is still released by
  /// the normal scope cascade, independently of this callback.)
  ///
  /// [create] may run more than once for the same target — the store rebuilds
  /// the instance whenever it needs it again, e.g. a scoped provider whose last
  /// binding scope died and is later bound anew. Returning a captured singleton
  /// is safe precisely because the store never disposes it; but build a
  /// **fresh** instance when you use the `..init()` shape above, or a rebuild
  /// would initialize the same object twice.
  Override<T> overrideWith(
    T Function(StoreSpace space) create, {
    void Function(T instance)? dispose,
  }) => Override._(this, Provider.from(create, disposer: dispose));
}
