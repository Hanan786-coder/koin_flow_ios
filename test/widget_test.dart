// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:koin_flow/main.dart';

void main() {
  testWidgets('Koin Flow boots and exposes the expense flow', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const KoinFlowApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Good morning, Abdul Hanan'), findsOneWidget);
    expect(find.text('NET LIQUIDITY'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Daily expenses'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);

  });
}
