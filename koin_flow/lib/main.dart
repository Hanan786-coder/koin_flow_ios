import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFFE0E3E7);
const _muted = Color(0xFFBCC9C6);
const _bg = Color(0xFF0B0F12);
const _panel = Color(0xFF161F28);
const _panelHigh = Color(0xFF1C2023);
const _violet = Color(0xFF6BD8CB);
const _green = Color(0xFF4EDEA3);
const _gold = Color(0xFFF7BE1D);
const _pink = Color(0xFFF43F5E);

void main() => runApp(const KoinFlowApp());

class Expense {
  Expense({required this.title, required this.amount, required this.category, required this.date});
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  Map<String, dynamic> toJson() => {'title': title, 'amount': amount, 'category': category, 'date': date.toIso8601String()};
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(title: json['title'] as String, amount: (json['amount'] as num).toDouble(), category: json['category'] as String, date: DateTime.parse(json['date'] as String));
}

class MoneyEntry {
  MoneyEntry({required this.name, required this.amount, required this.note, required this.isOwedToMe});
  final String name;
  final double amount;
  final String note;
  final bool isOwedToMe;
}

class KoinFlowApp extends StatelessWidget {
  const KoinFlowApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Koin Flow',
      theme: base.copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(surface: _bg, primary: _violet, secondary: _green, tertiary: _gold, error: _pink),
        textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: _ink, displayColor: _ink),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: _panelHigh, hintStyle: const TextStyle(color: _muted), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  double _budget = 2400;
  List<Expense> _expenses = [];
  final List<MoneyEntry> _debts = [MoneyEntry(name: 'Maya Chen', amount: 42.50, note: 'Dinner split', isOwedToMe: false), MoneyEntry(name: 'Jordan Lee', amount: 80, note: 'Concert tickets', isOwedToMe: true)];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('expenses') ?? [];
      setState(() { _expenses = raw.map((item) => Expense.fromJson(jsonDecode(item) as Map<String, dynamic>)).toList(); _budget = prefs.getDouble('budget') ?? 2400; });
    } catch (_) {
      return;
    }
  }
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expenses', _expenses.map((item) => jsonEncode(item.toJson())).toList());
    await prefs.setDouble('budget', _budget);
  }
  double get _spent => _expenses.fold(0, (sum, item) => sum + item.amount);
  double get _received => _debts.where((item) => item.isOwedToMe).fold(0, (sum, item) => sum + item.amount);
  double get _owed => _debts.where((item) => !item.isOwedToMe).fold(0, (sum, item) => sum + item.amount);

  void _addExpense() async {
    final result = await showModalBottomSheet<Expense>(context: context, isScrollControlled: true, backgroundColor: _panel, builder: (_) => const AddExpenseSheet());
    if (result == null) return;
    setState(() => _expenses = [result, ..._expenses]);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_dashboard(), _expensesPage(), _debtsPage(), _settingsPage()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(backgroundColor: _panel, indicatorColor: _violet.withValues(alpha: .18), selectedIndex: _tab, onDestinationSelected: (value) => setState(() => _tab = value), destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded, color: _violet), label: 'Overview'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: _violet), label: 'Expenses'), NavigationDestination(icon: Icon(Icons.swap_horiz_rounded), selectedIcon: Icon(Icons.swap_horiz_rounded, color: _violet), label: 'People'), NavigationDestination(icon: Icon(Icons.tune_rounded), selectedIcon: Icon(Icons.tune_rounded, color: _violet), label: 'Budget')]),
    );
  }

  Widget _shell({required String eyebrow, required String title, required Widget child}) => CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 0), sliver: SliverToBoxAdapter(child: _header(eyebrow, title))), SliverPadding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 32), sliver: SliverToBoxAdapter(child: child))]);
  Widget _header(String eyebrow, String title) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const KoinLogo(size: 42), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(eyebrow.toUpperCase(), style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700))])), IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: _muted))]);

  Widget _dashboard() => _shell(eyebrow: 'Thursday, October 3', title: 'Good morning, Alex', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_balanceCard(), const SizedBox(height: 22), _sectionTitle('This month', 'October 2026'), const SizedBox(height: 12), Row(children: [_statCard('Spent', 'Rs. ${_spent.toStringAsFixed(0)}', Icons.arrow_upward_rounded, _pink), const SizedBox(width: 12), _statCard('Available', 'Rs. ${(_budget - _spent).toStringAsFixed(0)}', Icons.south_west_rounded, _green)]), const SizedBox(height: 22), _cashflowChart(), const SizedBox(height: 24), _sectionTitle('Recent activity', 'See all', onTap: () => setState(() => _tab = 1)), const SizedBox(height: 10), if (_expenses.isEmpty) _emptyState('Your ledger is ready', 'Add your first expense to start seeing your flow.') else ..._expenses.take(4).map(_expenseTile), const SizedBox(height: 22), _sectionTitle('People & balances', 'Manage', onTap: () => setState(() => _tab = 2)), const SizedBox(height: 12), Row(children: [_miniBalance('You are owed', _received, _green), const SizedBox(width: 12), _miniBalance('You owe', _owed, _pink)])]));
  Widget _balanceCard() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF132227), Color(0xFF10171D)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: _green.withValues(alpha: .2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('NET LIQUIDITY', style: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)), const SizedBox(height: 8), Text('Rs. ${(_budget - _spent + _received - _owed).toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)), const SizedBox(height: 18), Row(children: [const Icon(Icons.trending_up_rounded, color: _green, size: 18), const SizedBox(width: 6), Text('${_expenses.isEmpty ? '0' : '12.8'}% from last month', style: const TextStyle(color: _green, fontWeight: FontWeight.w600)), const Spacer(), const Text('PKR', style: TextStyle(color: _muted, fontWeight: FontWeight.w700))]) ]));
  Widget _cashflowChart() {
    final today = DateTime.now();
    final values = List<double>.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return _expenses.where((item) => item.date.year == day.year && item.date.month == day.month && item.date.day == day.day).fold(0, (sum, item) => sum + item.amount);
    });
    return Container(padding: const EdgeInsets.fromLTRB(16, 16, 16, 12), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .06))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('Cashflow this week', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), Text('Rs. ${values.fold(0.0, (sum, value) => sum + value).toStringAsFixed(0)}', style: const TextStyle(color: _green, fontWeight: FontWeight.w700))]), const SizedBox(height: 18), SizedBox(height: 130, width: double.infinity, child: CustomPaint(painter: _CashflowPainter(values))), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) => Text('${today.day - (6 - index)}', style: const TextStyle(color: _muted, fontSize: 11))))]));
  }
  Widget _statCard(String label, String value, IconData icon, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 18), const SizedBox(height: 12), Text(label, style: const TextStyle(color: _muted, fontSize: 13)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))])));

  Widget _expensesPage() => _shell(eyebrow: 'Your ledger', title: 'Daily expenses', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: .06))), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('October spend', style: TextStyle(color: _muted)), SizedBox(height: 5), Text('Track the little things', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))])), Text('Rs. ${_spent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _violet))])), const SizedBox(height: 24), _sectionTitle('All transactions', 'Add expense', onTap: _addExpense), const SizedBox(height: 12), if (_expenses.isEmpty) _emptyState('No expenses yet', 'Tap Add expense to record a purchase.') else ..._expenses.map(_expenseTile)]));
  Widget _debtsPage() => _shell(eyebrow: 'Split with ease', title: 'People & balances', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_miniBalance('To receive', _received, _green), const SizedBox(width: 12), _miniBalance('To pay', _owed, _pink)]), const SizedBox(height: 26), _sectionTitle('Open balances', 'Add person', onTap: () => _showSnack('People can be added from a shared expense.')), const SizedBox(height: 12), ..._debts.map((item) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15)), child: Row(children: [CircleAvatar(backgroundColor: (item.isOwedToMe ? _green : _pink).withValues(alpha: .16), child: Text(item.name.substring(0, 1), style: TextStyle(color: item.isOwedToMe ? _green : _pink, fontWeight: FontWeight.w700))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(item.note, style: const TextStyle(color: _muted, fontSize: 13))])), Text('${item.isOwedToMe ? '+' : '-'}\$${item.amount.toStringAsFixed(2)}', style: TextStyle(color: item.isOwedToMe ? _green : _pink, fontWeight: FontWeight.w700))])))]));
  Widget _settingsPage() => _shell(eyebrow: 'Stay on track', title: 'Budget & settings', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_budgetCard(), const SizedBox(height: 24), _sectionTitle('Preferences', 'Stored on this device'), const SizedBox(height: 10), _settingTile(Icons.currency_exchange_rounded, 'Default currency', 'USD — US Dollar'), _settingTile(Icons.lock_outline_rounded, 'Privacy lock', 'Off'), _settingTile(Icons.file_download_outlined, 'Export ledger', 'CSV and JSON'), const SizedBox(height: 18), Center(child: Text('Koin Flow 1.0.0', style: TextStyle(color: _muted.withValues(alpha: .65), fontSize: 12)))]));
  Widget _budgetCard() => Container(padding: const EdgeInsets.all(19), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('Monthly budget', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), Text('\$${_budget.toStringAsFixed(0)}', style: const TextStyle(color: _violet, fontSize: 20, fontWeight: FontWeight.w700))]), const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (_spent / _budget).clamp(0, 1), minHeight: 9, backgroundColor: _panelHigh, color: _spent > _budget ? _pink : _green)), const SizedBox(height: 10), Text('\$${_spent.toStringAsFixed(0)} spent of \$${_budget.toStringAsFixed(0)}', style: const TextStyle(color: _muted, fontSize: 13)), Slider(value: _budget, min: 500, max: 10000, divisions: 95, onChanged: (value) { setState(() => _budget = value); _save(); })]));
  Widget _settingTile(IconData icon, String title, String subtitle) => ListTile(contentPadding: const EdgeInsets.symmetric(vertical: 2), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: _violet, size: 20)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)), trailing: const Icon(Icons.chevron_right_rounded, color: _muted));
  Widget _expenseTile(Expense item) => Dismissible(key: ValueKey('${item.title}-${item.date}'), onDismissed: (_) { setState(() => _expenses.remove(item)); _save(); }, background: Container(color: _pink.withValues(alpha: .15), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete_outline, color: _pink)), child: Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _violet.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Icon(_categoryIcon(item.category), color: _violet, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${item.category} · ${_date(item.date)}', style: const TextStyle(color: _muted, fontSize: 12))])), Text('-\$${item.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, color: _pink))])));
  Widget _sectionTitle(String title, String action, {VoidCallback? onTap}) => Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const Spacer(), GestureDetector(onTap: onTap, child: Text(action, style: const TextStyle(color: _violet, fontSize: 13, fontWeight: FontWeight.w600)))]);
  Widget _miniBalance(String label, double amount, Color color) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(15)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: _muted, fontSize: 12)), const SizedBox(height: 7), Text('\$${amount.toStringAsFixed(2)}', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700))])));
  Widget _emptyState(String title, String subtitle) => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18), decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)), child: Column(children: [const Icon(Icons.auto_awesome_rounded, color: _violet, size: 28), const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 13))]));
  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});
  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}
class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _category = 'Food';
  @override
  void dispose() { _title.dispose(); _amount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.viewInsetsOf(context).bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Expanded(child: Text('New expense', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]), const SizedBox(height: 12), TextField(controller: _title, autofocus: true, decoration: const InputDecoration(labelText: 'What did you spend on?', prefixIcon: Icon(Icons.edit_outlined))), const SizedBox(height: 12), TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ')), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: _category, dropdownColor: _panelHigh, decoration: const InputDecoration(labelText: 'Category'), items: ['Food', 'Transport', 'Home', 'Shopping', 'Health', 'Other'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => setState(() => _category = value!)), const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: () { final amount = double.tryParse(_amount.text.replaceAll(',', '')); if (_title.text.trim().isEmpty || amount == null || amount <= 0) return; Navigator.pop(context, Expense(title: _title.text.trim(), amount: amount, category: _category, date: DateTime.now())); }, style: FilledButton.styleFrom(backgroundColor: _violet, foregroundColor: const Color(0xFF1000A9), padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('Save expense', style: TextStyle(fontWeight: FontWeight.w700))))]));
}

class KoinLogo extends StatelessWidget {
  const KoinLogo({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _LogoPainter());
}
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 5 * scale..strokeCap = StrokeCap.round;
    paint.color = _violet;
    canvas.drawArc(Rect.fromLTWH(7 * scale, 7 * scale, 34 * scale, 34 * scale), -.7, 4.55, false, paint);
    paint.color = _green;
    canvas.drawLine(Offset(24 * scale, 12 * scale), Offset(24 * scale, 36 * scale), paint);
    canvas.drawLine(Offset(17 * scale, 24 * scale), Offset(31 * scale, 24 * scale), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CashflowPainter extends CustomPainter {
  const _CashflowPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = Colors.white.withValues(alpha: .06)..strokeWidth = 1;
    for (var index = 1; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = values.fold(0.0, (max, value) => value > max ? value : max);
    final ceiling = maxValue == 0 ? 1.0 : maxValue * 1.25;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = size.height - (values[index] / ceiling * size.height);
      points.add(Offset(x, y));
    }
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath..lineTo(points.last.dx, size.height)..close();
    canvas.drawPath(fillPath, Paint()..color = _violet.withValues(alpha: .10));
    final line = Paint()..color = _violet..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(path, line);
    for (final point in points) {
      canvas.drawCircle(point, 3.5, Paint()..color = _green);
    }
  }

  @override
  bool shouldRepaint(covariant _CashflowPainter oldDelegate) => oldDelegate.values != values;
}

IconData _categoryIcon(String category) => switch (category) { 'Food' => Icons.restaurant_rounded, 'Transport' => Icons.directions_car_rounded, 'Home' => Icons.home_rounded, 'Shopping' => Icons.shopping_bag_rounded, 'Health' => Icons.favorite_rounded, _ => Icons.more_horiz_rounded };
String _date(DateTime date) => '${date.month}/${date.day}';
