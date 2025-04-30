part of 'provider.dart';

abstract class _BaseArgProvider<T>{
  final void Function(T instance)? _disposer;

  const _BaseArgProvider({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeInstance(T instance) {
    _disposer?.call(instance);
  }
}

class ArgProvider<T, A> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A) _creator;

  const ArgProvider(T Function(StoreSpace space, A) creator, {super.disposer})
    : _creator = creator;

  Provider<T> call(A arg) {
    return _InstantiableArgProvider._(this, arg);
  }

  T createInstance(StoreSpace space, A arg) {
    return _creator.call(space, arg);
  }
}

class ArgProvider2<T, A, B> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A, B) _creator;

  const ArgProvider2(
    T Function(StoreSpace space, A, B) creator, {
    super.disposer,
  }) : _creator = creator;

  Provider<T> call(A arg1, B arg2) {
    return _InstantiableArgProvider2._(this, arg1, arg2);
  }

  T createInstance(StoreSpace space, A arg1, B arg2) {
    return _creator.call(space, arg1, arg2);
  }
}

class ArgProvider3<T, A, B, C> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A, B, C) _creator;

  const ArgProvider3(
    T Function(StoreSpace space, A, B, C) creator, {
    super.disposer,
  }) : _creator = creator;

  Provider<T> call(A arg1, B arg2, C arg3) {
    return _InstantiableArgProvider3._(this, arg1, arg2, arg3);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3) {
    return _creator.call(space, arg1, arg2, arg3);
  }
}

class ArgProvider4<T, A, B, C, D> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;

  const ArgProvider4(
    T Function(StoreSpace space, A, B, C, D) creator, {
    super.disposer,
  }) : _creator = creator;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4) {
    return _InstantiableArgProvider4._(this, arg1, arg2, arg3, arg4);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3, D arg4) {
    return _creator.call(space, arg1, arg2, arg3, arg4);
  }
}

class ArgProvider5<T, A, B, C, D, E> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;

  const ArgProvider5(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    super.disposer,
  }) : _creator = creator;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _InstantiableArgProvider5._(this, arg1, arg2, arg3, arg4, arg5);
  }

  T createInstance(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _creator.call(space, arg1, arg2, arg3, arg4, arg5);
  }
}

class ArgProvider6<T, A, B, C, D, E, F> extends _BaseArgProvider<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;

  const ArgProvider6(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    super.disposer,
  }) : _creator = creator;

  Provider<T> call(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6) {
    return _InstantiableArgProvider6._(
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

abstract class _BaseInstantiableArgProvider<T> extends Provider<T> {
  @override
  void disposeInstance(T instance) {
    getArgProvider().disposeInstance(instance);
  }

  _BaseArgProvider<T> getArgProvider();
}

class _InstantiableArgProvider<T, A> extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider._(this._argProvider, this._arg);
  final ArgProvider<T, A> _argProvider;
  final A _arg;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(space, _arg);
  }

  @override
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg == other._arg;

  @override
  int get hashCode => _argProvider.hashCode ^ _arg.hashCode;
}

class _InstantiableArgProvider2<T, A, B>
    extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider2._(this._argProvider, this._arg1, this._arg2);
  final ArgProvider2<T, A, B> _argProvider;
  final A _arg1;
  final B _arg2;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(space, _arg1, _arg2);
  }

  @override
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider2 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2;

  @override
  int get hashCode => _argProvider.hashCode ^ _arg1.hashCode ^ _arg2.hashCode;
}

class _InstantiableArgProvider3<T, A, B, C>
    extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider3._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
  );
  final ArgProvider3<T, A, B, C> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(space, _arg1, _arg2, _arg3);
  }

  @override
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider3 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2 &&
          _arg3 == other._arg3;

  @override
  int get hashCode =>
      _argProvider.hashCode ^ _arg1.hashCode ^ _arg2.hashCode ^ _arg3.hashCode;
}

class _InstantiableArgProvider4<T, A, B, C, D>
    extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider4._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
  );
  final ArgProvider4<T, A, B, C, D> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(space, _arg1, _arg2, _arg3, _arg4);
  }

  @override
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider4 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2 &&
          _arg3 == other._arg3 &&
          _arg4 == other._arg4;

  @override
  int get hashCode =>
      _argProvider.hashCode ^
      _arg1.hashCode ^
      _arg2.hashCode ^
      _arg3.hashCode ^
      _arg4.hashCode;
}

class _InstantiableArgProvider5<T, A, B, C, D, E>
    extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider5._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
  );
  final ArgProvider5<T, A, B, C, D, E> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(
      space,
      _arg1,
      _arg2,
      _arg3,
      _arg4,
      _arg5,
    );
  }

  @override
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider5 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2 &&
          _arg3 == other._arg3 &&
          _arg4 == other._arg4 &&
          _arg5 == other._arg5;

  @override
  int get hashCode =>
      _argProvider.hashCode ^
      _arg1.hashCode ^
      _arg2.hashCode ^
      _arg3.hashCode ^
      _arg4.hashCode ^
      _arg5.hashCode;
}

class _InstantiableArgProvider6<T, A, B, C, D, E, F>
    extends _BaseInstantiableArgProvider<T> {
  _InstantiableArgProvider6._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
    this._arg6,
  );
  final ArgProvider6<T, A, B, C, D, E, F> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;
  final F _arg6;

  @override
  T createInstance(StoreSpace space) {
    return _argProvider.createInstance(
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
  _BaseArgProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgProvider6 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2 &&
          _arg3 == other._arg3 &&
          _arg4 == other._arg4 &&
          _arg5 == other._arg5 &&
          _arg6 == other._arg6;

  @override
  int get hashCode =>
      _argProvider.hashCode ^
      _arg1.hashCode ^
      _arg2.hashCode ^
      _arg3.hashCode ^
      _arg4.hashCode ^
      _arg5.hashCode ^
      _arg6.hashCode;
}
