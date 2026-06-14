part of 'view_model.dart';

abstract class _BaseArgVmProviderFactory<T extends ViewModel> {
  final void Function(T instance)? _disposer;

  const _BaseArgVmProviderFactory({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeViewModel(T instance) {
    _disposer?.call(instance);
  }
}

abstract class _BaseArgViewModelProvider<T extends ViewModel>
    extends ViewModelProviderBase<T> {
  @override
  void disposeViewModel(T instance) {
    getProviderFactory().disposeViewModel(instance);
  }

  _BaseArgVmProviderFactory<T> getProviderFactory();
}

/// The single concrete ViewModel provider produced by every
/// `ArgVmProviderFactory[N]`. Arguments are kept *flattened* in [props] — see
/// [_ArgProvider] for why this preserves deep equality for collection
/// arguments.
///
/// As with `_ArgProvider`, the argument parts are deep-frozen at construction
/// (see [freezeArgKey]) so the identity key cannot be corrupted by a caller
/// later mutating a collection it passed as an argument; the ViewModel itself
/// is still built from the original argument value.
class _ArgViewModelProvider<T extends ViewModel>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider(this._factory, List<Object?> argParts, this._create)
    : assert(
        argParts.isNotEmpty,
        'equatableProps returned an empty list, so every argument would '
        'collapse to a single cached instance. Return the field(s) that '
        'distinguish family members.',
      ),
      _argParts = freezeArgKey(argParts);

  final _BaseArgVmProviderFactory<T> _factory;
  final List<Object?> _argParts;
  final T Function(StoreSpace space) _create;

  @override
  T createViewModel(StoreSpace space) => _create(space);

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _factory;

  @override
  List<Object?> get props => [_factory, ..._argParts];
}

/// A factory that builds a *family* of single-argument [ViewModel] providers.
///
/// Create one with [ViewModelProvider.withArgument]; calling it with an
/// argument value — e.g. `factory(42)` — yields a concrete
/// [ViewModelProviderBase] that you then [StoreSpace.bind] / `store.share`.
/// Each distinct argument value identifies a distinct [ViewModel] instance:
/// keys are compared by *value* (deep-compared via `equatable`, so `List`,
/// `Map` and `Set` arguments work as keys), not by reference.
///
/// As a [ViewModelProviderBase], the produced provider runs
/// [ViewModel.init] when the instance is created and [ViewModel.dispose]
/// (plus the optional `disposer`) when it is released. Whether release happens
/// when the binding scope dies or when the [Store] unmounts depends on how
/// the produced provider is acquired:
/// * `space.bind(factory(arg))` — scoped, reference-counted; disposed when the
///   last scope that bound it is gone.
/// * `asShared` — store-lifetime; one instance per distinct argument, kept
///   until the store unmounts (see [asShared]).
///
/// ```dart
/// final userVmProvider =
///     ViewModelProvider.withArgument<UserVm, int>((space, id) => UserVm(id));
///
/// // Scoped, reference-counted: disposed with the binding scope.
/// final vm = space.bind(userVmProvider(42));
/// ```
///
/// For higher arities use [ArgVmProviderFactory2] through
/// [ArgVmProviderFactory6]; they behave identically with more argument slots.
class ArgVmProviderFactory<T extends ViewModel, A>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  /// Creates a single-argument ViewModel family factory.
  ///
  /// [_creator] receives the [StoreSpace] (so it may `space.bind` child
  /// providers, composing dependencies that are disposed together with this
  /// instance) and the argument value, and returns the [ViewModel].
  ///
  /// Pass `disposer` to run extra cleanup after [ViewModel.dispose]. Pass
  /// `equatableProps` to derive the identity key from the argument when the
  /// argument itself is not a good `equatable` key (e.g. extract just the
  /// fields that should distinguish instances); by default the whole argument
  /// value is used as the key.
  ///
  /// The returned list is the *complete* identity: omitting a field aliases
  /// arguments that differ only in it, and an empty list collapses the whole
  /// family to one instance (which asserts in debug).
  const ArgVmProviderFactory(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at [arg], returning a concrete ViewModel provider
  /// keyed by that argument's value.
  ///
  /// Pass the result to [StoreSpace.bind] / `store.share`; equal arguments
  /// resolve to the same instance, distinct arguments to distinct instances.
  ViewModelProviderBase<T> call(A arg) => _ArgViewModelProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg) : [arg],
    (space) => _creator(space, arg),
  );

  /// Declares this argument ViewModel provider as **store-lifetime (shared)**:
  /// mark it once at definition, then every call follows the Store and is keyed
  /// by the argument's value (`init()` still runs on first creation).
  ///
  /// Use [asShared] when each distinct argument should resolve to a lazy
  /// singleton that outlives any single scope and is disposed only when the
  /// [Store] unmounts — acquire it scope-free with `store.share` /
  /// `context.share`. For scoped, reference-counted instances use the plain
  /// [call] result with [StoreSpace.bind] instead.
  ///
  /// ```dart
  /// final userVmProvider =
  ///     ViewModelProvider.withArgument<UserVm, int>((s, id) => UserVm(id)).asShared;
  /// store.share(userVmProvider(42)); // per-id singleton, lives until unmount
  /// ```
  SharedProvider<T> Function(A arg) get asShared =>
      (arg) => SharedProvider.of(this(arg));
}

/// A two-argument [ViewModel] family factory.
///
/// Identical to [ArgVmProviderFactory] but keyed by two argument values; see
/// [ArgVmProviderFactory] for the full semantics, [call] usage, and
/// [asShared].
class ArgVmProviderFactory2<T extends ViewModel, A, B>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  /// Creates a two-argument ViewModel family factory.
  /// See [ArgVmProviderFactory.new] for the parameter meanings.
  const ArgVmProviderFactory2(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at ([arg1], [arg2]); see [ArgVmProviderFactory.call].
  ViewModelProviderBase<T> call(A arg1, B arg2) => _ArgViewModelProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg1, arg2) : [arg1, arg2],
    (space) => _creator(space, arg1, arg2),
  );

  /// Store-lifetime variant — see [ArgVmProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2) get asShared =>
      (arg1, arg2) => SharedProvider.of(this(arg1, arg2));
}

/// A three-argument [ViewModel] family factory.
///
/// Identical to [ArgVmProviderFactory] but keyed by three argument values; see
/// [ArgVmProviderFactory] for the full semantics, [call] usage, and
/// [asShared].
class ArgVmProviderFactory3<T extends ViewModel, A, B, C>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  /// Creates a three-argument ViewModel family factory.
  /// See [ArgVmProviderFactory.new] for the parameter meanings.
  const ArgVmProviderFactory3(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at ([arg1], [arg2], [arg3]);
  /// see [ArgVmProviderFactory.call].
  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3)
            : [arg1, arg2, arg3],
        (space) => _creator(space, arg1, arg2, arg3),
      );

  /// Store-lifetime variant — see [ArgVmProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3) get asShared =>
      (arg1, arg2, arg3) => SharedProvider.of(this(arg1, arg2, arg3));
}

/// A four-argument [ViewModel] family factory.
///
/// Identical to [ArgVmProviderFactory] but keyed by four argument values; see
/// [ArgVmProviderFactory] for the full semantics, [call] usage, and
/// [asShared].
class ArgVmProviderFactory4<T extends ViewModel, A, B, C, D>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  /// Creates a four-argument ViewModel family factory.
  /// See [ArgVmProviderFactory.new] for the parameter meanings.
  const ArgVmProviderFactory4(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at ([arg1], [arg2], [arg3], [arg4]);
  /// see [ArgVmProviderFactory.call].
  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4)
            : [arg1, arg2, arg3, arg4],
        (space) => _creator(space, arg1, arg2, arg3, arg4),
      );

  /// Store-lifetime variant — see [ArgVmProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4) get asShared =>
      (arg1, arg2, arg3, arg4) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4));
}

/// A five-argument [ViewModel] family factory.
///
/// Identical to [ArgVmProviderFactory] but keyed by five argument values; see
/// [ArgVmProviderFactory] for the full semantics, [call] usage, and
/// [asShared].
class ArgVmProviderFactory5<T extends ViewModel, A, B, C, D, E>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  /// Creates a five-argument ViewModel family factory.
  /// See [ArgVmProviderFactory.new] for the parameter meanings.
  const ArgVmProviderFactory5(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at ([arg1], [arg2], [arg3], [arg4], [arg5]);
  /// see [ArgVmProviderFactory.call].
  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4, arg5)
            : [arg1, arg2, arg3, arg4, arg5],
        (space) => _creator(space, arg1, arg2, arg3, arg4, arg5),
      );

  /// Store-lifetime variant — see [ArgVmProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4, E arg5)
  get asShared =>
      (arg1, arg2, arg3, arg4, arg5) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4, arg5));
}

/// A six-argument [ViewModel] family factory.
///
/// Identical to [ArgVmProviderFactory] but keyed by six argument values; see
/// [ArgVmProviderFactory] for the full semantics, [call] usage, and
/// [asShared].
class ArgVmProviderFactory6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  /// Creates a six-argument ViewModel family factory.
  /// See [ArgVmProviderFactory.new] for the parameter meanings.
  const ArgVmProviderFactory6(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  /// Resolves the family at ([arg1], [arg2], [arg3], [arg4], [arg5], [arg6]);
  /// see [ArgVmProviderFactory.call].
  ViewModelProviderBase<T> call(
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    E arg5,
    F arg6,
  ) => _ArgViewModelProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3, arg4, arg5, arg6)
        : [arg1, arg2, arg3, arg4, arg5, arg6],
    (space) => _creator(space, arg1, arg2, arg3, arg4, arg5, arg6),
  );

  /// Store-lifetime variant — see [ArgVmProviderFactory.asShared].
  SharedProvider<T> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)
  get asShared =>
      (arg1, arg2, arg3, arg4, arg5, arg6) =>
          SharedProvider.of(this(arg1, arg2, arg3, arg4, arg5, arg6));
}
