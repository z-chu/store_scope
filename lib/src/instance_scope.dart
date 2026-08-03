part of 'provider.dart';

/// Identifies one live instance's dependency scope inside a [Store].
///
/// Keying on the *instance alone* would be wrong: instances are compared by
/// identity, and Dart canonicalizes values, so two unrelated providers that
/// each return `42` (or `'cfg'`, or a `const` object, or the same enum value)
/// would map to the same key — the second registration would silently evict the
/// first, and disposing one provider would then tear down the *other's*
/// dependency cascade while it is still in use, leaving its own cascade
/// orphaned forever.
///
/// Keying on the *provider alone* would be wrong too. A scoped `factory(42)`
/// and the shared `factory.asShared(42)` are *not* equal to each other — the
/// `SharedProvider` wrapper only ever equals another wrapper — but the wrapper
/// does not register itself here: `create` / `dispose` forward straight to the
/// `Provider` it wraps, so both members hand this manager the same
/// `factory(42)` recipe, which *is* equal by value. Two distinct live instances
/// in one store, one provider key.
///
/// The pair is unique: the [Store] holds at most one live instance per provider
/// key, so `(provider, instance)` identifies exactly one scope. The provider
/// part uses value equality — an argument provider is re-created on every
/// `factory(42)` call, so `create` and `dispose` may be handed equal-but-not-
/// identical objects — while the instance part uses identity, so a value type
/// with a custom `==` cannot alias two different objects together.
class _InstanceScopeKey {
  _InstanceScopeKey(this.provider, this.instance);

  final ProviderBase<dynamic> provider;
  final Object? instance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _InstanceScopeKey &&
          other.provider == provider &&
          identical(other.instance, instance));

  @override
  int get hashCode => Object.hash(provider, identityHashCode(instance));
}

class _InstanceScopeManager {
  final Map<_InstanceScopeKey, DisposeStateNotifier> _instanceScopes = {};

  void onInstanceCreated(
    ProviderBase<dynamic> provider,
    dynamic instance,
    DisposeStateNotifier scope,
  ) {
    _instanceScopes[_InstanceScopeKey(provider, instance)] = scope;
  }

  void onInstanceDisposed(ProviderBase<dynamic> provider, dynamic instance) {
    final scope = _instanceScopes.remove(_InstanceScopeKey(provider, instance));
    scope?.dispose();
  }
}

class _InstanceScopeManagerProvider
    extends SharedProvider<_InstanceScopeManager> {
  @override
  _InstanceScopeManager create(Store store) {
    return _InstanceScopeManager();
  }

  @override
  void dispose(Store store, _InstanceScopeManager instance) {}
}

final _instanceScopeManagerProvider = _InstanceScopeManagerProvider();
