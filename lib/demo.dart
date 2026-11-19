import 'models.dart';

/// Sample data for previews. Only used when built with --dart-define=DEMO=true.
const kDemo = bool.fromEnvironment('DEMO');

({List<Expense> expenses, List<MoneyEntry> debts, List<Bill> bills}) demoData(
  DateTime now,
) {
  DateTime ago(int days, [int hour = 13]) =>
      DateTime(now.year, now.month, now.day - days, hour);
  final lastMonth = DateTime(now.year, now.month - 1);
  final expenses =
      <Expense>[
            Expense(
              title: 'Chai and paratha',
              amount: 450,
              category: 'Food',
              date: ago(0, 9),
            ),
            Expense(
              title: 'Careem to office',
              amount: 780,
              category: 'Transport',
              date: ago(0, 8),
            ),
            Expense(
              title: 'Imtiaz groceries',
              amount: 6850,
              category: 'Food',
              date: ago(1, 19),
            ),
            Expense(
              title: 'Pharmacy',
              amount: 1240,
              category: 'Health',
              date: ago(1, 18),
            ),
            Expense(
              title: 'Petrol',
              amount: 5000,
              category: 'Transport',
              date: ago(2),
            ),
            Expense(
              title: 'New sneakers',
              amount: 12500,
              category: 'Shopping',
              date: ago(3),
              note: 'Sale at Dolmen',
            ),
            Expense(
              title: 'Biryani night',
              amount: 3200,
              category: 'Food',
              date: ago(4, 21),
            ),
            Expense(
              title: 'Electricity',
              amount: 14200,
              category: 'Bills',
              date: ago(6),
              note: 'Monthly bill',
            ),
            Expense(
              title: 'Plumber',
              amount: 2500,
              category: 'Home',
              date: ago(8),
            ),
            Expense(
              title: 'Daraz order',
              amount: 4300,
              category: 'Shopping',
              date: ago(10),
            ),
            Expense(
              title: 'Lunch with team',
              amount: 2100,
              category: 'Food',
              date: ago(12),
            ),
            Expense(
              title: 'Gym',
              amount: 4000,
              category: 'Health',
              date: ago(15),
            ),
            for (var d = 1; d <= 26; d += 3)
              Expense(
                title: 'Spending',
                amount: 3800.0 + d * 120,
                category: d.isEven ? 'Food' : 'Shopping',
                date: DateTime(lastMonth.year, lastMonth.month, d),
              ),
          ]
          .where(
            (e) => e.date.month == now.month || e.date.month == lastMonth.month,
          )
          .toList();

  final debts = [
    MoneyEntry(
      id: 'd1',
      name: 'Usman',
      amount: 8000,
      note: 'Concert tickets',
      isOwedToMe: true,
      dueDate: ago(-3),
    ),
    MoneyEntry(
      id: 'd2',
      name: 'Ayesha',
      amount: 2500,
      note: 'Dinner split',
      isOwedToMe: false,
    ),
    MoneyEntry(
      id: 'd3',
      name: 'Bilal',
      amount: 1500,
      note: 'Cab fare',
      isOwedToMe: true,
      settled: true,
    ),
  ];

  final bills = [
    Bill(name: 'Internet', amount: 3500, dueDay: (now.day + 2).clamp(1, 28)),
    Bill(name: 'Netflix', amount: 1100, dueDay: (now.day + 5).clamp(1, 28)),
    Bill(
      name: 'Rent',
      amount: 45000,
      dueDay: 1,
      paidMonths: [Bill.monthKey(now)],
    ),
    Bill(
      name: 'Electricity',
      amount: 14200,
      dueDay: (now.day - 6).clamp(1, 28),
      paidMonths: [Bill.monthKey(now)],
    ),
  ];
  return (expenses: expenses, debts: debts, bills: bills);
}
