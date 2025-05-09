part of 'view_model.dart';

abstract class _BaseArgVmProviderFactory<T extends ViewModel> {
  final void Function(T instance)? _disposer;

  const _BaseArgVmProviderFactory({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeViewModel(T instance) {
    _disposer?.call(instance);
  }
}

class ArgVmProviderFactory<T extends ViewModel, A>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  const ArgVmProviderFactory(
    T Function(StoreSpace space, A) creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg) {
    return _ArgViewModelProvider(this, arg);
  }

  T createViewModel(StoreSpace space, A arg) {
    return _creator.call(space, arg);
  }
}

class ArgVmProviderFactory2<T extends ViewModel, A, B>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  const ArgVmProviderFactory2(
    T Function(StoreSpace space, A, B) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2) {
    return _ArgViewModelProvider2(this, arg1, arg2);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2) {
    return _creator.call(space, arg1, arg2);
  }
}

class ArgVmProviderFactory3<T extends ViewModel, A, B, C>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  const ArgVmProviderFactory3(
    T Function(StoreSpace space, A, B, C) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3) {
    return _ArgViewModelProvider3(this, arg1, arg2, arg3);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3) {
    return _creator.call(space, arg1, arg2, arg3);
  }
}

class ArgVmProviderFactory4<T extends ViewModel, A, B, C, D>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  const ArgVmProviderFactory4(
    T Function(StoreSpace space, A, B, C, D) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4) {
    return _ArgViewModelProvider4(this, arg1, arg2, arg3, arg4);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3, D arg4) {
    return _creator.call(space, arg1, arg2, arg3, arg4);
  }
}

class ArgVmProviderFactory5<T extends ViewModel, A, B, C, D, E>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  const ArgVmProviderFactory5(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _ArgViewModelProvider5(this, arg1, arg2, arg3, arg4, arg5);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _creator.call(space, arg1, arg2, arg3, arg4, arg5);
  }
}

class ArgVmProviderFactory6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseArgVmProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  const ArgVmProviderFactory6(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  ViewModelProviderBase<T> call(
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    E arg5,
    F arg6,
  ) {
    return _ArgViewModelProvider6(this, arg1, arg2, arg3, arg4, arg5, arg6);
  }

  T createViewModel(
    StoreSpace space,
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    E arg5,
    F arg6,
  ) {
    return _creator.call(space, arg1, arg2, arg3, arg4, arg5, arg6);
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

class _ArgViewModelProvider<T extends ViewModel, A>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider(this._argProviderFactory, this._arg);
  final ArgVmProviderFactory<T, A> _argProviderFactory;
  final A _arg;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(space, _arg);
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [_argProviderFactory, ...equatableProps.call(_arg)]
        : [_argProviderFactory, _arg];
  }
}

class _ArgViewModelProvider2<T extends ViewModel, A, B>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider2(this._argProviderFactory, this._arg1, this._arg2);
  final ArgVmProviderFactory2<T, A, B> _argProviderFactory;
  final A _arg1;
  final B _arg2;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(space, _arg1, _arg2);
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [_argProviderFactory, ...equatableProps.call(_arg1, _arg2)]
        : [_argProviderFactory, _arg1, _arg2];
  }
}

class _ArgViewModelProvider3<T extends ViewModel, A, B, C>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider3(
    this._argProviderFactory,
    this._arg1,
    this._arg2,
    this._arg3,
  );
  final ArgVmProviderFactory3<T, A, B, C> _argProviderFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(space, _arg1, _arg2, _arg3);
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [_argProviderFactory, ...equatableProps.call(_arg1, _arg2, _arg3)]
        : [_argProviderFactory, _arg1, _arg2, _arg3];
  }
}

class _ArgViewModelProvider4<T extends ViewModel, A, B, C, D>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider4(
    this._argProviderFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
  );
  final ArgVmProviderFactory4<T, A, B, C, D> _argProviderFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(space, _arg1, _arg2, _arg3, _arg4);
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [_argProviderFactory, ...equatableProps.call(_arg1, _arg2, _arg3, _arg4)]
        : [_argProviderFactory, _arg1, _arg2, _arg3, _arg4];
  }
}

class _ArgViewModelProvider5<T extends ViewModel, A, B, C, D, E>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider5(
    this._argProviderFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
  );
  final ArgVmProviderFactory5<T, A, B, C, D, E> _argProviderFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(
      space,
      _arg1,
      _arg2,
      _arg3,
      _arg4,
      _arg5,
    );
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [
          _argProviderFactory,
          ...equatableProps.call(_arg1, _arg2, _arg3, _arg4, _arg5),
        ]
        : [_argProviderFactory, _arg1, _arg2, _arg3, _arg4, _arg5];
  }
}

class _ArgViewModelProvider6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseArgViewModelProvider<T>
    with EquatableMixin {
  _ArgViewModelProvider6(
    this._argProviderFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
    this._arg6,
  );
  final ArgVmProviderFactory6<T, A, B, C, D, E, F> _argProviderFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;
  final F _arg6;

  @override
  T createViewModel(StoreSpace space) {
    return _argProviderFactory.createViewModel(
      space,
      _arg1,
      _arg2,
      _arg3,
      _arg4,
      _arg5,
      _arg6,
    );
  }

  @override
  _BaseArgVmProviderFactory<T> getProviderFactory() => _argProviderFactory;

  @override
  List<Object?> get props {
    var equatableProps = _argProviderFactory._equatableProps;
    return equatableProps != null
        ? [
          _argProviderFactory,
          ...equatableProps.call(_arg1, _arg2, _arg3, _arg4, _arg5, _arg6),
        ]
        : [_argProviderFactory, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6];
  }
}
