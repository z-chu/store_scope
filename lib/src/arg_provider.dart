part of 'provider.dart';

abstract class _BaseArgProviderFactory<T> {
  final void Function(T instance)? _disposer;

  const _BaseArgProviderFactory({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeInstance(T instance) {
    _disposer?.call(instance);
  }
}

class ArgProviderFactory<T, A> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A) _creator;
  final List<Object?> Function(A arg)? _equatableProps;

  const ArgProviderFactory(
    T Function(StoreSpace space, A) creator, {
    super.disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg) {
    return _ArgProvider(this, arg);
  }

  T createInstance(StoreSpace space, A arg) {
    return _creator.call(space, arg);
  }
}

class ArgProviderFactory2<T, A, B> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B) _creator;
  final List<Object?> Function(A arg1, B arg2)? _equatableProps;

  const ArgProviderFactory2(
    T Function(StoreSpace space, A, B) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2) {
    return _ArgProvider2(this, arg1, arg2);
  }

  T createInstance(StoreSpace space, A arg1, B arg2) {
    return _creator.call(space, arg1, arg2);
  }
}

class ArgProviderFactory3<T, A, B, C> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3)? _equatableProps;

  const ArgProviderFactory3(
    T Function(StoreSpace space, A, B, C) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3) {
    return _ArgProvider3(this, arg1, arg2, arg3);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3) {
    return _creator.call(space, arg1, arg2, arg3);
  }
}

class ArgProviderFactory4<T, A, B, C, D> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? _equatableProps;

  const ArgProviderFactory4(
    T Function(StoreSpace space, A, B, C, D) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4) {
    return _ArgProvider4(this, arg1, arg2, arg3, arg4);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3, D arg4) {
    return _creator.call(space, arg1, arg2, arg3, arg4);
  }
}

class ArgProviderFactory5<T, A, B, C, D, E> extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
  _equatableProps;

  const ArgProviderFactory5(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _ArgProvider5(this, arg1, arg2, arg3, arg4, arg5);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _creator.call(space, arg1, arg2, arg3, arg4, arg5);
  }
}

class ArgProviderFactory6<T, A, B, C, D, E, F>
    extends _BaseArgProviderFactory<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;
  final List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
  _equatableProps;

  const ArgProviderFactory6(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    super.disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) : _creator = creator,
       _equatableProps = equatableProps;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6) {
    return _ArgProvider6(
      this,
      arg1,
      arg2,
      arg3,
      arg4,
      arg5,
      arg6,
    );
  }

  T createInstance(
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

abstract class _BaseArgProvider<T> extends Provider<T> {
  @override
  void disposeInstance(T instance) {
    getProviderFactory().disposeInstance(instance);
  }

  _BaseArgProviderFactory<T> getProviderFactory();
}

class _ArgProvider<T, A> extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider(this._providerFactory, this._arg);
  final ArgProviderFactory<T, A> _providerFactory;
  final A _arg;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(space, _arg);
  }

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [_providerFactory, ...equatableProps.call(_arg)]
        : [_providerFactory, _arg];
  }
}

class _ArgProvider2<T, A, B> extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider2(this._providerFactory, this._arg1, this._arg2);
  final ArgProviderFactory2<T, A, B> _providerFactory;
  final A _arg1;
  final B _arg2;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(space, _arg1, _arg2);
  }

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [_providerFactory, ...equatableProps.call(_arg1, _arg2)]
        : [_providerFactory, _arg1, _arg2];
  }
}

class _ArgProvider3<T, A, B, C>
    extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider3(
    this._providerFactory,
    this._arg1,
    this._arg2,
    this._arg3,
  );
  final ArgProviderFactory3<T, A, B, C> _providerFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(space, _arg1, _arg2, _arg3);
  }

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [_providerFactory, ...equatableProps.call(_arg1, _arg2, _arg3)]
        : [_providerFactory, _arg1, _arg2, _arg3];
  }
}

class _ArgProvider4<T, A, B, C, D>
    extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider4(
    this._providerFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
  );
  final ArgProviderFactory4<T, A, B, C, D> _providerFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(space, _arg1, _arg2, _arg3, _arg4);
  }

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [_providerFactory, ...equatableProps.call(_arg1, _arg2, _arg3, _arg4)]
        : [_providerFactory, _arg1, _arg2, _arg3, _arg4];
  }
}

class _ArgProvider5<T, A, B, C, D, E>
    extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider5(
    this._providerFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
  );
  final ArgProviderFactory5<T, A, B, C, D, E> _providerFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(
      space,
      _arg1,
      _arg2,
      _arg3,
      _arg4,
      _arg5,
    );
  }

  @override
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [
          _providerFactory,
          ...equatableProps.call(_arg1, _arg2, _arg3, _arg4, _arg5),
        ]
        : [_providerFactory, _arg1, _arg2, _arg3, _arg4, _arg5];
  }
}

class _ArgProvider6<T, A, B, C, D, E, F>
    extends _BaseArgProvider<T>
    with EquatableMixin {
  _ArgProvider6(
    this._providerFactory,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
    this._arg6,
  );
  final ArgProviderFactory6<T, A, B, C, D, E, F> _providerFactory;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;
  final F _arg6;

  @override
  T createInstance(StoreSpace space) {
    return _providerFactory.createInstance(
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
  _BaseArgProviderFactory<T> getProviderFactory() => _providerFactory;

  @override
  List<Object?> get props {
    var equatableProps = _providerFactory._equatableProps;
    return equatableProps != null
        ? [
          _providerFactory,
          ...equatableProps.call(_arg1, _arg2, _arg3, _arg4, _arg5, _arg6),
        ]
        : [_providerFactory, _arg1, _arg2, _arg3, _arg4, _arg5, _arg6];
  }
}
