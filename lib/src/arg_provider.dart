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
/// elements of [props]. This preserves [EquatableMixin]'s deep comparison for
/// `List`/`Map`/`Set` arguments — e.g. `provider([1, 2], p)` called twice with
/// different list instances but equal content resolves to the same cached
/// instance, exactly as the per-arity classes did before they were unified.
class _ArgProvider<T> extends _BaseArgProvider<T> with EquatableMixin {
  _ArgProvider(this._factory, this._argParts, this._create);

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

class ArgProviderFactory<T, A> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  const ArgProviderFactory(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg) => _ArgProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg) : [arg],
    (space) => _creator(space, arg),
  );
}

class ArgProviderFactory2<T, A, B> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  const ArgProviderFactory2(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2) => _ArgProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg1, arg2) : [arg1, arg2],
    (space) => _creator(space, arg1, arg2),
  );
}

class ArgProviderFactory3<T, A, B, C> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  const ArgProviderFactory3(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3)
        : [arg1, arg2, arg3],
    (space) => _creator(space, arg1, arg2, arg3),
  );
}

class ArgProviderFactory4<T, A, B, C, D> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  const ArgProviderFactory4(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3, arg4)
        : [arg1, arg2, arg3, arg4],
    (space) => _creator(space, arg1, arg2, arg3, arg4),
  );
}

class ArgProviderFactory5<T, A, B, C, D, E> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  const ArgProviderFactory5(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) => _ArgProvider<T>(
    this,
    _equatableProps != null
        ? _equatableProps(arg1, arg2, arg3, arg4, arg5)
        : [arg1, arg2, arg3, arg4, arg5],
    (space) => _creator(space, arg1, arg2, arg3, arg4, arg5),
  );
}

class ArgProviderFactory6<T, A, B, C, D, E, F>
    extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  const ArgProviderFactory6(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6) =>
      _ArgProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4, arg5, arg6)
            : [arg1, arg2, arg3, arg4, arg5, arg6],
        (space) => _creator(space, arg1, arg2, arg3, arg4, arg5, arg6),
      );
}
