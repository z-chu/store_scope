import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

class _SwapProbe extends StatefulWidget {
  const _SwapProbe({super.key, required this.provider});
  final Provider<Object> provider;
  @override
  State<_SwapProbe> createState() => _SwapProbeState();
}

class _SwapProbeState extends State<_SwapProbe> with ScopedSpaceStateMixin {
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
    // A disposer that notifies listeners on teardown (a common pattern: reset
    // selection, clear an error). It must not run during the build phase.
    addCloseable(notifyListeners);
  }
}

class _VmBinder extends StatefulWidget {
  const _VmBinder({super.key, required this.provider});
  final ViewModelProvider<_NotifyingVm> provider;
  @override
  State<_VmBinder> createState() => _VmBinderState();
}

class _VmBinderState extends State<_VmBinder> with ScopedSpaceStateMixin {
  @override
  Widget build(BuildContext context) {
    space.bind(widget.provider);
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
}
