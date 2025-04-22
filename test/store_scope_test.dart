import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';

void main() {
  group('StoreScope', () {
    testWidgets('should provide store to descendants', (tester) async {
      await tester.pumpWidget(
        StoreScope(
          child: Builder(
            builder: (context) {
              final store = context.store;
              expect(store, isNotNull);
              expect(context.requireStore.mounted, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should throw when store is not found', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => context.requireStore, throwsFlutterError);
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('Store', () {
    late Store store;
    late TestProvider provider;

    setUp(() {
      store = StoreImpl();
      provider = TestProvider();
    });

    test('should not exist provider', () {
      expect(store.exists(provider), isFalse);
    });

    test('should create and read provider instance', () {
      final instance = store.shared(provider);
      expect(instance, isNotNull);
      expect(store.exists(provider), isTrue);
    });

    test('should watch provider', () {
      final notifier = DisposeStateNotifier();
      final instance = store.bind(provider, notifier);
      expect(instance, isNotNull);
      notifier.dispose();
      expect(store.exists(provider), isFalse);
    });
  });

  group('ViewModel', () {
    late Store store;
    late TestViewModelProvider provider;

    setUp(() {
      store = StoreImpl();
      provider = TestViewModelProvider();
    });

    test('should create and initialize view model', () {
      final vm = store.shared(provider);
      expect(vm, isNotNull);
      expect(vm.disposed, isFalse);
    });
  });
}

class TestProvider extends Provider<String> {
  @override
  String create(Store store) => 'test';

  @override
  void dispose(String instance) {}
}

class TestViewModel extends ViewModel {
  bool initialized = false;

  @override
  void init() {
    initialized = true;
  }
}

class TestViewModelProvider extends ViewModelProvider<TestViewModel> {
  TestViewModelProvider() : super((space) => TestViewModel());
}
