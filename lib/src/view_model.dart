import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:store_scope/src/provider.dart' show Provider;

import 'dispose_state_notifier.dart';
import 'store.dart';
import 'store_scope_config.dart';
import 'store_space.dart';

part 'arg_view_model_provider.dart';

/// A base class for ViewModels, integrating with [ChangeNotifier] for UI updates
/// and [ScopeAware] for lifecycle management.
///
/// ViewModels are responsible for holding and managing UI-related data and business logic.
/// They notify listeners (typically UI widgets) when data changes, and they can manage
/// resources that need to be cleaned up when the ViewModel is no longer in use.
///
/// Lifecycle:
/// 1. **Creation**: Instantiated by a [ViewModelProvider].
/// 2. **Initialization**: The [init] method is called after creation.
/// 3. **Usage**: Bound to UI components, providing data and handling events.
/// 4. **Disposal**: The [dispose] method is called to clean up resources.
///
/// Resource Management:
/// - Use [addCloseable] and [addKeyedCloseable] to register callbacks for resource cleanup
///   during the [dispose] phase.
/// - The ViewModel's [scope] (from [ScopeAware]) is tied to its lifecycle and will
///   notify listeners upon disposal.
abstract class ViewModel extends ChangeNotifier implements ScopeAware {
  final _viewModelScope = DisposeStateNotifier();
  final Map<String, VoidCallback> _keyToCloseables = {};
  final Set<VoidCallback> _closeables = {};

  @override
  Listenable get scope => _viewModelScope;

  /// Returns `true` if this ViewModel has been disposed.
  /// Once disposed, a ViewModel should not be used anymore.
  bool get disposed => _viewModelScope.disposed;

  /// Called once after the ViewModel is created by a [ViewModelProvider].
  ///
  /// Override this method to perform initialization tasks such as setting up
  /// listeners, fetching initial data, etc.
  void init() {}

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    final allCloseables = [..._closeables, ..._keyToCloseables.values];
    for (var closeable in allCloseables) {
      _closeWithException(closeable);
    }
    _keyToCloseables.clear();
    _closeables.clear();
    _viewModelScope.dispose();
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
      _viewModelScope.removeListener(oldCloseable);
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
          'Failed to close $error in $runtimeType\n'
          'Stack trace:\n$stackTrace',
        );
      } else {
        StoreScopeConfig.log(
          'Failed to close $error in $runtimeType\n'
          'Stack trace:\n$stackTrace',
          isError: true,
        );
      }
    }
  }
}

/// An abstract base class for providing [ViewModel] instances.
///
/// It extends [Provider] and handles the basic lifecycle of a [ViewModel],
/// including calling [ViewModel.init] after creation and [ViewModel.dispose]
/// during its own disposal.
///
/// Subclasses must implement [createViewModel] and can optionally implement
/// [disposeViewModel] for custom disposal logic beyond what the ViewModel itself handles.
abstract class ViewModelProviderBase<T extends ViewModel> extends Provider<T> {
  @override
  @nonVirtual
  T createInstance(StoreSpace space) {
    final vm = createViewModel(space);
    vm.init();
    return vm;
  }

  @override
  @nonVirtual
  void disposeInstance(T instance) {
    instance.dispose();
    disposeViewModel(instance);
  }

  /// Creates an instance of the [ViewModel].
  ///
  /// This method is called by [createInstance] after which [ViewModel.init]
  /// will be automatically invoked on the created ViewModel.
  ///
  /// - [space]: The [StoreSpace] providing access to the [Store] and the
  ///            ViewModel's own lifecycle [Listenable] scope.
  /// Returns a new instance of the ViewModel.
  T createViewModel(StoreSpace space);

  /// Called when the [ViewModelProvider] is disposed and the [instance] of the
  /// [ViewModel] it created is about to be cleaned up.
  ///
  /// This method is called after [ViewModel.dispose]. Override this to perform
  /// any additional cleanup specific to the provider that isn't handled by the
  /// ViewModel's own [dispose] method.
  ///
  /// - [instance]: The ViewModel instance that was created by this provider.
  void disposeViewModel(T instance) {}
}

/// A concrete implementation of [ViewModelProviderBase] that uses a creator
/// function to instantiate the [ViewModel].
///
/// - [T]: The type of the [ViewModel].
class ViewModelProvider<T extends ViewModel> extends ViewModelProviderBase<T> {
  /// A function that creates an instance of the [ViewModel].
  final T Function(StoreSpace space) creator;

  /// An optional function that is called when the [ViewModel] instance is disposed.
  /// This is called after [ViewModel.dispose].
  final void Function(T instance)? disposer;

  /// Creates a [ViewModelProvider].
  ///
  /// - [creator]: The function to create the [ViewModel] instance.
  /// - [disposer]: An optional function for additional cleanup when the
  ///               [ViewModel] is disposed. This is called after [ViewModel.dispose].
  ViewModelProvider(this.creator, {this.disposer});

  @override
  T createViewModel(StoreSpace space) {
    return creator(space);
  }

  @override
  void disposeViewModel(T instance) {
    disposer?.call(instance);
  }

  /// Creates an [ArgVmProviderFactory] for [ViewModel]s that require one argument for creation.
  ///
  /// This factory allows creating providers that depend on a runtime argument.
  /// The returned factory can be called with the argument to get a specific [Provider] instance.
  ///
  /// - [T]: The type of the [ViewModel].
  /// - [A]: The type of the argument.
  /// - [creator]: A function that takes a [StoreSpace] and argument [A] to create the [ViewModel].
  /// - [disposer]: Optional. A function to dispose the [ViewModel] instance.
  /// - [equatableProps]: Optional. A function to generate props for `Equatable` from the argument,
  ///   ensuring that providers created with equivalent arguments are treated as equal.
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

  /// Creates an [ArgVmProviderFactory2] for [ViewModel]s that require two arguments for creation.
  /// See [withArgument] for more details.
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

  /// Creates an [ArgVmProviderFactory3] for [ViewModel]s that require three arguments for creation.
  /// See [withArgument] for more details.
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

  /// Creates an [ArgVmProviderFactory4] for [ViewModel]s that require four arguments for creation.
  /// See [withArgument] for more details.
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

  /// Creates an [ArgVmProviderFactory5] for [ViewModel]s that require five arguments for creation.
  /// See [withArgument] for more details.
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

  /// Creates an [ArgVmProviderFactory6] for [ViewModel]s that require six arguments for creation.
  /// See [withArgument] for more details.
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
