// ... existing code ...

import 'package:flutter/widgets.dart';

import 'mixins.dart';
import 'store_space.dart';

/// A function signature for building widgets with scoped store access.
///
/// The [context] provides the build context, [space] provides scoped access
/// to the store, and [child] is an optional pre-built widget for optimization.
typedef ScopedBuilderFunction =
    Widget Function(BuildContext context, StoreSpace space, Widget? child);

/// A widget that provides scoped access to the store through a builder function.
///
/// This widget automatically manages the store space lifecycle and provides
/// scoped access for clean resource management. It's designed to work seamlessly
/// with the store_scope architecture.
///
/// Example:
/// ```dart
/// ScopedBuilder(
///   builder: (context, space, child) {
///     final counter = space.bind(counterProvider);
///     return Text('Counter: $counter');
///   },
/// )
/// ```
///
/// With child optimization:
/// ```dart
/// ScopedBuilder(
///   child: const Icon(Icons.star), // This won't rebuild
///   builder: (context, space, child) {
///     final counter = space.bind(counterProvider);
///     return Row(
///       children: [
///         Text('Counter: $counter'),
///         child!, // Reuse the pre-built child
///       ],
///     );
///   },
/// )
/// ```
class ScopedBuilder extends StatelessWidget with ScopedSpaceStatelessMixin {
  /// Creates a ScopedBuilder widget.
  ///
  /// The [builder] function is called to build the widget tree and receives
  /// the build context, a [StoreSpace] for scoped store access, and an optional
  /// pre-built [child] widget for performance optimization.
  const ScopedBuilder({
    super.key,
    required ScopedBuilderFunction builder,
    Widget? child,
  }) : _builder = builder,
       _child = child;

  final ScopedBuilderFunction _builder;
  final Widget? _child;

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    return _builder(context, space, _child);
  }
}
