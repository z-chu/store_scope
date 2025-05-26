import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:store_scope/src/view_model.dart';
import 'package:store_scope/src/store_scope_config.dart';
import 'package:store_scope/src/dispose_state_notifier.dart'; // Required for _viewModelScope.disposed check
import 'package:flutter/foundation.dart' show VoidCallback;

// Annotations for build_runner to generate mocks
// We'd normally run: dart run build_runner build --delete-conflicting-outputs
// @GenerateMocks([VoidCallback])
// For now, we'll manually define a simple mock or rely on Mockito's Mock class directly
// if @GenerateMocks and the .mocks.dart file isn't feasible in this environment.

// Simple mock for VoidCallback if @GenerateMocks is not used/runnable
class MockVoidCallback extends Mock implements VoidCallback {
  // Add a 'callCount' and a 'called' getter for easier verification if not using full mockito generation
  int _callCount = 0;
  int get callCount => _callCount;
  bool get wasCalled => _callCount > 0;

  @override
  void call() {
    _callCount++;
    super.noSuchMethod(Invocation.method(#call, null));
  }

  void resetMock() {
    _callCount = 0;
  }
}


class TestViewModel extends ViewModel {
  // Expose internal structures for testing if necessary, or use getters.
  // For this test, we'll rely on the public API and behavior.
  int initCallCount = 0;

  @override
  void init() {
    super.init();
    initCallCount++;
  }

  // Expose internal state for testing
  bool get isViewModelScopeDisposed => _viewModelScope.disposed;
  int get closeablesCount => _closeables.length;
  int get keyedCloseablesCount => _keyToCloseables.length;
}

void main() {
  group('ViewModel Tests', () {
    late TestViewModel viewModel;
    late MockVoidCallback mockCloseable1;
    late MockVoidCallback mockCloseable2;
    late MockVoidCallback mockKeyedCloseable1;
    late MockVoidCallback mockKeyedCloseable2;

    setUp(() {
      viewModel = TestViewModel();
      mockCloseable1 = MockVoidCallback();
      mockCloseable2 = MockVoidCallback();
      mockKeyedCloseable1 = MockVoidCallback();
      mockKeyedCloseable2 = MockVoidCallback();
      
      // Reset StoreScopeConfig to defaults before each test
      StoreScopeConfig.throwOnCloseError = false;
      StoreScopeConfig.log = (_, {bool isError = false}) {}; // Default to no-op logger
    });

    tearDown(() {
      // Ensure ViewModel is disposed if not done by the test explicitly,
      // to prevent interference between tests via global config.
      if (!viewModel.disposed) {
        viewModel.dispose();
      }
    });

    group('ViewModel.dispose()', () {
      test('calls super.dispose (hasListeners becomes false)', () {
        expect(viewModel.hasListeners, isTrue); // Assuming it starts with listeners or can have them
        viewModel.dispose();
        expect(viewModel.hasListeners, isFalse);
      });

      test('calls all registered non-keyed closeables once', () {
        viewModel.addCloseable(mockCloseable1);
        viewModel.addCloseable(mockCloseable2);
        viewModel.dispose();
        expect(mockCloseable1.callCount, 1);
        expect(mockCloseable2.callCount, 1);
      });

      test('calls all registered keyed closeables once', () {
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        viewModel.addKeyedCloseable('key2', mockKeyedCloseable2);
        viewModel.dispose();
        expect(mockKeyedCloseable1.callCount, 1);
        expect(mockKeyedCloseable2.callCount, 1);
      });

      test('_viewModelScope.dispose() is called', () {
        expect(viewModel.isViewModelScopeDisposed, isFalse);
        viewModel.dispose();
        expect(viewModel.isViewModelScopeDisposed, isTrue);
      });

      test('_closeables and _keyToCloseables are empty after disposal', () {
        viewModel.addCloseable(mockCloseable1);
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        
        expect(viewModel.closeablesCount, 1);
        expect(viewModel.keyedCloseablesCount, 1);
        
        viewModel.dispose();
        
        expect(viewModel.closeablesCount, 0);
        expect(viewModel.keyedCloseablesCount, 0);
      });

      test('other closeables still executed if one throws (throwOnCloseError = false)', () {
        StoreScopeConfig.throwOnCloseError = false;
        final failingCloseable = MockVoidCallback();
        when(failingCloseable.call()).thenThrow(Exception('Test error'));

        viewModel.addCloseable(failingCloseable);
        viewModel.addCloseable(mockCloseable1); // Added after
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1); // Keyed

        viewModel.dispose();

        expect(failingCloseable.callCount, 1); // It was called
        expect(mockCloseable1.callCount, 1); // This should still be called
        expect(mockKeyedCloseable1.callCount, 1); // This should also still be called
      });
      
      test('error is logged if a closeable throws (throwOnCloseError = false)', () {
        StoreScopeConfig.throwOnCloseError = false;
        String? loggedMessage;
        bool? logWasError;
        StoreScopeConfig.log = (message, {isError = false}) {
          loggedMessage = message;
          logWasError = isError;
        };

        final failingCloseable = MockVoidCallback();
        final exception = Exception('Test error from closeable');
        when(failingCloseable.call()).thenThrow(exception);

        viewModel.addCloseable(failingCloseable);
        viewModel.dispose();

        expect(failingCloseable.callCount, 1);
        expect(loggedMessage, contains('Failed to close $exception in TestViewModel'));
        expect(loggedMessage, contains('Stack trace:'));
        expect(logWasError, isTrue);
      });

      test('re-throws error from closeable if throwOnCloseError = true', () {
        StoreScopeConfig.throwOnCloseError = true;
        final failingCloseable = MockVoidCallback();
        final exception = Exception('Test error');
        when(failingCloseable.call()).thenThrow(exception);

        viewModel.addCloseable(failingCloseable);
        viewModel.addCloseable(mockCloseable1);

        expect(() => viewModel.dispose(), throwsA(isA<Exception>()));
        
        // Even if it throws, it should attempt to call all closeables.
        // The exact behavior (stop on first error vs. collect errors) depends on implementation.
        // The current implementation continues after an error even if throwOnCloseError is true,
        // but the first error is rethrown.
        expect(failingCloseable.callCount, 1);
        expect(mockCloseable1.callCount, 1); 
      });
    });

    group('ViewModel.addKeyedCloseable()', () {
      test('executes and replaces existing closeable for the same key', () {
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        expect(mockKeyedCloseable1.callCount, 0);

        viewModel.addKeyedCloseable('key1', mockKeyedCloseable2); // Replace
        expect(mockKeyedCloseable1.callCount, 1); // Old one called on replacement
        expect(mockKeyedCloseable2.callCount, 0); // New one not called yet

        viewModel.dispose();
        expect(mockKeyedCloseable1.callCount, 1); // Not called again
        expect(mockKeyedCloseable2.callCount, 1); // New one called on dispose
      });

      test('executes immediately if ViewModel is disposed', () {
        viewModel.dispose();
        expect(viewModel.disposed, isTrue);

        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        expect(mockKeyedCloseable1.callCount, 1); // Called immediately
        
        // Ensure it's not added to the map to be called again
        expect(viewModel.keyedCloseablesCount, 0);
      });

      test('adding same closeable instance with same key: old one called, new one stored', () {
        // This test reflects the behavior after removing `if (oldCloseable == closeable) return;`
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        expect(mockKeyedCloseable1.callCount, 0);

        // Add the SAME instance again
        viewModel.addKeyedCloseable('key1', mockKeyedCloseable1);
        expect(mockKeyedCloseable1.callCount, 1); // mockKeyedCloseable1 (as old) is called

        viewModel.dispose();
        // mockKeyedCloseable1 (as new, which replaced the old) is called again
        expect(mockKeyedCloseable1.callCount, 2); 
      });
    });

    group('ViewModel.addCloseable()', () {
      test('executes immediately if ViewModel is disposed', () {
        viewModel.dispose();
        expect(viewModel.disposed, isTrue);

        viewModel.addCloseable(mockCloseable1);
        expect(mockCloseable1.callCount, 1); // Called immediately
        
        // Ensure it's not added to the list
        expect(viewModel.closeablesCount, 0);
      });

      test('adding same closeable instance multiple times only adds it once', () {
        viewModel.addCloseable(mockCloseable1);
        viewModel.addCloseable(mockCloseable1); // Add same instance again
        
        expect(viewModel.closeablesCount, 1); // Should only be one instance in the set

        viewModel.dispose();
        expect(mockCloseable1.callCount, 1); // Called only once
      });

      test('adding different closeable instances adds them all', () {
        viewModel.addCloseable(mockCloseable1);
        viewModel.addCloseable(mockCloseable2);
        
        expect(viewModel.closeablesCount, 2);

        viewModel.dispose();
        expect(mockCloseable1.callCount, 1);
        expect(mockCloseable2.callCount, 1);
      });
    });
     group('ViewModel.init()', () {
      test('is called after ViewModel creation by provider (simulated)', () {
        // In real scenario, ViewModelProvider calls init.
        // Here, we call it manually for TestViewModel to check its effect.
        // The TestViewModel's constructor doesn't call init.
        // We can check the initCallCount we added to TestViewModel.
        final newVm = TestViewModel();
        expect(newVm.initCallCount, 0); // Not called by constructor
        newVm.init(); // Manually call for testing the method itself
        expect(newVm.initCallCount, 1);
      });
    });
  });
}

// Note: If full mockito generation via build_runner was available,
// the MockVoidCallback would be generated in a .mocks.dart file,
// and we would import that. The manual mock is a fallback.
// e.g. import 'view_model_test.mocks.dart';
// then use MockVoidCallback from that generated file.
