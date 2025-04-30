part of 'view_model.dart';

abstract class _BaseArgViewModelProvider<T extends ViewModel> {
  final void Function(T instance)? _disposer;

  const _BaseArgViewModelProvider({Function(T instance)? disposer})
    : _disposer = disposer;

  void disposeViewModel(T instance) {
    _disposer?.call(instance);
  }
}

class ArgViewModelProvider<T extends ViewModel, A>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A) _creator;

  const ArgViewModelProvider(
    T Function(StoreSpace space, A) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(A arg) {
    return _InstantiableArgViewModelProvider._(this, arg);
  }

  T createViewModel(StoreSpace space, A arg) {
    return _creator.call(space, arg);
  }
}

class ArgViewModelProvider2<T extends ViewModel, A, B>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A, B) _creator;

  const ArgViewModelProvider2(
    T Function(StoreSpace space, A, B) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(A arg1, B arg2) {
    return _InstantiableArgViewModelProvider2._(this, arg1, arg2);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2) {
    return _creator.call(space, arg1, arg2);
  }
}

class ArgViewModelProvider3<T extends ViewModel, A, B, C>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A, B, C) _creator;

  const ArgViewModelProvider3(
    T Function(StoreSpace space, A, B, C) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3) {
    return _InstantiableArgViewModelProvider3._(this, arg1, arg2, arg3);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3) {
    return _creator.call(space, arg1, arg2, arg3);
  }
}

class ArgViewModelProvider4<T extends ViewModel, A, B, C, D>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A, B, C, D) _creator;

  const ArgViewModelProvider4(
    T Function(StoreSpace space, A, B, C, D) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4) {
    return _InstantiableArgViewModelProvider4._(this, arg1, arg2, arg3, arg4);
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3, D arg4) {
    return _creator.call(space, arg1, arg2, arg3, arg4);
  }
}

class ArgViewModelProvider5<T extends ViewModel, A, B, C, D, E>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A, B, C, D, E) _creator;

  const ArgViewModelProvider5(
    T Function(StoreSpace space, A, B, C, D, E) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _InstantiableArgViewModelProvider5._(
      this,
      arg1,
      arg2,
      arg3,
      arg4,
      arg5,
    );
  }

  T createViewModel(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5) {
    return _creator.call(space, arg1, arg2, arg3, arg4, arg5);
  }
}

class ArgViewModelProvider6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseArgViewModelProvider<T> {
  final T Function(StoreSpace space, A, B, C, D, E, F) _creator;

  const ArgViewModelProvider6(
    T Function(StoreSpace space, A, B, C, D, E, F) creator, {
    super.disposer,
  }) : _creator = creator;

  ViewModelProviderBase<T> call(
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    E arg5,
    F arg6,
  ) {
    return _InstantiableArgViewModelProvider6._(
      this,
      arg1,
      arg2,
      arg3,
      arg4,
      arg5,
      arg6,
    );
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

abstract class _BaseInstantiableArgViewModelProvider<T extends ViewModel>
    extends ViewModelProviderBase<T> {
  @override
  void disposeViewModel(T instance) {
    getArgProvider().disposeViewModel(instance);
  }

  _BaseArgViewModelProvider<T> getArgProvider();
}

class _InstantiableArgViewModelProvider<T extends ViewModel, A>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider._(this._argProvider, this._arg);
  final ArgViewModelProvider<T, A> _argProvider;
  final A _arg;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(space, _arg);
  }

  @override
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg == other._arg;

  @override
  int get hashCode => _argProvider.hashCode ^ _arg.hashCode;
}

class _InstantiableArgViewModelProvider2<T extends ViewModel, A, B>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider2._(
    this._argProvider,
    this._arg1,
    this._arg2,
  );
  final ArgViewModelProvider2<T, A, B> _argProvider;
  final A _arg1;
  final B _arg2;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(space, _arg1, _arg2);
  }

  @override
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider2 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2;

  @override
  int get hashCode => _argProvider.hashCode ^ _arg1.hashCode ^ _arg2.hashCode;
}

class _InstantiableArgViewModelProvider3<T extends ViewModel, A, B, C>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider3._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
  );
  final ArgViewModelProvider3<T, A, B, C> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(space, _arg1, _arg2, _arg3);
  }

  @override
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider3 &&
          runtimeType == other.runtimeType &&
          _argProvider == other._argProvider &&
          _arg1 == other._arg1 &&
          _arg2 == other._arg2 &&
          _arg3 == other._arg3;

  @override
  int get hashCode =>
      _argProvider.hashCode ^ _arg1.hashCode ^ _arg2.hashCode ^ _arg3.hashCode;
}

class _InstantiableArgViewModelProvider4<T extends ViewModel, A, B, C, D>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider4._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
  );
  final ArgViewModelProvider4<T, A, B, C, D> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(space, _arg1, _arg2, _arg3, _arg4);
  }

  @override
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider4 &&
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

class _InstantiableArgViewModelProvider5<T extends ViewModel, A, B, C, D, E>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider5._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
  );
  final ArgViewModelProvider5<T, A, B, C, D, E> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(
      space,
      _arg1,
      _arg2,
      _arg3,
      _arg4,
      _arg5,
    );
  }

  @override
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider5 &&
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

class _InstantiableArgViewModelProvider6<T extends ViewModel, A, B, C, D, E, F>
    extends _BaseInstantiableArgViewModelProvider<T> {
  _InstantiableArgViewModelProvider6._(
    this._argProvider,
    this._arg1,
    this._arg2,
    this._arg3,
    this._arg4,
    this._arg5,
    this._arg6,
  );
  final ArgViewModelProvider6<T, A, B, C, D, E, F> _argProvider;
  final A _arg1;
  final B _arg2;
  final C _arg3;
  final D _arg4;
  final E _arg5;
  final F _arg6;

  @override
  T createViewModel(StoreSpace space) {
    return _argProvider.createViewModel(
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
  _BaseArgViewModelProvider<T> getArgProvider() => _argProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InstantiableArgViewModelProvider6 &&
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
