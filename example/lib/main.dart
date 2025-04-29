import 'package:flutter/material.dart';
import 'package:store_scope/store_scope.dart';

class NumberViewModel extends ViewModel {
  int get number => 5;
}

class CounterViewModel extends ViewModel {
  final NumberViewModel numberViewModel;

  CounterViewModel(this.numberViewModel);

  final _count = ValueNotifier<int>(0);
  ValueNotifier<int> get count => _count;

  void increment() {
    _count.value = count.value + numberViewModel.number;
  }

  @override
  void init() {
    super.init();
    count.value = numberViewModel.number * 2;
  }

  @override
  void dispose() {
    super.dispose();
    _count.dispose();
  }
}

final numberProvider = ViewModelProvider<NumberViewModel>((space) {
  return NumberViewModel();
});
final counterProvider = ViewModelProvider<CounterViewModel>((space) {
  final numberViewModel = space.bind(numberProvider);
  return CounterViewModel(numberViewModel);
});
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      child: MaterialApp(
        title: 'StoreScope Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const StartPage(),
      ),
    );
  }
}

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CounterPage()),
            );
          },
          child: const Text('Open Counter Page'),
        ),
      ),
    );
  }
}

class CounterPage extends StatelessWidget with ScopedStatelessMixin {
  CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    CounterViewModel viewModel = context.store.bindWithScoped(
      counterProvider,
      this,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: viewModel.count,
              builder: (context, count, child) {
                return Text(
                  'Count: $count',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                viewModel.increment();
              },
              child: const Text('Increment'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CounterPage()),
                );
              },
              child: const Text('Open new page'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoreScopePage(),
                  ),
                );
              },
              child: const Text('Open StoreScopePage'),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreScopePage extends StoreScopeWidget {
  const StoreScopePage({super.key});

  @override
  Widget build(BuildContext context) {
    var viewModel = context.store.shared(counterProvider);
    viewModel.increment();
    return const ChildPage();
  }
}

class ChildPage extends StatefulWidget {
  const ChildPage({super.key});

  @override
  State<ChildPage> createState() => _ChildPageState();
}

class _ChildPageState extends State<ChildPage> {
  @override
  Widget build(BuildContext context) {
    context.store.shared(counterProvider).increment();

    return CounterPage();
  }
}
