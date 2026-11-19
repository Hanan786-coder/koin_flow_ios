import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:koin_flow/format.dart';
import 'package:koin_flow/main.dart';
import 'package:koin_flow/models.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('format', () {
    test('groups digits', () {
      expect(groupDigits(0), '0');
      expect(groupDigits(950), '950');
      expect(groupDigits(1234567), '1,234,567');
      expect(groupDigits(-12000), '-12,000');
      expect(rs(240000), 'Rs 240,000');
      expect(rs(240000, hidden: true), 'Rs ••••');
    });

    test('ordinals', () {
      expect(ordinal(1), '1st');
      expect(ordinal(2), '2nd');
      expect(ordinal(11), '11th');
      expect(ordinal(23), '23rd');
    });
  });

  group('models', () {
    test('old expenses without id still load', () {
      final e = Expense.fromJson({
        'title': 'Tea',
        'amount': 120,
        'category': 'Food',
        'date': '2026-11-01T10:00:00.000',
      });
      expect(e.id, isNotEmpty);
      expect(e.note, '');
    });

    test('ids are unique when created back to back', () {
      final ids = List.generate(
        500,
        (_) => Bill(name: 'x', amount: 1, dueDay: 1).id,
      );
      expect(ids.toSet().length, 500);
    });

    test('bill due and paid tracking', () {
      final bill = Bill(name: 'Internet', amount: 3500, dueDay: 25);
      final today = DateTime(2026, 11, 19);
      expect(bill.daysUntilDue(today), 6);
      expect(bill.isPaidFor(today), isFalse);
      final paid = bill.copyWith(paidMonths: [Bill.monthKey(today)]);
      expect(paid.isPaidFor(today), isTrue);
      expect(Bill.fromJson(paid.toJson()).isPaidFor(today), isTrue);
    });
  });

  testWidgets('keeps data saved by the previous version', (tester) async {
    // Exactly the shape the old app wrote, plus one damaged record.
    const oldExpense =
        '{"title":"Groceries","amount":5000.0,"category":"Food","date":"2026-11-10T12:00:00.000"}';
    const oldDebt =
        '{"id":"1","name":"Ali","amount":2000.0,"note":"Lunch","isOwedToMe":true,"dueDate":null,"settled":false}';
    const damaged = '{"title": broken';
    SharedPreferences.setMockInitialValues({
      'expenses': [oldExpense, damaged],
      'debts': [oldDebt],
      'budget': 80000.0,
      'privacyLock': false,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(KoinFlowApp(now: () => DateTime(2026, 11, 19, 9)));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('of Rs 80,000'), findsOneWidget);
    await tester.tap(find.text('Expenses'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Groceries'), findsOneWidget);

    // Saving (marking via a write) must keep the damaged record untouched.
    await tester.tap(find.text('People'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Ali'), findsOneWidget);
    await tester.tap(find.text('Settle'));
    await tester.pump(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('expenses'), contains(damaged));
    expect(prefs.getDouble('budget'), 80000.0);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('boots, shows the budget and switches tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(KoinFlowApp(now: () => DateTime(2026, 11, 19, 20)));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Good evening, Abdul'), findsOneWidget);
    expect(find.text('Left this month'), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);

    await tester.tap(find.text('Expenses'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No expenses yet'), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Monthly bills'), findsOneWidget);
    expect(find.text('Add bill'), findsWidgets);
  });
}
