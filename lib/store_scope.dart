/// A robust and flexible state management library for Flutter applications.
///
/// `store_scope` provides a structured way to manage application state using
/// stores, providers, and view models. It emphasizes scoped state, lifecycle
/// management, and easy dependency injection.
///
/// Key features:
/// - **Store:** A central repository for application state and provider instances.
/// - **Provider:** A mechanism for creating, managing, and disposing of state objects (instances).
///   Supports providers with multiple arguments for creating instances that require runtime data.
/// - **ViewModel:** A specialized `ChangeNotifier` that integrates with the store's
///   lifecycle, designed to hold UI-related state and business logic.
/// - **Scope Management:** Clearly defined lifecycles for state, with automatic disposal
///   of resources when scopes (e.g., associated with widgets or ViewModels) are closed.
/// - **Dependency Injection:** Easily access and share provider instances throughout
///   the widget tree or within other services.
/// - **Testability:** Designed with testability in mind, allowing for easy mocking
///   and testing of stateful components.
library;

export 'src/store_scope.dart';
export 'src/store.dart';
export 'src/provider.dart';
export 'src/dispose_state_notifier.dart';
export 'src/view_model.dart';
export 'src/store_space.dart';
export 'src/mixins.dart';