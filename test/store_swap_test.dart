import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

class _SwapProbe extends StatefulWidget {
  const _SwapProbe({super.key, required this.provider});
  final Provider<Object> provider;
  @override
  State<_SwapProbe> createState() => _SwapProbeState();
}

class _SwapProbeState extends State<_SwapProbe> with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    // Pure bind-only widget: no other inherited-widget dependency. The store
    // swap is detected in the `space` getter, so a GlobalKey reparent is picked
    // up on the next build without any contrived dependency to force it.
    space.bind(widget.provider);
    return const SizedBox();
  }
}

class _NotifyingVm extends ViewModel {
  @override
  void init() {
    super.init();
    // A disposer that reaches markNeedsBuild — the cheapest probe for "did this
    // run at a moment the framework forbids it". Not an endorsed pattern:
    // Provider.disposeInstance forbids notifying from teardown outright.
    // Here it only has to survive the *swap* path, which defers past the build
    // phase; the teardown paths are a documented caller error.
    addCloseable(notifyListeners);
  }
}

class _VmBinder extends StatefulWidget {
  const _VmBinder({super.key, required this.provider});
  final ViewModelProvider<_NotifyingVm> provider;
  @override
  State<_VmBinder> createState() => _VmBinderState();
}

class _VmBinderState extends State<_VmBinder> with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    space.bind(widget.provider);
    return const SizedBox();
  }
}

/// Reads `space` only on demand, so a reparent can slip past without any build
/// noticing the swap — leaving it to be discovered later, from outside a frame.
class _ConditionalProbe extends StatefulWidget {
  const _ConditionalProbe({
    super.key,
    required this.provider,
    required this.readSpace,
  });
  final Provider<Object> provider;
  final bool readSpace;
  @override
  State<_ConditionalProbe> createState() => _ConditionalProbeState();
}

class _ConditionalProbeState extends State<_ConditionalProbe>
    with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    if (widget.readSpace) space.bind(widget.provider);
    return const SizedBox();
  }
}

/// Reads `space` based on a mutable module-level switch rather than a widget
/// field, so a `reassemble` (hot reload) rebuild can be the *first* build that
/// notices a swap — which is what editing a `build` method on reload does.
bool _hotReloadReadsSpace = false;

class _ReloadProbe extends StatefulWidget {
  const _ReloadProbe({super.key, required this.provider});
  final Provider<Object> provider;
  @override
  State<_ReloadProbe> createState() => _ReloadProbeState();
}

class _ReloadProbeState extends State<_ReloadProbe> with ScopedStateMixin {
  @override
  Widget build(BuildContext context) {
    if (_hotReloadReadsSpace) space.bind(widget.provider);
    return const SizedBox();
  }
}

/// The [StatelessWidget] counterparts. The swap logic lives in a second place —
/// the element installed by [ScopedStatelessMixin] — and `ScopedBuilder` rides
/// on it, so it needs the same coverage as the `State` side above.
class _StatelessSwapProbe extends StatelessWidget with ScopedStatelessMixin {
  const _StatelessSwapProbe({super.key, required this.provider});
  final Provider<Object> provider;

  @override
  Widget buildScoped(BuildContext context, StoreSpace space) {
    space.bind(provider);
    return const SizedBox();
  }
}

class _StatelessVmBinder extends StatelessWidget with ScopedStatelessMixin {
  const _StatelessVmBinder({super.key, required this.provider});
  final ViewModelProvider<_NotifyingVm> provider;

  @override
  Widget buildScoped(BuildContext context, StoreSpace space) {
    space.bind(provider);
    return const SizedBox();
  }
}

void main() {
  testWidgets(
    'reparenting across StoreScopes releases old-store binds and rebinds',
    (tester) async {
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      final storeA = ownerA.store;
      final storeB = ownerB.store;

      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final childKey = GlobalKey();

      Widget tree({required bool underB}) {
        final child = _SwapProbe(key: childKey, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : child,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false));
      expect(storeA.exists(provider), isTrue, reason: 'bound in A first');
      expect(storeB.exists(provider), isFalse);
      expect(disposeCount, 0);

      await tester.pumpWidget(tree(underB: true)); // GlobalKey reparent A -> B

      expect(disposeCount, 1, reason: 'old-store bind released on swap');
      expect(
        storeA.exists(provider),
        isFalse,
        reason: 'A released (not leaked)',
      );
      expect(storeB.exists(provider), isTrue, reason: 'rebound in B');
    },
  );

  testWidgets(
    'swap that disposes a listened ViewModel does not throw during build',
    (tester) async {
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      final key = GlobalKey();
      final provider = ViewModelProvider<_NotifyingVm>(
        (space) => _NotifyingVm(),
      );

      Widget tree({required bool underB}) {
        final binder = _VmBinder(key: key, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              // A sibling that observes the VM bound in store A. When the swap
              // disposes that VM, its disposer notifies this listener — which
              // must not happen during the build phase.
              Builder(
                builder: (context) {
                  final vm = ownerA.store.find(provider);
                  if (vm == null) return const SizedBox();
                  return ListenableBuilder(
                    listenable: vm,
                    builder: (_, __) => const SizedBox(),
                  );
                },
              ),
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : binder,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? binder : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(tree(underB: true)); // reparent disposes A's VM
      expect(
        tester.takeException(),
        isNull,
        reason:
            'disposing a listened VM on swap must defer past the build phase',
      );
    },
  );

  testWidgets(
    'stateless: reparenting across StoreScopes releases old-store binds and rebinds',
    (tester) async {
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      final storeA = ownerA.store;
      final storeB = ownerB.store;

      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final childKey = GlobalKey();

      Widget tree({required bool underB}) {
        final child = _StatelessSwapProbe(key: childKey, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : child,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false));
      expect(storeA.exists(provider), isTrue, reason: 'bound in A first');
      expect(storeB.exists(provider), isFalse);
      expect(disposeCount, 0);

      await tester.pumpWidget(tree(underB: true)); // GlobalKey reparent A -> B

      expect(disposeCount, 1, reason: 'old-store bind released on swap');
      expect(
        storeA.exists(provider),
        isFalse,
        reason: 'A released (not leaked)',
      );
      expect(storeB.exists(provider), isTrue, reason: 'rebound in B');
    },
  );

  testWidgets(
    'stateless: swap that disposes a listened ViewModel does not throw during build',
    (tester) async {
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      final key = GlobalKey();
      final provider = ViewModelProvider<_NotifyingVm>(
        (space) => _NotifyingVm(),
      );

      Widget tree({required bool underB}) {
        final binder = _StatelessVmBinder(key: key, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  final vm = ownerA.store.find(provider);
                  if (vm == null) return const SizedBox();
                  return ListenableBuilder(
                    listenable: vm,
                    builder: (_, __) => const SizedBox(),
                  );
                },
              ),
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : binder,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? binder : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(tree(underB: true)); // reparent disposes A's VM
      expect(
        tester.takeException(),
        isNull,
        reason:
            'disposing a listened VM on swap must defer past the build phase',
      );
    },
  );

  testWidgets(
    'stateless: unmounting in the same frame as a swap disposes both scopes once',
    (tester) async {
      // The swap hands the *old* scope to a post-frame callback while `unmount`
      // disposes the *new* one. They must be distinct notifiers, so neither
      // binding leaks and neither scope is disposed twice.
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final childKey = GlobalKey();

      Widget tree({required int phase}) {
        final child = _StatelessSwapProbe(key: childKey, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: phase == 0 ? child : const SizedBox(),
              ),
              StoreScope(
                storeOwner: ownerB,
                child: phase == 1 ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(phase: 0));
      await tester.pumpWidget(tree(phase: 1)); // A -> B
      await tester.pumpWidget(tree(phase: 2)); // gone entirely
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        disposeCount,
        2,
        reason: 'both the A bind and the B bind released',
      );
      expect(ownerA.store.exists(provider), isFalse);
      expect(ownerB.store.exists(provider), isFalse);
    },
  );

  testWidgets(
    'a swap noticed outside a frame releases the old scope immediately',
    (tester) async {
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final key = GlobalKey();

      Widget tree({required bool underB, required bool readSpace}) {
        final child = _ConditionalProbe(
          key: key,
          provider: provider,
          readSpace: readSpace,
        );
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : child,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false, readSpace: true));
      expect(ownerA.store.exists(provider), isTrue, reason: 'bound in A first');

      // Reparent A -> B with a build that never reads `space`, so no build
      // notices the swap.
      await tester.pumpWidget(tree(underB: true, readSpace: false));
      expect(
        ownerA.store.exists(provider),
        isTrue,
        reason: 'swap still unnoticed',
      );

      // Now read `space` the way an onPressed / Timer / stream listener would.
      // Premise of this test: the scheduler is idle, so the read takes the
      // inline arm of the phase split. That idleness is also why deferring here
      // would be wrong in production — addPostFrameCallback schedules no frame
      // of its own, so the old scope would sit in the queue until something
      // unrelated happened to pump a frame, if ever.
      expect(SchedulerBinding.instance.schedulerPhase, SchedulerPhase.idle);

      final state = tester.state<_ConditionalProbeState>(
        find.byType(_ConditionalProbe),
      );
      final oldScope = state.scope;
      state.space.bind(provider);

      expect(
        identical(state.scope, oldScope),
        isFalse,
        reason: 'a fresh scope backs the new store',
      );
      // The load-bearing assertion: no further pump happens in this test, so
      // this can only hold if the release ran inline.
      expect(
        disposeCount,
        1,
        reason: 'old scope released inline rather than stranded',
      );
      expect(ownerA.store.exists(provider), isFalse);
      expect(ownerB.store.exists(provider), isTrue, reason: 'rebound in B');
    },
  );

  testWidgets(
    'a swap noticed while post-frame callbacks drain releases immediately',
    (tester) async {
      // The third arm of the phase split, and the one that leaks silently if it
      // is classified as "defer": SchedulerBinding copies _postFrameCallbacks
      // and clears the list *before* invoking them, so a callback registered
      // from inside that drain lands on the *next* frame — which nothing
      // schedules. Reading `space` from a post-frame callback is ordinary (a
      // controller settling after layout, an ensureVisible, a first-frame hook).
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final key = GlobalKey();

      Widget tree({required bool underB, required bool readSpace}) {
        final child = _ConditionalProbe(
          key: key,
          provider: provider,
          readSpace: readSpace,
        );
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: underB ? const SizedBox() : child,
              ),
              StoreScope(
                storeOwner: ownerB,
                child: underB ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(underB: false, readSpace: true));
      expect(ownerA.store.exists(provider), isTrue, reason: 'bound in A first');

      // Reparent A -> B with a build that never reads `space`.
      await tester.pumpWidget(tree(underB: true, readSpace: false));
      expect(
        ownerA.store.exists(provider),
        isTrue,
        reason: 'swap still unnoticed',
      );

      SchedulerPhase? phaseAtRead;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        phaseAtRead = SchedulerBinding.instance.schedulerPhase;
        tester
            .state<_ConditionalProbeState>(find.byType(_ConditionalProbe))
            .space
            .bind(provider);
      });
      tester.binding.scheduleFrame();
      await tester.pump(); // exactly one frame: runs the callback above

      expect(
        phaseAtRead,
        SchedulerPhase.postFrameCallbacks,
        reason: 'premise: the swap really was noticed during the drain',
      );
      // No second pump. A deferred release would sit in _postFrameCallbacks
      // waiting for a frame that is never scheduled.
      expect(
        disposeCount,
        1,
        reason: 'old scope released inline rather than stranded',
      );
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason:
            'test bookkeeping, not a claim about the release: the one frame '
            'scheduled above was consumed and nothing re-armed it, so "no '
            'second pump" really does mean no further callbacks run',
      );
      expect(ownerA.store.exists(provider), isFalse);
      expect(ownerB.store.exists(provider), isTrue, reason: 'rebound in B');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unmounting in the same frame as a swap disposes both scopes once',
    (tester) async {
      // The `State` counterpart of the stateless case above. The teardown runs
      // through `State.dispose` rather than `Element.unmount`, so the two
      // notifiers have to be distinct on this side too.
      final ownerA = StoreOwnerImpl(StoreImpl());
      final ownerB = StoreOwnerImpl(StoreImpl());
      var disposeCount = 0;
      final provider = Provider.from<Object>(
        (space) => Object(),
        disposer: (_) => disposeCount++,
      );
      final childKey = GlobalKey();

      Widget tree({required int phase}) {
        final child = _SwapProbe(key: childKey, provider: provider);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              StoreScope(
                storeOwner: ownerA,
                child: phase == 0 ? child : const SizedBox(),
              ),
              StoreScope(
                storeOwner: ownerB,
                child: phase == 1 ? child : const SizedBox(),
              ),
            ],
          ),
        );
      }

      await tester.pumpWidget(tree(phase: 0));
      await tester.pumpWidget(tree(phase: 1)); // A -> B
      await tester.pumpWidget(tree(phase: 2)); // gone entirely
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        disposeCount,
        2,
        reason: 'both the A bind and the B bind released',
      );
      expect(ownerA.store.exists(provider), isFalse);
      expect(ownerB.store.exists(provider), isFalse);
    },
  );

  testWidgets('two widgets swapping stores in one frame keep both instances', (
    tester,
  ) async {
    // Both scopes bind the same provider and trade places in a single frame.
    // The swap is noticed during the build phase, so each release is deferred to
    // the end of the frame: both widgets have rebound before either old scope is
    // disposed, so neither store's reference count ever reaches zero and neither
    // instance is torn down. Releasing inline instead would drop the first
    // store's count to zero mid-frame and force a rebuild of both instances.
    final ownerA = StoreOwnerImpl(StoreImpl());
    final ownerB = StoreOwnerImpl(StoreImpl());
    var createCount = 0;
    var disposeCount = 0;
    final provider = Provider.from<Object>((space) {
      createCount++;
      return Object();
    }, disposer: (_) => disposeCount++);
    final keyOne = GlobalKey();
    final keyTwo = GlobalKey();

    Widget tree({required bool crossed}) {
      final one = _SwapProbe(key: keyOne, provider: provider);
      final two = _SwapProbe(key: keyTwo, provider: provider);
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            StoreScope(
              key: const ValueKey('a'),
              storeOwner: ownerA,
              child: crossed ? two : one,
            ),
            StoreScope(
              key: const ValueKey('b'),
              storeOwner: ownerB,
              child: crossed ? one : two,
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(tree(crossed: false));
    expect(createCount, 2, reason: 'one instance per store');
    expect(disposeCount, 0);

    await tester.pumpWidget(tree(crossed: true)); // one: A->B, two: B->A
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(disposeCount, 0, reason: 'neither store ever lost its last binding');
    expect(createCount, 2, reason: 'no instance was torn down and rebuilt');
    expect(ownerA.store.exists(provider), isTrue);
    expect(ownerB.store.exists(provider), isTrue);
  });

  testWidgets('a swap first noticed during a hot-reload rebuild is released', (
    tester,
  ) async {
    // Hot reload marks the tree dirty (BuildOwner.reassemble -> markNeedsBuild)
    // and the rebuild lands in the next frame's build phase, so the release must
    // defer past it. Model the edited `build` with a module-level switch.
    _hotReloadReadsSpace = true;
    addTearDown(() => _hotReloadReadsSpace = false);

    final ownerA = StoreOwnerImpl(StoreImpl());
    final ownerB = StoreOwnerImpl(StoreImpl());
    var disposeCount = 0;
    final provider = Provider.from<Object>(
      (space) => Object(),
      disposer: (_) => disposeCount++,
    );
    final key = GlobalKey();

    Widget tree({required bool underB}) {
      final child = _ReloadProbe(key: key, provider: provider);
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            StoreScope(
              storeOwner: ownerA,
              child: underB ? const SizedBox() : child,
            ),
            StoreScope(
              storeOwner: ownerB,
              child: underB ? child : const SizedBox(),
            ),
          ],
        ),
      );
    }

    await tester.pumpWidget(tree(underB: false));
    expect(ownerA.store.exists(provider), isTrue, reason: 'bound in A first');

    // Reparent A -> B during a build that does not read `space`, so no build
    // notices the swap.
    _hotReloadReadsSpace = false;
    await tester.pumpWidget(tree(underB: true));
    expect(
      ownerA.store.exists(provider),
      isTrue,
      reason: 'swap still unnoticed',
    );

    // Hot reload: the edited build reads `space` again and finally sees it.
    _hotReloadReadsSpace = true;
    tester.binding.reassembleApplication();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(disposeCount, 1, reason: 'old-store bind released after reload');
    expect(ownerA.store.exists(provider), isFalse);
    expect(ownerB.store.exists(provider), isTrue, reason: 'rebound in B');
  });
}
