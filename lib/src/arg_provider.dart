part of 'provider.dart';

abstract class _BaseArgProviderFactory<T> {
  final void Function(T instance)? _disposer;

  const _BaseArgProviderFactory({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeInstance(T instance) {
    _disposer?.call(instance);
  }
}

abstract class _BaseArgProvider<T> extends Provider<T> {
  @override
  void disposeInstance(T instance) {
    getProviderFactory().disposeInstance(instance);
  }

  _BaseArgProviderFactory<T> getProviderFactory();
}

/// The single concrete provider produced by every `ArgProviderFactory[N]`.
///
/// Arguments are stored *flattened* in [_argParts] so they remain direct
/// elements of [props]. This preserves [Equatable]'s deep comparison for
/// `List`/`Map`/`Set` arguments — e.g. `provider([1, 2], p)` called twice with
/// different list instances but equal content resolves to the same cached
/// instance, exactly as the per-arity classes did before they were unified.
///
/// The argument parts are deep-frozen at construction (see [freezeArgKey]) so
/// this provider's `==` / `hashCode` stay stable even if the caller later
/// mutates a collection it passed as an argument; otherwise that mutation would
/// silently change the key after it had been stored in the [Store]'s instance
/// and scope maps, orphaning the cached instance and breaking refcounting. The
/// instance itself is still created from the caller's *original* argument value
/// — only the identity key is frozen.
class _ArgProvider<T> extends _BaseArgProvider<T> with Equatable {
  _ArgProvider(this._factory, List<Object?> argParts, this._create)
    : assert(
        argParts.isNotEmpty,
        'equatableProps returned an empty list, so every argument would '
        'collapse to a single cached instance. Return the field(s) that '
        'distinguish family members.',
      ),
      _argParts = freezeArgKey(argParts);

  final _BaseArgProviderFactory<T> _factory;
  final List<Object?> _argParts;
  final T Function(StoreSpace space) _create;

  @override
  T createInstance(StoreSpace space) => _create(space);

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _factory;

  @override
  List<Object?> get props => [_factory, ..._argParts];
}

/// A factory that builds a **family** of single-argument [Provider]s, one per
/// distinct argument value.
///
/// You usually do not construct this directly — obtain it from
/// [Provider.withArgument]. Calling the factory like a function, e.g. `p(42)`,
/// yields a [Provider] for that argument. Providers are keyed by the
/// argument's *value*, deep-compared via [Equatable], so two calls with
/// equal arguments resolve to the same cached instance (and `List`/`Map`/`Set`
/// arguments work as keys):
///
/// ```dart
/// final userProvider =
///     Provider.withArgument<User, int>((space, id) => User(id));
///
/// userProvider(42) == userProvider(42); // true  — same instance is reused
/// userProvider(1)  == userProvider(2);  // false — distinct family members
///
/// // Scoped acquisition (reference-counted, disposed with the scope):
/// final user = space.bind(userProvider(42));
/// ```
///
/// Lifetime follows how each produced provider is acquired: `space.bind(...)`
/// gives a scoped, reference-counted instance that is disposed when the last
/// binding scope is gone. To make the whole family store-lifetime instead, use
/// [asShared].
class ArgProviderFactory<T, A> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  /// Creates an argument-keyed provider factory.
  ///
  /// [_creator] receives the [StoreSpace] (the [Store] plus the baked-in scope
  /// of the acquiring widget) and the argument, and returns the instance.
  ///
  /// [disposer] runs when an instance produced by this family is disposed —
  /// i.e. when its last binding scope dies or the store unmounts. Use it to
  /// release resources the instance owns.
  ///
  /// [equatableProps] lets you customize the cache key derived from the
  /// argument. Return the list of values that should participate in equality;
  /// by default the argument itself is the key. Useful when only part of a
  /// rich argument object should distinguish family members.
  ///
  /// The returned list is the *complete* identity of a family member: any field
  /// you omit makes arguments that differ only in that field alias to the same
  /// cached instance, and returning an empty list collapses the whole family to
  /// one instance (which asserts in debug). Include every field that should
  /// distinguish instances.
  const ArgProviderFactory(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for [arg], returning a [Provider] you can
  /// acquire with `space.bind(...)` (scoped) or, after [asShared], with
  /// `store.share(...)` / `context.share(...)` (store-lifetime).
  ///
  /// Calls with equal arguments return equal providers, so the underlying
  /// instance is cached and shared per distinct argument value.
  Provider<T> call(A arg) => _ArgProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg) : [arg],
    (space) => _creator(space, arg),
  );

  /// Declares this argument provider as **store-lifetime (shared)**: mark it
  /// once at definition, then every call follows the Store and is keyed by the
  /// argument's value.
  ///
  /// Returns a function from the argument to a [SharedProvider]. Each distinct
  /// argument yields one lazy singleton acquired scope-free via
  /// [Store.share] / `context.share`, kept alive until the store unmounts.
  ///
  /// ```dart
  /// final userProvider =
  ///     Provider.withArgument<User, int>((space, id) => User(id)).asShared;
  /// store.share(userProvider(42)); // per-id singleton, lives until unmount
  /// ```
  SharedProvider<T> Function(A arg) get asShared =>
      (arg) => SharedProvider.of(this(arg));
}

/// Two-argument argument-keyed provider factory.
///
/// Behaves exactly like [ArgProviderFactory] but keys the family on a pair of
/// arguments; obtain it from [Provider.withArgument2]. See [ArgProviderFactory]
/// for the full behaviour, caching semantics, and an example.
class ArgProviderFactory2<T, A, B> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  /// Creates a two-argument provider factory — see [ArgProviderFactory.new].
  const ArgProviderFactory2(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for `(arg1, arg2)` — see
  /// [ArgProviderFactory.call].
  Provider<T> call(A arg1, B arg2) => _ArgProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg1, arg2) : [arg1, arg2],
    (space) => _creator(space, arg1, arg2),
  );

  /// Store-lifetime variant — see [ArgProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2) get asShared =>
      (arg1, arg2) => SharedProvider.of(this(arg1, arg2));
}

/// Three-argument argument-keyed provider factory.
///
/// Behaves exactly like [ArgProviderFactory] but keys the family on three
/// arguments; obtain it from [Provider.withArgument3]. See [ArgProviderFactory]
/// for the full behaviour, caching semantics, and an example.
class ArgProviderFactory3<T, A, B, C> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  /// Creates a three-argument provider factory — see [ArgProviderFactory.new].
  const ArgProviderFactory3(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for `(arg1, arg2, arg3)` — see
  /// [ArgProviderFactory.call].
  Provider<T> call(A arg1, B arg2, C arg3) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3)
        : [arg1, arg2, arg3],
    (space) => _creator(space, arg1, arg2, arg3),
  );

  /// Store-lifetime variant — see [ArgProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3) get asShared =>
      (arg1, arg2, arg3) => SharedProvider.of(this(arg1, arg2, arg3));
}

/// Four-argument argument-keyed provider factory.
///
/// Behaves exactly like [ArgProviderFactory] but keys the family on four
/// arguments; obtain it from [Provider.withArgument4]. See [ArgProviderFactory]
/// for the full behaviour, caching semantics, and an example.
class ArgProviderFactory4<T, A, B, C, D> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  /// Creates a four-argument provider factory — see [ArgProviderFactory.new].
  const ArgProviderFactory4(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for `(arg1, arg2, arg3, arg4)` — see
  /// [ArgProviderFactory.call].
  Provider<T> call(A arg1, B arg2, C arg3, D arg4) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3, arg4)
        : [arg1, arg2, arg3, arg4],
    (space) => _creator(space, arg1, arg2, arg3, arg4),
  );

  /// Store-lifetime variant — see [ArgProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4) get asShared =>
      (arg1, arg2, arg3, arg4) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4));
}

/// Five-argument argument-keyed provider factory.
///
/// Behaves exactly like [ArgProviderFactory] but keys the family on five
/// arguments; obtain it from [Provider.withArgument5]. See [ArgProviderFactory]
/// for the full behaviour, caching semantics, and an example.
class ArgProviderFactory5<T, A, B, C, D, E> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  /// Creates a five-argument provider factory — see [ArgProviderFactory.new].
  const ArgProviderFactory5(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for `(arg1, arg2, arg3, arg4, arg5)` — see
  /// [ArgProviderFactory.call].
  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3, arg4, arg5)
        : [arg1, arg2, arg3, arg4, arg5],
    (space) => _creator(space, arg1, arg2, arg3, arg4, arg5),
  );

  /// Store-lifetime variant — see [ArgProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4, E arg5)
  get asShared =>
      (arg1, arg2, arg3, arg4, arg5) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4, arg5));
}

/// Six-argument argument-keyed provider factory.
///
/// Behaves exactly like [ArgProviderFactory] but keys the family on six
/// arguments; obtain it from [Provider.withArgument6]. This is the highest
/// supported arity. See [ArgProviderFactory] for the full behaviour, caching
/// semantics, and an example.
class ArgProviderFactory6<T, A, B, C, D, E, F>
    extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  /// Creates a six-argument provider factory — see [ArgProviderFactory.new].
  const ArgProviderFactory6(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family member for `(arg1, arg2, arg3, arg4, arg5, arg6)` —
  /// see [ArgProviderFactory.call].
  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6) =>
      _ArgProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4, arg5, arg6)
            : [arg1, arg2, arg3, arg4, arg5, arg6],
        (space) => _creator(space, arg1, arg2, arg3, arg4, arg5, arg6),
      );

  /// Store-lifetime variant — see [ArgProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)
  get asShared =>
      (arg1, arg2, arg3, arg4, arg5, arg6) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4, arg5, arg6));
}
