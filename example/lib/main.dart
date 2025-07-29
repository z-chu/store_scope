import 'package:flutter/material.dart';
import 'package:store_scope/store_scope.dart';

class NumberObj {
  final int number;
  NumberObj({required this.number});
}

class CounterViewModel extends ViewModel {
  final NumberObj numberObj;
  final int multiplyNumber;

  CounterViewModel(this.numberObj, this.multiplyNumber);

  final _count = ValueNotifier<int>(0);
  ValueNotifier<int> get count => _count;

  void increment() {
    _count.value = count.value + numberObj.number;
  }

  @override
  void init() {
    super.init();
    count.value = numberObj.number * multiplyNumber;
  }

  @override
  void dispose() {
    super.dispose();
    _count.dispose();
  }
}

final numberProvider = Provider.withArgument((space, int number) {
  return NumberObj(number: number);
});
final counterProvider = ViewModelProvider.withArgument((
  space,
  int multiplyNumber,
) {
  final numberViewModel = space.bind(numberProvider(5));
  return CounterViewModel(numberViewModel, multiplyNumber);
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

class CounterPage extends StatelessWidget with ScopedSpaceStatelessMixin {
  CounterPage({super.key});

  @override
  Widget buildWithSpace(BuildContext context, StoreSpace space) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScopedBuilder(
              builder: (context, space, child) {
                CounterViewModel viewModel = space.bind(counterProvider(2));
                return ValueListenableBuilder<int>(
                  valueListenable: viewModel.count,
                  builder: (context, count, child) {
                    return Text(
                      'Count: $count',
                      style: Theme.of(context).textTheme.headlineMedium,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.store.find(counterProvider(2))?.increment();
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

class StoreScopePage extends AutoStoreWidget {
  const StoreScopePage({super.key});

  @override
  Widget build(BuildContext context) {
    var viewModel = context.store.shared(counterProvider(2));
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
  void initState() {
    super.initState();
    context.store.shared(counterProvider(2)).increment();
  }

  @override
  Widget build(BuildContext context) {
    return CounterPage();
  }
}
