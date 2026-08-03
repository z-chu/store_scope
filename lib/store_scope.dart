/// store_scope — Flutter's Jetpack ViewModel.
///
/// Widget-tree-scoped dependency injection with automatic disposal, zero
/// codegen, no global singletons, and bring-your-own reactivity.
///
/// The model is small:
///
/// * A [Store] is a DI container. It lives for as long as the [StoreScope]
///   widget that owns it.
/// * A [Provider] is a recipe for an instance. Its lifetime is declared where
///   it is *defined*:
///   * [Provider.from] / [ViewModelProvider.new] — **scoped**: acquired with
///     `space.bind(p)`, reference-counted, disposed when the last scope that
///     bound it is gone.
///   * [Provider.shared] / [ViewModelProvider.shared] — **store-lifetime**:
///     acquired scope-free with `store.share(p)` / `context.share(p)`, kept
///     alive until the Store unmounts.
///   * [Provider.withArgument] (`withArgument`..`withArgument6`) builds a
///     family of instances keyed by argument value; add `.asShared` at the
///     definition site to make that family store-lifetime.
/// * A [ViewModel] is a Jetpack-style holder with `init()` / `dispose()` and
///   `addCloseable` / `addKeyedCloseable` / `addSubscription` for deterministic
///   teardown.
///
/// Dependencies compose as plain Dart: a provider's body may `space.bind`
/// another provider, and the child is disposed together with its parent — no
/// graph DSL.
///
/// ```dart
/// final counterProvider = ViewModelProvider<CounterVm>((space) => CounterVm());
///
/// void main() => runApp(const StoreScope(child: MyApp()));
///
/// class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
///   const CounterPage({super.key});
///   @override
///   Widget buildWithSpace(BuildContext context, StoreSpace space) {
///     final vm = space.bind(counterProvider); // disposed with this widget
///     return ValueListenableBuilder<int>(
///       valueListenable: vm.count,
///       builder: (_, value, __) => Text('$value'),
///     );
///   }
/// }
/// ```
///
/// store_scope deliberately ships **no reactivity of its own** — pair it with
/// `ValueNotifier`, `signals`, `flutter_bloc`, or anything else. See the README
/// for recipes, a comparison with other solutions, and testing with
/// `StoreScope(overrides: ...)`.
library;

export 'src/store_scope.dart';
export 'src/store.dart';
// `show`: the library also declares a top-level `LogWriterCallback` typedef and
// a `defaultLogWriterCallback` function, both carrying GetX's exact names. A
// bare export would make any file that imports both packages unprefixed fail to
// compile with `ambiguous_import`. Assigning `StoreScopeConfig.log` needs
// neither name — the closure's type is inferred.
export 'src/store_scope_config.dart' show StoreScopeConfig;
export 'src/provider.dart';
export 'src/dispose_state_notifier.dart';
export 'src/view_model.dart';
export 'src/store_space.dart';
export 'src/mixins.dart';
export 'src/scoped_builder.dart';
