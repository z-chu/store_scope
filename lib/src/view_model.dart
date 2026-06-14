import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:store_scope/src/provider.dart' show Provider, SharedProvider;

import 'arg_key.dart';
import 'dispose_state_notifier.dart';
import 'store.dart';
import 'store_scope_config.dart';
import 'store_space.dart';

part 'arg_view_model_provider.dart';

/// A Jetpack-style state holder with a deterministic, scope-bound lifetime.
///
/// A [ViewModel] is created and disposed by a [ViewModelProvider] (or one of
/// its [ViewModelProvider.shared] / [ViewModelProvider.withArgument] variants).
/// [init] runs once on creation; [dispose] — together with every
/// [addCloseable], [addKeyedCloseable] and [addSubscription] callback — runs
/// exactly once, deterministically, when the binding scope dies or the owning
/// [Store] unmounts. You never call [init] or [dispose] yourself; the provider
/// drives them.
///
/// Because it extends [ChangeNotifier], a [ViewModel] can hold mutable state
/// and call `notifyListeners()` to rebuild widgets that listen to it. It also
/// implements [ScopeAware]: its [scope] becomes disposed at the start of
/// [dispose], so child providers bound through it are released alongside it.
///
/// Subclass it, expose state, and register cleanup in [init]:
///
/// ```dart
/// class CounterVm extends ViewModel {
///   int count = 0;
///
///   @override
///   void init() {
///     final ticker = Stream.periodic(const Duration(seconds: 1));
///     addSubscription(ticker.listen((_) {
///       count++;
///       notifyListeners();
///     }));
///   }
/// }
///
/// final counterVmProvider = ViewModelProvider((space) => CounterVm());
/// ```
abstract class ViewModel extends ChangeNotifier implements ScopeAware {
  final _viewModelScope = DisposeStateNotifier();
  final Map<String, VoidCallback> _keyToCloseables = {};
  final Set<VoidCallback> _closeables = {};

  /// The [Listenable] whose disposal marks the end of this ViewModel's life.
  ///
  /// It is disposed at the very start of [dispose], so any child provider that
  /// was `space.bind`-ed through this scope is released together with the
  /// ViewModel. After this point [disposed] is `true`.
  @override
  Listenable get scope => _viewModelScope;

  /// Whether [dispose] has already run.
  ///
  /// Once `true`, registering an [addCloseable] / [addKeyedCloseable] callback
  /// runs it immediately instead of storing it, and the ViewModel must no
  /// longer be used.
  bool get disposed => _viewModelScope.disposed;

  /// One-time initialization hook, invoked by the provider right after the
  /// instance is constructed (via `createInstance`).
  ///
  /// Override it to start subscriptions, kick off loads, or register cleanup
  /// with [addCloseable] / [addKeyedCloseable] / [addSubscription]. The default
  /// implementation does nothing.
  void init() {}

  /// Releases every resource registered with [addCloseable],
  /// [addKeyedCloseable] and [addSubscription], then tears down the
  /// [ChangeNotifier].
  ///
  /// Called automatically by the provider when the binding scope dies or the
  /// [Store] unmounts — do not call it yourself. The [scope] is disposed first
  /// (so [disposed] becomes `true` before any callback runs), each callback is
  /// then invoked once on a snapshot of the collections, and `super.dispose()`
  /// runs last so the notifier stays usable while callbacks execute. Errors
  /// thrown by a callback are routed through [StoreScopeConfig].
  @override
  @mustCallSuper
  void dispose() {
    // 先 dispose scope:让 disposed=true,这样在 closeable 内重入调用
    // addCloseable/addKeyedCloseable 时会走"立即关闭"分支,不再 mutate 集合。
    // 再对集合做快照遍历(toList),双保险避免 ConcurrentModificationError。
    _viewModelScope.dispose();
    for (var closeable in _closeables.toList()) {
      _closeWithException(closeable);
    }
    for (var closeable in _keyToCloseables.values.toList()) {
      _closeWithException(closeable);
    }
    _keyToCloseables.clear();
    _closeables.clear();
    // super.dispose() 放最后:closeable 运行期间 ChangeNotifier 仍可用。
    super.dispose();
  }

  /// Registers a [StreamSubscription] to be cancelled when this ViewModel is
  /// disposed.
  ///
  /// Shorthand for `addCloseable(subscription.cancel)`. Call it from [init] to
  /// keep stream listeners tied to the ViewModel's lifetime.
  @protected
  void addSubscription(StreamSubscription subscription) {
    _closeables.add(() {
      subscription.cancel();
    });
  }

  /// Adds a closeable resource to be disposed when the ViewModel is disposed.
  ///
  /// The [closeable] callback will be executed when:
  /// - The ViewModel is disposed
  /// - The ViewModel is already disposed (immediately)
  ///
  /// If the same [closeable] is added multiple times, it will only be executed once.
  ///
  /// Example:
  /// ```dart
  /// addCloseable(() {
  ///   // Clean up resources
  ///   subscription.cancel();
  /// });
  /// ```
  @protected
  void addCloseable(VoidCallback closeable) {
    if (disposed) {
      _closeWithException(closeable);
      return;
    }
    if (_closeables.contains(closeable)) {
      return;
    }
    _closeables.add(closeable);
  }

  /// Adds a keyed closeable resource to be disposed when the ViewModel is disposed.
  ///
  /// The [closeable] callback will be executed when:
  /// - The ViewModel is disposed
  /// - The ViewModel is already disposed (immediately)
  /// - A new closeable is added with the same [key]
  ///
  /// If a closeable with the same [key] already exists:
  /// - The old closeable will be executed immediately
  /// - The new closeable will replace the old one
  ///
  /// Example:
  /// ```dart
  /// addKeyedCloseable('subscription', () {
  ///   // Clean up resources
  ///   subscription.cancel();
  /// });
  /// ```
  @protected
  void addKeyedCloseable(String key, VoidCallback closeable) {
    if (disposed) {
      _closeWithException(closeable);
      return;
    }
    var oldCloseable = _keyToCloseables[key];
    if (oldCloseable != null) {
      if (oldCloseable == closeable) return;
      // 立即执行旧的 keyed closeable。注意:closeable 从不作为 listener 注册,
      // 因此无需(也不能)调用 removeListener。
      oldCloseable.call();
    }
    _keyToCloseables[key] = closeable;
  }

  void _closeWithException(VoidCallback closeable) {
    try {
      closeable();
    } catch (error, stackTrace) {
      if (StoreScopeConfig.throwOnCloseError) {
        throw Exception(
          'Failed to close $error\n'
          'Stack trace:\n$stackTrace',
        );
      } else {
        StoreScopeConfig.log(
          'Failed to close $error\n'
          'Stack trace:\n$stackTrace',
          isError: true,
        );
      }
    }
  }
}

/// Base class for any [Provider] whose instances are [ViewModel]s.
///
/// It wires the [ViewModel] lifecycle into the provider contract:
/// [createInstance] builds the ViewModel via [createViewModel] and immediately
/// calls its [ViewModel.init]; [disposeInstance] calls the ViewModel's
/// [ViewModel.dispose] and then [disposeViewModel] for any extra teardown.
/// Those two overrides are `@nonVirtual` — subclasses customize behavior by
/// implementing [createViewModel] / [disposeViewModel], not by re-overriding
/// the lifecycle hooks. Most code uses the concrete [ViewModelProvider]
/// instead of subclassing this directly.
abstract class ViewModelProviderBase<T extends ViewModel> extends Provider<T> {
  /// Builds the ViewModel through [createViewModel] and runs
  /// [ViewModel.init] before returning it. Invoked by the [Store] when the
  /// provider is first acquired in a scope; do not call it yourself.
  @override
  @nonVirtual
  T createInstance(StoreSpace space) {
    final vm = createViewModel(space);
    vm.init();
    return vm;
  }

  /// Runs [ViewModel.dispose] and then [disposeViewModel] when the instance is
  /// torn down. Invoked by the [Store] once the last binding scope is gone (or
  /// the store unmounts); do not call it yourself.
  @override
  @nonVirtual
  void disposeInstance(T instance) {
    instance.dispose();
    disposeViewModel(instance);
  }

  /// Constructs the [ViewModel]. The given [space] is a [StoreSpace] tied to
  /// this instance's own scope — use `space.bind(childProvider)` to compose
  /// dependencies that should live and die with this ViewModel.
  T createViewModel(StoreSpace space);

  /// Optional extra teardown run after [ViewModel.dispose]. The default
  /// implementation does nothing.
  void disposeViewModel(T instance) {}
}

/// A [Provider] backed by a [ViewModel], created from plain creator/disposer
/// callbacks.
///
/// Define one at the top level and acquire its instance with
/// `space.bind(provider)` (scoped, reference-counted: the ViewModel is disposed
/// when the last scope that bound it is gone). For store-lifetime instances use
/// [shared]; for instance families keyed by an argument value use
/// [withArgument] (and its higher-arity siblings).
///
/// ```dart
/// final counterVmProvider = ViewModelProvider(
///   (space) => CounterVm(),
///   disposer: (vm) => print('counter gone'),
/// );
///
/// // In a scoped widget / another provider:
/// final vm = space.bind(counterVmProvider);
/// ```
class ViewModelProvider<T extends ViewModel> extends ViewModelProviderBase<T> {
  /// Builds the [ViewModel] for a given [StoreSpace]. Bind child providers
  /// through `space.bind(...)` here to compose dependencies that share this
  /// instance's lifetime.
  final T Function(StoreSpace space) creator;

  /// Optional extra teardown invoked after [ViewModel.dispose] when the
  /// instance is released. May be `null`.
  final void Function(T instance)? disposer;

  /// Creates a scoped ViewModel provider from a [creator] and an optional
  /// [disposer]. The resulting instance is reference-counted across all scopes
  /// that bind it and disposed when the last one is gone.
  ViewModelProvider(this.creator, {this.disposer});

  @override
  T createViewModel(StoreSpace space) {
    return creator(space);
  }

  @override
  void disposeViewModel(T instance) {
    disposer?.call(instance);
  }

  /// Creates a store-lifetime ViewModel provider: the ViewModel is created
  /// lazily on first [Store.share], `init()` is called, and it is disposed when
  /// the Store is unmounted. Read it with `context.share(provider)`.
  static SharedProvider<T> shared<T extends ViewModel>(
    T Function(StoreSpace space) creator, {
    void Function(T instance)? disposer,
  }) => SharedProvider.of(ViewModelProvider(creator, disposer: disposer));

  /// Defines a FAMILY of ViewModels keyed by a single argument's value.
  ///
  /// Returns an [ArgVmProviderFactory]; calling it, e.g. `factory(42)`, yields
  /// a concrete provider you can `space.bind` (or `.asShared` for a
  /// store-lifetime per-argument singleton). Arguments are deep-compared via
  /// equatable, so `List`/`Map`/`Set` arguments work as keys; pass
  /// [equatableProps] to customize how an argument maps to its equality key.
  ///
  /// ```dart
  /// final userVmProvider =
  ///     ViewModelProvider.withArgument<UserVm, int>((space, id) => UserVm(id));
  /// final vm = space.bind(userVmProvider(42)); // distinct instance per id
  /// ```
  static ArgVmProviderFactory<T, A> withArgument<T extends ViewModel, A>(
    T Function(StoreSpace space, A arg) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg)? equatableProps,
  }) {
    return ArgVmProviderFactory(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  /// Two-argument family variant — see [withArgument]. Returns an
  /// [ArgVmProviderFactory2] keyed by both argument values.
  static ArgVmProviderFactory2<T, A, B>
  withArgument2<T extends ViewModel, A, B>(
    T Function(StoreSpace space, A arg1, B arg2) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2)? equatableProps,
  }) {
    return ArgVmProviderFactory2(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  /// Three-argument family variant — see [withArgument]. Returns an
  /// [ArgVmProviderFactory3] keyed by all three argument values.
  static ArgVmProviderFactory3<T, A, B, C>
  withArgument3<T extends ViewModel, A, B, C>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3)? equatableProps,
  }) {
    return ArgVmProviderFactory3(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  /// Four-argument family variant — see [withArgument]. Returns an
  /// [ArgVmProviderFactory4] keyed by all four argument values.
  static ArgVmProviderFactory4<T, A, B, C, D>
  withArgument4<T extends ViewModel, A, B, C, D>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4) creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4)? equatableProps,
  }) {
    return ArgVmProviderFactory4(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  /// Five-argument family variant — see [withArgument]. Returns an
  /// [ArgVmProviderFactory5] keyed by all five argument values.
  static ArgVmProviderFactory5<T, A, B, C, D, E>
  withArgument5<T extends ViewModel, A, B, C, D, E>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5)
    creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5)?
    equatableProps,
  }) {
    return ArgVmProviderFactory5(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }

  /// Six-argument family variant — see [withArgument]. Returns an
  /// [ArgVmProviderFactory6] keyed by all six argument values.
  static ArgVmProviderFactory6<T, A, B, C, D, E, F>
  withArgument6<T extends ViewModel, A, B, C, D, E, F>(
    T Function(StoreSpace space, A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)
    creator, {
    void Function(T instance)? disposer,
    List<Object?> Function(A arg1, B arg2, C arg3, D arg4, E arg5, F arg6)?
    equatableProps,
  }) {
    return ArgVmProviderFactory6(
      creator,
      disposer: disposer,
      equatableProps: equatableProps,
    );
  }
}
