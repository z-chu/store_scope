part of 'store_scope.dart';

/// A [StatelessWidget]-style base class that owns its own [Store].
///
/// Subclass this instead of [StatelessWidget] when a widget needs a private
/// dependency-injection container without manually wrapping itself in a
/// [StoreScope]. Each instance gets a fresh [Store] that lives exactly as long
/// as the element is mounted: it is created the first time the element builds
/// and is unmounted (disposing every instance it holds) when the element is
/// removed from the tree.
///
/// Because the [Store] is exposed to the subtree through an inherited widget,
/// the [build] method and any descendants can resolve store-lifetime instances
/// with `context.share(provider)` and bind scoped instances through the store.
///
/// Example:
/// ```dart
/// // counterProvider = Provider.shared((space) => 0);
/// class MyPage extends AutoStoreWidget {
///   const MyPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Resolve the lazy, store-lifetime singleton declared by the provider.
///     final counter = context.share(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
///
/// Note: despite the "stateless" naming, this class extends
/// [AutoStoreStatefulWidget]. A stateful element is required so the owned
/// [Store] can be created and unmounted in step with the widget's lifecycle.
abstract class AutoStoreWidget extends AutoStoreStatefulWidget {
  /// Creates an [AutoStoreWidget].
  ///
  /// The owned [Store] is not created here; it is lazily initialized by the
  /// backing element the first time the widget builds and is unmounted when
  /// that element leaves the tree.
  const AutoStoreWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AutoStoreWidgetState();
  }

  /// Builds the UI for this widget.
  ///
  /// Override this to describe the part of the user interface represented by
  /// the widget. The provided [context] is already located beneath the inherited
  /// widget that exposes this widget's owned [Store], so it can be used directly
  /// with `context.share(provider)` (store-lifetime acquisition) and other
  /// store-backed context extensions.
  Widget build(BuildContext context);
}

/// The internal [State] for [AutoStoreWidget].
/// It simply forwards [build] to the widget so subclasses only implement
/// [AutoStoreWidget.build].
class _AutoStoreWidgetState extends State<AutoStoreWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

/// A [StatefulWidget] base class that owns its own [Store].
///
/// Subclass this instead of [StatefulWidget] when a stateful widget needs a
/// private dependency-injection container without manually wrapping itself in a
/// [StoreScope]. The owned [Store] is bound to the element's lifecycle: it is
/// created on first build and unmounted — disposing every instance it holds —
/// when the element is removed from the tree.
///
/// The [Store] is published to the subtree through an inherited widget, so both
/// the widget's [State.build] and any descendants can resolve store-lifetime
/// instances with `context.share(provider)` and bind scoped instances through
/// the store.
///
/// Example:
/// ```dart
/// // counterProvider = Provider.shared((space) => 0);
/// class MyStatefulPage extends AutoStoreStatefulWidget {
///   const MyStatefulPage({super.key});
///
///   @override
///   State<MyStatefulPage> createState() => _MyStatefulPageState();
/// }
///
/// class _MyStatefulPageState extends State<MyStatefulPage> {
///   @override
///   Widget build(BuildContext context) {
///     final counter = context.share(counterProvider);
///     return Text('Counter: $counter');
///   }
/// }
/// ```
///
/// Key characteristics:
/// - Automatically creates and owns a per-instance [Store].
/// - The store's lifetime is tied to the widget's element lifetime.
/// - All instances held by the store are disposed when the widget unmounts.
/// - The store is exposed to descendants via an inherited widget so they can
///   access it through the store-backed [BuildContext] extensions.
abstract class AutoStoreStatefulWidget extends StatefulWidget {
  /// Creates an [AutoStoreStatefulWidget].
  ///
  /// The owned [Store] is created lazily by the backing element rather than in
  /// this constructor, and is unmounted when the element leaves the tree.
  const AutoStoreStatefulWidget({super.key});

  @override
  StatefulElement createElement() {
    // Create a custom element that manages the Store lifecycle.
    return _AutoStoreStatefulElement(this);
  }
}

/// The custom [StatefulElement] backing [AutoStoreStatefulWidget].
///
/// It implements the [StoreOwner] contract and is responsible for:
/// 1. Creating and owning the [StoreImpl] instance.
/// 2. Exposing the store to descendants through an inherited widget.
/// 3. Unmounting the store (and disposing everything it holds) when the
///    element is removed from the tree.
class _AutoStoreStatefulElement extends StatefulElement implements StoreOwner {
  _AutoStoreStatefulElement(AutoStoreStatefulWidget super.widget);

  /// The owned store, lazily initialized.
  /// Each AutoStoreStatefulWidget has its own independent Store.
  late final StoreImpl _store = StoreImpl();

  @override
  Widget build() {
    // Wrap the child in an inherited widget so the store is reachable from the
    // subtree, e.g. via context.share().
    return _InheritedStoreScope(store: store, child: super.build());
  }

  @override
  void unmount() {
    // Unmount the store when the element is removed, so every provider instance
    // it holds is disposed deterministically.
    unmountStore();
    super.unmount();
  }

  @override
  Store get store => _store;

  @override
  void unmountStore() {
    // Unmount the store and release all of its resources.
    _store.unmount();
  }
}
