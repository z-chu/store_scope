/// Internal helper shared by the argument-provider families in `provider.dart`
/// (`_ArgProvider`) and `view_model.dart` (`_ArgViewModelProvider`).
///
/// It is deliberately a tiny standalone library so a single implementation can
/// be reused across those two separate libraries (Dart privacy is per-library,
/// so a `_`-prefixed helper could not be shared). It is **not** exported from
/// the package's public API (`lib/store_scope.dart`); treat `freezeArgKey` as
/// package-internal.
library;

/// Returns a deeply-immutable snapshot of [parts] for use as an arg-provider
/// cache key.
///
/// Arg providers derive `==` / `hashCode` from their argument parts, and the
/// docs encourage `List`/`Map`/`Set` arguments as keys. Without freezing, a
/// caller mutating such a collection after binding would change the provider's
/// `hashCode` *after* it was stored as a key in the Store's `HashMap`s, making
/// the entry unreachable (orphaned instance, broken unbind/refcount). Freezing
/// the key at construction makes the identity immune to later mutation of the
/// caller's collection. Custom value types are assumed immutable and are passed
/// through unchanged.
List<Object?> freezeArgKey(List<Object?> parts) =>
    List<Object?>.unmodifiable(parts.map(_freezeArgValue));

Object? _freezeArgValue(Object? value) {
  if (value is Map) {
    return Map<Object?, Object?>.unmodifiable({
      for (final entry in value.entries)
        _freezeArgValue(entry.key): _freezeArgValue(entry.value),
    });
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(_freezeArgValue));
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeArgValue));
  }
  return value;
}
