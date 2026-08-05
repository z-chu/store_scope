import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../store_scope.dart';

/// Disposes [old] as soon as it is safe to run the instance disposers hanging
/// off it, releasing everything bound against that scope.
///
/// Both scoped mixins re-check the ambient [Store] from a getter that is
/// normally read during `build`. Disposing inline there would run instance
/// disposers mid-build — a disposer that calls `notifyListeners` would trip
/// "markNeedsBuild called during build" — so the release is deferred to the end
/// of the frame.
///
/// That deferral is only valid while a frame is actually in flight.
/// [SchedulerBinding.addPostFrameCallback] does **not** schedule a frame of its
/// own, so registering one from an idle scheduler (a `State` reading `space`
/// from an `onPressed`, a `Timer`, or a stream listener after a [GlobalKey]
/// reparent went unnoticed by an intervening build) hands the notifier to a
/// callback that may never run — leaking the old scope and every instance bound
/// through it. Outside a frame there is nothing to protect, so dispose inline.
void _releaseWhenSafe(DisposeStateNotifier old) {
  switch (SchedulerBinding.instance.schedulerPhase) {
    // A frame is in flight and its post-frame callbacks are still ahead of us.
    case SchedulerPhase.transientCallbacks:
    case SchedulerPhase.midFrameMicrotasks:
    case SchedulerPhase.persistentCallbacks:
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    // Idle, or already draining post-frame callbacks — deferring would push the
    // work onto a frame nobody has scheduled. The build phase is over either
    // way, so running disposers now is safe.
    case SchedulerPhase.postFrameCallbacks:
    case SchedulerPhase.idle:
      old.dispose();
  }
}

/// A mixin that gives a [StatelessWidget] its own disposal-tracked [StoreSpace].
///
/// The mixin installs a dedicated [Element] that owns a [DisposeStateNotifier]
/// and pairs it with the ambient [Store] as a [StoreSpace]. Calling
/// `space.bind(provider)` acquires an instance scoped to this widget: bindings
/// are reference-counted across every scope that binds the same provider, so the
/// instance is disposed only when the last binding scope is gone. Because the
/// element disposes its notifier when it unmounts, everything bound through this
/// widget is released deterministically the moment it leaves the tree.
///
/// **This mixin requires a [StoreScope] ancestor.** The space is materialised as
/// the [buildScoped] argument on every build, so the ambient [Store] is resolved
/// on every build too — a widget with this mixin throws when it is built outside
/// any [StoreScope], even if its [buildScoped] never touches the `space`. If all
/// you want is a disposal [Listenable] with no DI container behind it, use a
/// [DisposeStateNotifier] in a [StatefulWidget] directly.
///
/// The [StoreSpace] object itself is cached, and rebuilt only when the ambient
/// [Store] changes (for example when a [GlobalKey] reparents this subtree
/// beneath a different [StoreScope]).
///
/// Need a raw [Listenable] scope rather than the space — to call
/// `store.bindWith(provider, scope)` or to hand the lifetime to something else?
/// Use `space.scope`. For store-lifetime singletons reach for
/// `context.share` / [Store.share] and a [Provider.shared] recipe, which need no
/// scope at all.
///
/// It is the [StatelessWidget] counterpart to [ScopedStateMixin].
///
/// **Usage:** Override [buildScoped] instead of [build].
///
/// Example:
/// ```dart
/// class MyWidget extends StatelessWidget with ScopedStatelessMixin {
///   const MyWidget({super.key});
///
///   @override
///   Widget buildScoped(BuildContext context, StoreSpace space) {
///     final counter = space.bind(counterProvider);
///     return Text('Counter: ${counter.value}');
///   }
/// }
/// ```
mixin ScopedStatelessMixin on StatelessWidget {
  /// Sealed entry point that forwards to [buildScoped] with this widget's
  /// [StoreSpace].
  ///
  /// Marked [nonVirtual]: do not override it. It requires the dedicated element
  /// installed by [createElement]; using this mixin without that element throws
  /// a [StateError].
  @override
  @nonVirtual
  Widget build(BuildContext context) {
    if (context is! _ScopedStatelessElement) {
      throw StateError(
        'ScopedStatelessMixin must be used with its own Element',
      );
    }
    return buildScoped(context, context.space);
  }

  /// Build the widget with the given store space.
  ///
  /// **IMPORTANT:**
  /// - Do NOT override the [build] method when using this mixin
  /// - Override this method instead to build your widget
  /// - The [space] parameter provides scoped access to the store and will be
  ///   automatically disposed when the widget is removed
  ///
  /// Call `space.bind(provider)` to acquire scoped instances tied to this
  /// widget's lifetime, `space.scope` for the raw [Listenable] scope, or
  /// `space.share(provider)` for store-lifetime singletons (a [StoreSpace] *is*
  /// a [Store], so every [Store] method is available on it directly).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildScoped(BuildContext context, StoreSpace space) {
  ///   final counter = space.bind(counterProvider);
  ///   return Text('Counter: $counter');
  /// }
  /// ```
  @protected
  Widget buildScoped(BuildContext context, StoreSpace space);

  /// Creates the dedicated element that owns this widget's [StoreSpace] and its
  /// disposable scope.
  ///
  /// The returned element implements [ScopeAware], tracks the ambient [Store],
  /// rebuilds the space when it changes, and disposes the scope on unmount;
  /// [build] relies on it being present.
  @override
  StatelessElement createElement() => _ScopedStatelessElement(this);
}

class _ScopedStatelessElement extends StatelessElement implements ScopeAware {
  _ScopedStatelessElement(ScopedStatelessMixin super.widget);

  DisposeStateNotifier _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  @override
  Listenable get scope => _disposeNotifier;

  StoreSpace get space {
    // Resolved on every build, so report the failure in terms of the mixin
    // rather than letting `context.store` blame an API the widget never called.
    final current = storeOrNull;
    if (current == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No StoreScope found for a ScopedStatelessMixin widget'),
        ErrorDescription(
          '${widget.runtimeType} mixes in ScopedStatelessMixin, which hands '
          'buildScoped a StoreSpace built from the ambient Store. That lookup '
          'happens on every build, so the widget needs a StoreScope ancestor '
          'even when buildScoped never touches the space.',
        ),
        ErrorHint(
          'Add a StoreScope above this widget. If all you wanted was a disposal '
          'Listenable with no DI container behind it, drop the mixin and use a '
          'DisposeStateNotifier inside a StatefulWidget instead.',
        ),
        describeElement('The widget being built was'),
      ]);
    }
    if (_space == null) {
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
    } else if (_currentStore != current) {
      // The ambient Store changed under a surviving element (e.g. a GlobalKey
      // reparented this subtree beneath a different StoreScope). We detect it
      // here — on each build that reads `space` — rather than in
      // didChangeDependencies, which is not called for a pure `space.bind`
      // widget (the store lookup registers no inherited-widget dependency). Bind
      // to the new store on a fresh scope NOW, and release the OLD scope once it
      // is safe to run its disposers (see [_releaseWhenSafe]).
      final old = _disposeNotifier;
      _disposeNotifier = DisposeStateNotifier();
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
      _releaseWhenSafe(old);
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

/// A mixin that gives a [State] its own disposal-tracked [StoreSpace], turning
/// the widget into a [ScopeAware] binding point for scoped providers.
///
/// The mixin owns a private [DisposeStateNotifier] and pairs it with the ambient
/// [Store] as a [StoreSpace]. Calling `space.bind(provider)` acquires an
/// instance scoped to this widget: bindings are reference-counted across every
/// scope that binds the same provider, so the instance is disposed only when the
/// last binding scope is gone. Because this mixin disposes its notifier inside
/// [dispose], every instance bound through it is released deterministically the
/// moment this [State] leaves the tree.
///
/// Need a raw [Listenable] scope rather than the space — to call
/// `store.bindWith(provider, scope)` or to hand the lifetime to something else?
/// Use [scope], which never touches the store. For store-lifetime singletons
/// reach for [Store.share] / `context.share` and a [Provider.shared] recipe,
/// which need no scope at all.
///
/// It is the [StatefulWidget] counterpart to [ScopedStatelessMixin].
///
/// Example:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> with ScopedStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     // Acquire an instance scoped to this widget's lifetime. Bind on every
///     // build rather than caching in a field — binding is idempotent, and a
///     // cached instance would outlive a store swap that should have replaced
///     // it (see [scope]).
///     final counter = space.bind(counterProvider);
///
///     return Text('Counter: ${counter.value}');
///   }
/// }
/// ```
mixin ScopedStateMixin<T extends StatefulWidget> on State<T>
    implements ScopeAware {
  DisposeStateNotifier _disposeNotifier = DisposeStateNotifier();
  Store? _currentStore;
  StoreSpace? _space;

  /// The [Listenable] whose notification marks the end of this widget's scope.
  ///
  /// It is the same scope baked into [space], and fires when this [State] is
  /// disposed, releasing every instance bound through it. Pass it to scoped
  /// acquisition APIs such as `store.bindWith(provider, scope)` when you need to
  /// bind against a store other than the ambient one; otherwise prefer [space].
  ///
  /// **The notifier this returns is not stable if the widget also uses [space].**
  /// Reading [space] after the ambient [Store] changed (a [GlobalKey] reparent
  /// beneath a different [StoreScope]) starts a *fresh* notifier and releases
  /// this one, so a field like `late final x = store.bindWith(p, scope)` would
  /// keep pointing at an instance that has already been disposed — silently, and
  /// only in that reparent case. Re-read [scope] and re-bind on every build
  /// instead of caching the result. A widget that never touches [space] is
  /// unaffected: without it the notifier is never swapped.
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
  /// scoped acquisition or `space.share(p)` for store-lifetime singletons (a
  /// [StoreSpace] *is* a [Store], so every [Store] method is available on it
  /// directly).
  StoreSpace get space {
    final current = context.store;
    if (_space == null) {
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
    } else if (_currentStore != current) {
      // Start a fresh scope NOW so this build binds to the new store, and
      // release the OLD scope once it is safe to run its disposers. Unlike the
      // element above, this getter is public and can be read from outside a
      // frame, which is exactly the case [_releaseWhenSafe] has to handle.
      final old = _disposeNotifier;
      _disposeNotifier = DisposeStateNotifier();
      _currentStore = current;
      _space = StoreSpace(current, _disposeNotifier);
      _releaseWhenSafe(old);
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
