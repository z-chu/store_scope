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
class _ArgViewModelProvider<T extends ViewModel>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider(this._factory, this._argParts, this._create);

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

class ArgVmProviderFactory<T extends ViewModel, A>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  const ArgVmProviderFactory(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg) => _ArgViewModelProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg) : [arg],
    (space) => _creator(space, arg),
  );
}

class ArgVmProviderFactory2<T extends ViewModel, A, B>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  const ArgVmProviderFactory2(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2) => _ArgViewModelProvider<T>(
    this,
    _equatableProps != null ? _equatableProps(arg1, arg2) : [arg1, arg2],
    (space) => _creator(space, arg1, arg2),
  );
}

class ArgVmProviderFactory3<T extends ViewModel, A, B, C>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  const ArgVmProviderFactory3(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3)
            : [arg1, arg2, arg3],
        (space) => _creator(space, arg1, arg2, arg3),
      );
}

class ArgVmProviderFactory4<T extends ViewModel, A, B, C, D>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  const ArgVmProviderFactory4(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4)
            : [arg1, arg2, arg3, arg4],
        (space) => _creator(space, arg1, arg2, arg3, arg4),
      );
}

class ArgVmProviderFactory5<T extends ViewModel, A, B, C, D, E>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  const ArgVmProviderFactory5(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) =>
      _ArgViewModelProvider<T>(
        this,
        _equatableProps != null
            ? _equatableProps(arg1, arg2, arg3, arg4, arg5)
            : [arg1, arg2, arg3, arg4, arg5],
        (space) => _creator(space, arg1, arg2, arg3, arg4, arg5),
      );
}

class ArgVmProviderFactory6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  const ArgVmProviderFactory6(
    this._creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _equatableProps = equatableProps;

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
}
