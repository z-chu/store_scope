import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../store_scope.dart';

/// A mixin that gives a [State] its own disposal-tracked [scope], turning the
/// widget into a [ScopeAware] binding point for scoped providers.
///
/// The mixin owns a private [DisposeStateNotifier] and exposes it through
/// [scope]. Use that [scope] with `store.bindWith(provider, scope)` (or
/// `context.store.bindWith(provider, scope)`) to acquire scoped instances from
/// a [Provider.from] recipe. Binding is reference-counted across every scope that binds the same
/// provider, so the instance is disposed only when the last binding scope is
/// gone. Because this mixin disposes its notifier inside [dispose], every
/// instance bound through it is released deterministically the moment this
/// [State] leaves the tree.
///
/// Prefer this mixin when you need scoped (reference-counted) acquisition tied
/// to a [StatefulWidget]'s lifetime but do not need a full [StoreSpace]. If you
/// want the store baked in alongside the scope, use [ScopedSpaceStateMixin]
/// instead; for store-lifetime singletons reach for [Store.share] /
/// `context.share` and a [Provider.shared] recipe, which need no scope at all.
///
/// Example:
/// ```dart
/// class _CounterPageState extends State<CounterPage> with ScopedStateMixin {
///   late final counter = context.store.bindWith(counterProvider, scope);
///
///   @override
///   Widget build(BuildContext context) => Text('Counter: ${counter.value}');
/// }
/// ```
mixin ScopedStateMixin<T extends StatefulWidget> on State<T>
    implements ScopeAware {
  late final _disposeNotifier = DisposeStateNotifier();

  /// The [Listenable] whose notification marks the end of this widget's scope.
  ///
  /// Pass it to scoped acquisition APIs such as `store.bindWith(provider, scope)`.
  /// It fires (and releases the instances bound through it) when this [State] is
  /// disposed.
  @override
  Listenable get scope => _disposeNotifier;

  /// Disposes the backing scope notifier, releasing every instance bound through
  /// [scope], then defers to `super.dispose`.
  ///
  /// Always call `super.dispose()` if you override this further down your class.
  @override
  void dispose() {
    _disposeNotifier.dispose();
    super.dispose();
  }
}

/// A mixin that provides dispose state tracking capability for [StatelessWidget]s.
///
/// This mixin creates and manages a [DisposeStateNotifier] that will be disposed
/// when the widget is removed from the tree, exposing it as a [ScopeAware]
/// [scope]. Use that scope with `context.store.bindWith(provider, scope)` to
/// acquire scoped [Provider.from] instances; they are reference-counted and the
/// instance is disposed once the last binding scope (including this one) is gone.
/// It is the [StatelessWidget] counterpart to [ScopedStateMixin].
///
/// **Usage:** Override [buildScoped] instead of [build].
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with ScopedStatelessMixin {
///   @override
///   Widget buildScoped(BuildContext context, Listenable scope) {
///     final data = context.store.bindWith(dataProvider, scope);
///     return Text('Data: $data');
///   }
/// }
/// ```
mixin ScopedStatelessMixin on StatelessWidget {
  /// Sealed entry point that forwards to [buildScoped] with this widget's scope.
  ///
  /// Marked [nonVirtual]: do not override it. It requires the dedicated element
  /// installed by [createElement]; using this mixin without that element throws
  /// a [StateError].
  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (context is! _DisposeAwareStatelessElement) {
      throw StateError(
        'ScopedStatelessMixin must be used with its own Element',
      );
    }
    return buildScoped(context, context.scope);
  }

  /// Build the widget with the given scope.
  ///
  /// **IMPORTANT:**
  /// - Do NOT override the [build] method when using this mixin
  /// - Override this method instead to build your widget
  /// - The [scope] parameter will be automatically disposed when the widget is removed
  ///
  /// Use [scope] with scoped acquisition (`context.store.bindWith(provider, scope)`):
  /// the instance is reference-counted and disposed when the last scope binding
  /// it — this widget's included — is gone.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildScoped(BuildContext context, Listenable scope) {
  ///   final counter = context.store.bindWith(counterProvider, scope);
  ///   return Text('Counter: $counter');
  /// }
  /// ```
  @protected
  Widget buildScoped(BuildContext context, Listenable scope);

  /// Creates the dedicated element that owns this widget's disposable scope.
  ///
  /// The returned element implements [ScopeAware] and disposes the scope when
  /// it unmounts; [build] relies on it being present.
  @override
  StatelessElement createElement() => _DisposeAwareStatelessElement(this);
}

class _DisposeAwareStatelessElement extends StatelessElement
    implements ScopeAware {
  _DisposeAwareStatelessElement(ScopedStatelessMixin super.widget);

  final _disposeNotifier = DisposeStateNotifier();

  @override
  void unmount() {
    _disposeNotifier.dispose();
    super.unmount();
  }

  @override
  Listenable get scope => _disposeNotifier;
}

// ... existing code ...

/// A mixin that provides store space management capability for [StatelessWidget]s.
///
/// This mixin creates and manages a [StoreSpace] instance that will be automatically
/// updated when the store in the widget tree changes, and disposed when the widget
/// is removed from the tree.
///
/// The [StoreSpace] pairs the ambient [Store] with a baked-in scope, so calling
/// `space.bind(provider)` acquires an instance scoped to this widget — no need to
/// thread a separate [Listenable] around as with [ScopedStatelessMixin]. Bound
/// instances are reference-counted and cleaned up automatically when the widget
/// is disposed. It is the [StatelessWidget] counterpart to [ScopedSpaceStateMixin].
///
/// **Usage:** Override [buildWithSpace] instead of [build].
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with ScopedSpaceStatelessMixin {
///   @override
///   Widget buildWithSpace(BuildContext context, StoreSpace space) {
///     final counter = space.bind(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
mixin ScopedSpaceStatelessMixin on StatelessWidget {
  /// Sealed entry point that forwards to [buildWithSpace] with this widget's
  /// [StoreSpace].
  ///
  /// Marked [nonVirtual]: do not override it. It requires the dedicated element
  /// installed by [createElement]; using this mixin without that element throws
  /// a [StateError].
  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (context is! _SpaceAwareStatelessElement) {
      throw StateError(
        'ScopedSpaceStatelessMixin must be used with its own Element',
      );
    }
    return buildWithSpace(context, context.space);
  }

  /// Build the widget with the given store space.
  ///
  /// **IMPORTANT:**
  /// - Do NOT override the [build] method when using this mixin
  /// - Override this method instead to build your widget
  /// - The [space] parameter provides scoped access to the store and will be automatically disposed when the widget is removed
  ///
  /// Call `space.bind(provider)` to acquire scoped instances tied to this
  /// widget's lifetime, or `space.store.share(provider)` for store-lifetime
  /// singletons. The [StoreSpace] is rebuilt automatically if the ambient
  /// [Store] changes.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildWithSpace(BuildContext context, StoreSpace space) {
  ///   final counter = space.bind(counterProvider);
  ///   return Text('Counter: $counter');
  /// }
  /// ```
  @protected
  Widget buildWithSpace(BuildContext context, StoreSpace space);

  /// Creates the dedicated element that owns this widget's [StoreSpace] and its
  /// disposable scope.
  ///
  /// The returned element tracks the ambient [Store], rebuilds the space when it
  /// changes, and disposes the scope on unmount; [build] relies on it being present.
  @override
  StatelessElement createElement() => _SpaceAwareStatelessElement(this);
}

class _SpaceAwareStatelessElement extends StatelessElement
    implements ScopeAware {
  _SpaceAwareStatelessElement(ScopedSpaceStatelessMixin super.widget);

  DisposeStateNotifier _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  @override
  Listenable get scope => _disposeNotifier;

  StoreSpace get space {
    final current = store;
    if (_space == null) {
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
    } else if (_currentStore != current) {
      // The ambient Store changed under a surviving element (e.g. a GlobalKey
      // reparented this subtree beneath a different StoreScope). We detect it
      // here — on each build that reads `space` — rather than in
      // didChangeDependencies, which is not called for a pure `space.bind`
      // widget (the store lookup registers no inherited-widget dependency). Bind
      // to the new store on a fresh scope NOW, and release the OLD scope AFTER
      // the frame: disposing inline would run instance disposers mid-build and
      // could trip "markNeedsBuild during build".
      final old = _disposeNotifier;
      _disposeNotifier = DisposeStateNotifier();
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _space!;
  }

  @override
  void unmount() {
    _disposeNotifier.dispose();
    _space = null;
    _currentStore = null;
    super.unmount();
  }
}

/// A mixin that provides store space management capability for [StatefulWidget]s.
///
/// This mixin creates and manages a [StoreSpace] instance that will be automatically
/// updated when the store in the widget tree changes, and disposed when the widget
/// is removed from the tree.
///
/// The [StoreSpace] pairs the ambient [Store] with a baked-in scope, so calling
/// `space.bind(provider)` acquires an instance scoped to this widget — bound
/// instances are reference-counted and disposed automatically when this [State]
/// leaves the tree. It is the [StatefulWidget] counterpart to
/// [ScopedSpaceStatelessMixin]; use [ScopedStateMixin] if you want a raw [scope]
/// without the store baked in.
///
/// Example:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with ScopedSpaceStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     // Acquire an instance scoped to this widget's lifetime.
///     final counter = space.bind(counterProvider);
///
///     return Text('Counter: ${counter.value}');
///   }
/// }
/// ```
mixin ScopedSpaceStateMixin<T extends StatefulWidget> on State<T>
    implements ScopeAware {
  DisposeStateNotifier _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  /// The [Listenable] whose notification marks the end of this widget's scope.
  ///
  /// It is the same scope baked into [space], and fires when this [State] is
  /// disposed, releasing every instance bound through the space.
  @override
  Listenable get scope => _disposeNotifier;

  /// The [StoreSpace] for this widget: the ambient [Store] paired with this
  /// widget's [scope].
  ///
  /// Lazily created on first access from `context.store`, then reused. On each
  /// access it re-checks the ambient store: if it changed (e.g. this [State] was
  /// reparented via a [GlobalKey] beneath a different [StoreScope]), the old
  /// scope is disposed — releasing everything bound against the previous store —
  /// and a fresh scope starts for the new store. This is checked here rather
  /// than in [didChangeDependencies], which is not called for a pure
  /// `space.bind` widget (the store lookup registers no inherited-widget
  /// dependency, so a reparent never notifies it). Call `space.bind(p)` for
  /// scoped acquisition or `space.store.share(p)` for store-lifetime singletons.
  StoreSpace get space {
    final current = context.store;
    if (_space == null) {
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
    } else if (_currentStore != current) {
      // Start a fresh scope NOW so this build binds to the new store, but
      // release the OLD scope AFTER the frame: this getter runs during build,
      // and disposing inline would run instance disposers mid-build (a disposer
      // that calls notifyListeners would trip "markNeedsBuild during build").
      final old = _disposeNotifier;
      _disposeNotifier = DisposeStateNotifier();
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return _space!;
  }

  /// Disposes the backing scope notifier — releasing every instance bound through
  /// [space] — clears the cached space, then defers to `super.dispose`.
  ///
  /// Always call `super.dispose()` if you override this further down your class.
  @override
  void dispose() {
    _disposeNotifier.dispose();
    _space = null;
    _currentStore = null;
    super.dispose();
  }
}
