import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:store_scope/store_scope.dart';
import 'package:example/main.dart';

void main() {
  group('Counter Tests', () {
    testWidgets('CounterPage initial count should be 10', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        StoreScope(child: MaterialApp(home: CounterPage())),
      );

      // 初始值应该是 numberViewModel.number * 2 = 5 * 2 = 10
      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('CounterPage increment should add 5', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        StoreScope(child: MaterialApp(home: CounterPage())),
      );

      // 点击增加按钮
      await tester.tap(find.text('Increment'));
      await tester.pump();

      // 应该增加 5 (numberViewModel.number)
      expect(find.text('Count: 15'), findsOneWidget);
    });

    testWidgets('Navigation to new CounterPage should work', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        StoreScope(child: MaterialApp(home: CounterPage())),
      );

      // 点击打开新页面按钮
      await tester.tap(find.text('Open new page'));
      await tester.pumpAndSettle();

      // 验证新页面是否正确显示
      expect(find.text('Counter Example'), findsOneWidget);
      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('StoreScopePage should increment counter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        StoreScope(child: MaterialApp(home: CounterPage())),
      );

      // 记录初始值
      expect(find.text('Count: 10'), findsOneWidget);

      // 导航到 StoreScopePage
      await tester.tap(find.text('Open StoreScopePage'));
      await tester.pumpAndSettle();

      // StoreScopePage 和 ChildPage 都会调用 increment
      // 所以计数器应该增加两次
      expect(find.text('Count: 20'), findsOneWidget);
    });
  });
}
