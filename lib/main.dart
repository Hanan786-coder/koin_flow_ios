import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() => runApp(const _KoinFlowBootApp());

class Expense {
  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
  };
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
  );
}

class MoneyEntry {
  MoneyEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.note,
    required this.isOwedToMe,
    this.dueDate,
    this.settled = false,
  });
  final String id;
  final String name;
  final double amount;
  final String note;
  final bool isOwedToMe;
  final DateTime? dueDate;
  final bool settled;

  MoneyEntry copyWith({bool? settled}) => MoneyEntry(
    id: id,
    name: name,
    amount: amount,
    note: note,
    isOwedToMe: isOwedToMe,
    dueDate: dueDate,
    settled: settled ?? this.settled,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'note': note,
    'isOwedToMe': isOwedToMe,
    'dueDate': dueDate?.toIso8601String(),
    'settled': settled,
  };
  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    note: json['note'] as String,
    isOwedToMe: json['isOwedToMe'] as bool,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
    settled: json['settled'] as bool? ?? false,
  );
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
        colorScheme: const ColorScheme.dark(
          surface: _bg,
          primary: _violet,
          secondary: _green,
          tertiary: _gold,
          error: _pink,
        ),
        textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
            .apply(bodyColor: _ink, displayColor: _ink),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _panelHigh,
          hintStyle: const TextStyle(color: _muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class _KoinFlowBootApp extends StatefulWidget {
  const _KoinFlowBootApp();

  @override
  State<_KoinFlowBootApp> createState() => _KoinFlowBootAppState();
}

class _KoinFlowBootAppState extends State<_KoinFlowBootApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _splashController;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _splashController.forward();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          const KoinFlowApp(),
          AnimatedBuilder(
            animation: _splashController,
            builder: (context, child) => IgnorePointer(
              ignoring: _splashController.status == AnimationStatus.completed,
              child: child,
            ),
            child: _SplashScreen(controller: _splashController),
          ),
        ],
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scaleAnimation =
        Tween<double>(begin: 0.8, end: 1.2).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    final opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.7, 1, curve: Curves.easeInCubic),
      ),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: opacityAnimation.value,
        child: Container(
          color: _bg,
          child: Center(
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: (1 - controller.value) * 0.3,
                    child: const KoinLogo(size: 80),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1)
                        .animate(CurvedAnimation(
                          parent: controller,
                          curve: Curves.easeOut,
                        )),
                    child: const Text(
                      'Koin Flow',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _violet,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.6, end: 0)
                        .animate(CurvedAnimation(
                          parent: controller,
                          curve: Curves.easeIn,
                        )),
                    child: const Text(
                      'Track your flow',
                      style: TextStyle(
                        fontSize: 13,
                        color: _muted,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
  double _budget = 240000;
  double _budgetSliderValue = 240000;
  DateTime? _budgetExpenseStart;
  final _budgetController = TextEditingController(text: '240000');
  final _budgetFocusNode = FocusNode();
  List<Expense> _expenses = [];
  List<MoneyEntry> _debts = [];
  String _expenseQuery = '';
  String _debtQuery = '';
  String _expenseCategory = 'All';
  String _dateFilter = 'All time';
  DateTime? _specificDate;
  int? _filterMonth;
  int? _filterYear;
  bool _sortNewestFirst = true;
  String _chartRange = 'Weekly';
  bool _privacyLock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('expenses') ?? [];
      final debtRaw = prefs.getStringList('debts') ?? [];
      final budgetExpenseStartRaw = prefs.getString('budgetExpenseStart');
      setState(() {
        _expenses = raw
            .map(
              (item) =>
                  Expense.fromJson(jsonDecode(item) as Map<String, dynamic>),
            )
            .toList();
        _debts = debtRaw
            .map(
              (item) =>
                  MoneyEntry.fromJson(jsonDecode(item) as Map<String, dynamic>),
            )
            .toList();
        _budget = prefs.getDouble('budget') ?? 240000;
        _budgetSliderValue = _budget;
        _budgetExpenseStart = budgetExpenseStartRaw == null
            ? null
            : DateTime.tryParse(budgetExpenseStartRaw);
        _budgetController.text = _budget.toStringAsFixed(0);
        _privacyLock = prefs.getBool('privacyLock') ?? false;
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'expenses',
      _expenses.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setStringList(
      'debts',
      _debts.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await prefs.setDouble('budget', _budget);
    if (_budgetExpenseStart == null) {
      await prefs.remove('budgetExpenseStart');
    } else {
      await prefs.setString(
        'budgetExpenseStart',
        _budgetExpenseStart!.toIso8601String(),
      );
    }
    await prefs.setBool('privacyLock', _privacyLock);
  }

  Future<void> _setBudgetFromText(String value) async {
    final parsed = double.tryParse(
      value.replaceAll(',', '').replaceAll('Rs.', '').trim(),
    );
    if (parsed == null || parsed <= 0) {
      _showSnack('Enter a budget greater than zero.');
      return;
    }
    _budgetFocusNode.unfocus();
    await _confirmBudgetChange(parsed);
  }

  Future<void> _confirmBudgetChange(double value) async {
    if (value == _budget) return;
    final includePrevious = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set a new budget?'),
        content: Text(
          'You have Rs. ${_expenses.fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)} in saved expenses. Should they count toward this budget?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Start fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Include expenses'),
          ),
        ],
      ),
    );
    if (includePrevious == null || !mounted) {
      if (mounted) {
        setState(() {
          _budgetSliderValue = _budget;
          _budgetController.text = _budget.toStringAsFixed(0);
        });
      }
      return;
    }
    setState(() {
      _budget = value;
      _budgetSliderValue = value;
      _budgetController.text = value.toStringAsFixed(0);
      _budgetExpenseStart = includePrevious ? null : DateTime.now();
    });
    await _save();
    if (mounted) {
      _showSnack('Monthly budget updated.');
    }
  }

  double get _spent => _expenses
      .where(
        (item) =>
            _budgetExpenseStart == null ||
            !item.date.isBefore(_budgetExpenseStart!),
      )
      .fold(0, (sum, item) => sum + item.amount);
  double get _received => _debts
      .where((item) => item.isOwedToMe && !item.settled)
      .fold(0, (sum, item) => sum + item.amount);
  double get _owed => _debts
      .where((item) => !item.isOwedToMe && !item.settled)
      .fold(0, (sum, item) => sum + item.amount);
  double get _availableBalance => _budget - _spent + _received - _owed;
  bool _matchesDate(DateTime date) {
    final now = DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    return switch (_dateFilter) {
      'Today' => normalized == today,
      'This week' =>
        !normalized.isBefore(
              today.subtract(Duration(days: today.weekday - 1)),
            ) &&
            !normalized.isAfter(today),
      'This month' =>
        normalized.year == today.year && normalized.month == today.month,
      'Specific month' =>
        _filterMonth != null &&
            _filterYear != null &&
            date.year == _filterYear &&
            date.month == _filterMonth,
      'Specific date' =>
        _specificDate != null &&
            normalized ==
                DateTime(
                  _specificDate!.year,
                  _specificDate!.month,
                  _specificDate!.day,
                ),
      _ => true,
    };
  }

  List<Expense> get _filteredExpenses {
    final result = _expenses
        .where(
          (item) =>
              (_expenseCategory == 'All' ||
                  item.category == _expenseCategory) &&
              (item.title.toLowerCase().contains(_expenseQuery.toLowerCase()) ||
                  item.category.toLowerCase().contains(
                    _expenseQuery.toLowerCase(),
                  )) &&
              _matchesDate(item.date),
        )
        .toList();
    result.sort(
      (a, b) => _sortNewestFirst
          ? b.date.compareTo(a.date)
          : a.date.compareTo(b.date),
    );
    return result;
  }

  List<MoneyEntry> get _filteredDebts {
    final result = _debts
        .where(
          (item) =>
              item.name.toLowerCase().contains(_debtQuery.toLowerCase()) ||
              item.note.toLowerCase().contains(_debtQuery.toLowerCase()),
        )
        .where((item) => item.dueDate == null || _matchesDate(item.dueDate!))
        .toList();
    result.sort(
      (a, b) {
        final aDate = a.dueDate ?? DateTime(2099);
        final bDate = b.dueDate ?? DateTime(2099);
        return _sortNewestFirst
            ? bDate.compareTo(aDate)
            : aDate.compareTo(bDate);
      },
    );
    return result;
  }

  void _addExpense() async {
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      builder: (_) => const AddExpenseSheet(),
    );
    if (result == null) return;
    setState(() => _expenses = [result, ..._expenses]);
    await _save();
    if (mounted) {
      _showSnack('Expense added.');
    }
  }

  Future<void> _addDebt() async {
    final result = await showModalBottomSheet<MoneyEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel,
      builder: (_) => const AddMoneySheet(),
    );
    if (result == null) return;
    setState(() => _debts = [result, ..._debts]);
    await _save();
    if (mounted) {
      _showSnack('Balance added for ${result.name}.');
    }
  }

  Future<void> _settleDebt(MoneyEntry item) async {
    setState(
      () => _debts = _debts
          .map(
            (entry) =>
                entry.id == item.id ? entry.copyWith(settled: true) : entry,
          )
          .toList(),
    );
    
    // If I gave them money (I owe them), create an expense entry
    if (!item.isOwedToMe) {
      setState(() => _expenses = [
        Expense(
          title: '${item.name} - Settled',
          amount: item.amount,
          category: 'Other',
          date: DateTime.now(),
        ),
        ..._expenses,
      ]);
    }
    
    await _save();
    if (mounted) {
      _showSnack(
        item.isOwedToMe
            ? '${item.name} settled your balance.'
            : 'Settlement added as an expense.',
      );
    }
  }

  Future<void> _deleteAllExpenses() async {
    if (_expenses.isEmpty) {
      _showSnack('There are no expenses to delete.');
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      title: 'Delete all expenses?',
      message: 'This will permanently remove ${_expenses.length} expense entries.',
      confirmLabel: 'Delete expenses',
    );
    if (!confirmed || !mounted) return;
    setState(() => _expenses = []);
    await _save();
    if (mounted) {
      _showSnack('All expenses deleted.');
    }
  }

  Future<void> _deleteAllPeople() async {
    if (_debts.isEmpty) {
      _showSnack('There are no people or balances to delete.');
      return;
    }
    final confirmed = await _confirmDestructiveAction(
      title: 'Delete all people?',
      message: 'This will permanently remove all people and balances, including settled ones.',
      confirmLabel: 'Delete people',
    );
    if (!confirmed || !mounted) return;
    setState(() => _debts = []);
    await _save();
    if (mounted) {
      _showSnack('All people and balances deleted.');
    }
  }

  Future<bool> _confirmDestructiveAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _pink),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showNotifications() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Financial check-in'),
        content: Text(
          _debts.where((item) => !item.settled).isEmpty
              ? 'You have ${_debts.where((item) => !item.settled).length} open balance(s) totalling Rs. ${(_received + _owed).toStringAsFixed(0)}.'
              : 'No open balances. Your ledger is up to date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showExport() {
    final backup = const JsonEncoder.withIndent('  ').convert({
      'expenses': _expenses.map((item) => item.toJson()).toList(),
      'balances': _debts.map((item) => item.toJson()).toList(),
      'monthlyBudget': _budget,
      'currency': 'PKR',
    });
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ledger backup'),
        content: SizedBox(
          width: double.maxFinite,
          child: SelectableText(
            backup,
            maxLines: 12,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backup));
              Navigator.pop(context);
              _showSnack('Backup copied to clipboard.');
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter and sort',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _dateFilter,
                decoration: const InputDecoration(
                  labelText: 'Date range',
                  prefixIcon: Icon(Icons.date_range_outlined),
                ),
                items:
                    [
                          'All time',
                          'Today',
                          'This week',
                          'This month',
                          'Specific month',
                          'Specific date',
                        ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) async {
                  if (value == 'Specific month') {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: _filterYear != null && _filterMonth != null
                          ? DateTime(_filterYear!, _filterMonth!)
                          : now,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSheetState(() {});
                      setState(() {
                        _filterMonth = picked.month;
                        _filterYear = picked.year;
                        _dateFilter = value!;
                      });
                    }
                  } else if (value == 'Specific date') {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: _specificDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setSheetState(() {});
                      setState(() {
                        _specificDate = picked;
                        _dateFilter = value!;
                      });
                    }
                  } else {
                    setSheetState(() {});
                    setState(() {
                      _dateFilter = value!;
                      _specificDate = null;
                      _filterMonth = null;
                      _filterYear = null;
                    });
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Newest first'),
                value: _sortNewestFirst,
                onChanged: (value) {
                  setSheetState(() {});
                  setState(() => _sortNewestFirst = value);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: FilledButton.styleFrom(
                    backgroundColor: _violet,
                    foregroundColor: const Color(0xFF003732),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboard(),
      _expensesPage(),
      _debtsPage(),
      _settingsPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _panel,
        indicatorColor: _violet.withValues(alpha: .18),
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded, color: _violet),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: _violet),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            selectedIcon: Icon(Icons.swap_horiz_rounded, color: _violet),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded, color: _violet),
            label: 'Budget',
          ),
        ],
      ),
    );
  }

  Widget _shell({
    required String eyebrow,
    required String title,
    required Widget child,
  }) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        sliver: SliverToBoxAdapter(child: _header(eyebrow, title)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        sliver: SliverToBoxAdapter(child: child),
      ),
    ],
  );
  Widget _header(String eyebrow, String title) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const KoinLogo(size: 42),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: _showNotifications,
        tooltip: 'View financial check-in',
        icon: const Icon(Icons.notifications_none_rounded, color: _muted),
      ),
    ],
  );

  Widget _dashboard() => _shell(
    eyebrow: 'Thursday, October 3',
    title: 'Good morning, Abdul Hanan',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _balanceCard(),
        const SizedBox(height: 22),
        _sectionTitle('This month', 'October 2026'),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              'Spent',
              'Rs. ${_spent.toStringAsFixed(0)}',
              Icons.arrow_upward_rounded,
              _pink,
            ),
            const SizedBox(width: 12),
            _statCard(
              'Available',
              'Rs. ${_availableBalance.toStringAsFixed(0)}',
              Icons.south_west_rounded,
              _green,
            ),
          ],
        ),
        const SizedBox(height: 22),
        _cashflowChart(),
        const SizedBox(height: 16),
        _categoryBreakdown(),
        const SizedBox(height: 24),
        _sectionTitle(
          'Recent activity',
          'See all',
          onTap: () => setState(() => _tab = 1),
        ),
        const SizedBox(height: 10),
        if (_expenses.isEmpty)
          _emptyState(
            'Your ledger is ready',
            'Add your first expense to start seeing your flow.',
          )
        else
          ..._expenses.take(4).map(_expenseTile),
        const SizedBox(height: 22),
        _sectionTitle(
          'People & balances',
          'Manage',
          onTap: () => setState(() => _tab = 2),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _miniBalance('You are owed', _received, _green),
            const SizedBox(width: 12),
            _miniBalance('You owe', _owed, _pink),
          ],
        ),
      ],
    ),
  );
  Widget _balanceCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF132227), Color(0xFF10171D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _green.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NET LIQUIDITY',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Rs. ${_availableBalance.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: _green, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${_expenses.isEmpty ? '0' : '12.8'}% from last month',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PKR',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _cashflowChart() {
    final today = DateTime.now();
    final values = _chartValues(today);
    final labels = _chartLabels(today);
    final total = values.fold(0.0, (sum, value) => sum + value);
    final detail = switch (_chartRange) {
      'Monthly' => 'Weekly totals · last 5 weeks',
      'Yearly' => 'Monthly totals · this year',
      _ => 'Daily totals · last 7 days',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_chartRange spending',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _chartRange,
                  dropdownColor: _panelHigh,
                  icon: const Icon(Icons.expand_more, color: _violet),
                  style: const TextStyle(
                    color: _violet,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  items: const ['Weekly', 'Monthly', 'Yearly']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _chartRange = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(painter: _CashflowPainter(values)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                )
                .toList(),
          ),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Add expenses to see your spending pattern.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  List<double> _chartValues(DateTime today) {
    if (_chartRange == 'Yearly') {
      return List.generate(
        12,
        (index) => _expenses
            .where(
              (item) =>
                  item.date.year == today.year && item.date.month == index + 1,
            )
            .fold(0, (sum, item) => sum + item.amount),
      );
    }
    if (_chartRange == 'Monthly') {
      return List.generate(5, (index) {
        final end = DateTime(
          today.year,
          today.month,
          today.day - ((4 - index) * 7),
        );
        final start = end.subtract(const Duration(days: 6));
        return _expenses
            .where(
              (item) =>
                  !item.date.isBefore(start) &&
                  !item.date.isAfter(end.add(const Duration(days: 1))),
            )
            .fold(0, (sum, item) => sum + item.amount);
      });
    }
    return List.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return _expenses
          .where(
            (item) =>
                item.date.year == day.year &&
                item.date.month == day.month &&
                item.date.day == day.day,
          )
          .fold(0, (sum, item) => sum + item.amount);
    });
  }

  List<String> _chartLabels(DateTime today) {
    if (_chartRange == 'Yearly') {
      return const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
    }
    if (_chartRange == 'Monthly') {
      return List.generate(5, (index) => 'W${index + 1}');
    }
    return List.generate(
      7,
      (index) => _weekday(today.subtract(Duration(days: 6 - index))),
    );
  }

  Widget _categoryBreakdown() {
    const categories = [
      'Food',
      'Transport',
      'Home',
      'Shopping',
      'Health',
      'Other',
    ];
    final totals = {
      for (final category in categories)
        category: _expenses
            .where((item) => item.category == category)
            .fold(0.0, (sum, item) => sum + item.amount),
    };
    final largest = totals.values.fold(
      0.0,
      (max, value) => value > max ? value : max,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by category',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ...categories.map((category) {
            final amount = totals[category]!;
            final ratio = largest == 0 ? 0.0 : amount / largest;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      category,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: _panelHigh,
                        color: category == 'Shopping' ? _gold : _violet,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 78,
                    child: Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _expensesPage() => _shell(
    eyebrow: 'Your ledger',
    title: 'Daily expenses',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('October spend', style: TextStyle(color: _muted)),
                    SizedBox(height: 5),
                    Text(
                      'Track the little things',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${_spent.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _violet,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _expenseQuery = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search expenses',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showFilters,
              tooltip: 'Filter and sort expenses',
              style: IconButton.styleFrom(backgroundColor: _panelHigh),
              icon: const Icon(Icons.tune_rounded, color: _violet),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_dateFilter == 'Specific month' && _filterMonth != null ? 'Month: ${_monthName(_filterMonth!)} ${_filterYear!}' : _dateFilter == 'Specific date' && _specificDate != null ? _date(_specificDate!) : _dateFilter} · ${_sortNewestFirst ? 'Newest first' : 'Oldest first'}',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                [
                      'All',
                      'Food',
                      'Transport',
                      'Home',
                      'Shopping',
                      'Health',
                      'Other',
                    ]
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _expenseCategory == category,
                          onSelected: (_) =>
                              setState(() => _expenseCategory = category),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('All transactions', 'Add expense', onTap: _addExpense),
        const SizedBox(height: 12),
        if (_filteredExpenses.isEmpty)
          _emptyState(
            _expenses.isEmpty ? 'No expenses yet' : 'No matching expenses',
            _expenses.isEmpty
                ? 'Tap Add expense to record a purchase.'
                : 'Try another search or category.',
          )
        else
          ..._filteredExpenses.map(_expenseTile),
      ],
    ),
  );
  Widget _debtsPage() => _shell(
    eyebrow: 'Split with ease',
    title: 'People & balances',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _miniBalance('To receive', _received, _green),
            const SizedBox(width: 12),
            _miniBalance('To pay', _owed, _pink),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _debtQuery = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search people or notes',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showFilters,
              tooltip: 'Filter and sort balances',
              style: IconButton.styleFrom(backgroundColor: _panelHigh),
              icon: const Icon(Icons.tune_rounded, color: _violet),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _sectionTitle('Open balances', 'Add balance', onTap: _addDebt),
        const SizedBox(height: 12),
        if (_filteredDebts.where((item) => !item.settled).isEmpty)
          _emptyState(
            _debts.isEmpty ? 'No balances yet' : 'No matching balances',
            _debts.isEmpty
                ? 'Add a person, amount, and due date to start tracking.'
                : 'Try another search or date filter.',
          )
        else
          ..._filteredDebts.where((item) => !item.settled).map(_debtTile),
        const SizedBox(height: 16),
        if (_filteredDebts.any((item) => item.settled))
          _sectionTitle(
            'Settled',
            '${_filteredDebts.where((item) => item.settled).length}',
          ),
        ..._filteredDebts.where((item) => item.settled).map(_debtTile),
      ],
    ),
  );
  Widget _debtTile(MoneyEntry item) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: item.settled ? _panelHigh : _panel,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: item.settled
            ? Colors.white.withValues(alpha: .03)
            : Colors.white.withValues(alpha: .06),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: (item.isOwedToMe ? _green : _pink).withValues(
            alpha: item.settled ? .08 : .16,
          ),
          child: Text(
            item.name.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: (item.isOwedToMe ? _green : _pink)
                  .withValues(alpha: item.settled ? 0.6 : 1.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: item.settled ? TextDecoration.lineThrough : null,
                  color: item.settled ? _muted : _ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.note}${item.dueDate != null ? ' · Due ${_date(item.dueDate!)}' : ''}',
                style: TextStyle(
                  color: item.settled ? _muted.withValues(alpha: .6) : _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.isOwedToMe ? '+' : '-'}Rs. ${item.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: item.isOwedToMe ? _green : _pink,
                fontWeight: FontWeight.w700,
                decoration: item.settled ? TextDecoration.lineThrough : null,
              ),
            ),
            if (!item.settled)
              TextButton(
                onPressed: () => _settleDebt(item),
                child: const Text('Settle'),
              )
            else
              const SizedBox(height: 32),
          ],
        ),
      ],
    ),
  );
  Widget _settingsPage() => _shell(
    eyebrow: 'Stay on track',
    title: 'Budget & settings',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _budgetCard(),
        const SizedBox(height: 24),
        _sectionTitle('Preferences', 'Stored on this device'),
        const SizedBox(height: 10),
        _settingTile(
          Icons.currency_exchange_rounded,
          'Default currency',
          'PKR — Pakistani Rupee',
          onTap: () => _showSnack('Koin Flow is configured for PKR.'),
        ),
        _settingTile(
          Icons.lock_outline_rounded,
          'Privacy lock',
          _privacyLock ? 'On' : 'Off',
          onTap: () {
            setState(() => _privacyLock = !_privacyLock);
            _save();
          },
        ),
        _settingTile(
          Icons.file_download_outlined,
          'Export ledger',
          'Copy JSON backup',
          onTap: _showExport,
        ),
        const SizedBox(height: 18),
        _sectionTitle('Data management', 'Permanent actions'),
        const SizedBox(height: 10),
        _settingTile(
          Icons.delete_sweep_outlined,
          'Delete all expenses',
          '${_expenses.length} saved expense${_expenses.length == 1 ? '' : 's'}',
          onTap: _deleteAllExpenses,
        ),
        _settingTile(
          Icons.group_remove_outlined,
          'Delete all people',
          '${_debts.length} saved balance${_debts.length == 1 ? '' : 's'}',
          onTap: _deleteAllPeople,
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'Koin Flow 1.0.0 · Local only',
            style: TextStyle(
              color: _muted.withValues(alpha: .65),
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _budgetCard() => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Monthly budget',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              'Rs. ${_budget.toStringAsFixed(0)}',
              style: const TextStyle(
                color: _violet,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _budgetController,
          focusNode: _budgetFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          textInputAction: TextInputAction.done,
          onTap: () {
            _budgetController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _budgetController.text.length,
            );
          },
          onSubmitted: _setBudgetFromText,
          decoration: InputDecoration(
            labelText: 'Type monthly limit',
            prefixText: 'Rs. ',
            suffixIcon: IconButton(
              tooltip: 'Save budget',
              onPressed: () => _setBudgetFromText(_budgetController.text),
              icon: const Icon(Icons.check_circle_outline, color: _violet),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_spent / _budget).clamp(0, 1),
            minHeight: 9,
            backgroundColor: _panelHigh,
            color: _spent > _budget ? _pink : _green,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Rs. ${_spent.toStringAsFixed(0)} spent of Rs. ${_budget.toStringAsFixed(0)}',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        Slider(
          value: _budgetSliderValue.clamp(5000, 1000000),
          min: 5000,
          max: 1000000,
          divisions: 199,
          onChanged: (value) {
            setState(() {
              _budgetSliderValue = value;
              _budgetController.text = value.toStringAsFixed(0);
            });
          },
          onChangeEnd: _confirmBudgetChange,
        ),
      ],
    ),
  );
  Widget _settingTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(vertical: 2),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: _violet, size: 20),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: _muted, fontSize: 13),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
  );
  Widget _expenseTile(Expense item) => Dismissible(
    key: ValueKey('${item.title}-${item.date}'),
    onDismissed: (_) {
      setState(() => _expenses.remove(item));
      _save();
      _showSnack('Expense deleted.');
    },
    background: Container(
      color: _pink.withValues(alpha: .15),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: _pink),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _violet.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(item.category), color: _violet, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.category} · ${_date(item.date)}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '-Rs. ${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _pink),
          ),
        ],
      ),
    ),
  );
  Widget _sectionTitle(String title, String action, {VoidCallback? onTap}) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                color: _violet,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
  Widget _miniBalance(String label, double amount, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 7),
          Text(
            'Rs. ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _emptyState(String title, String subtitle) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
    decoration: BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: _violet, size: 28),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
      ],
    ),
  );
  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
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
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      14,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'New expense',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'What did you spend on?',
            prefixIcon: Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: 'Rs. ',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _category,
          dropdownColor: _panelHigh,
          decoration: const InputDecoration(labelText: 'Category'),
          items: ['Food', 'Transport', 'Home', 'Shopping', 'Health', 'Other']
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final amount = double.tryParse(_amount.text.replaceAll(',', ''));
              if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
                return;
              }
              Navigator.pop(
                context,
                Expense(
                  title: _title.text.trim(),
                  amount: amount,
                  category: _category,
                  date: DateTime.now(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: _violet,
              foregroundColor: const Color(0xFF1000A9),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'Save expense',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class AddMoneySheet extends StatefulWidget {
  const AddMoneySheet({super.key});
  @override
  State<AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<AddMoneySheet> {
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime? _dueDate;
  bool _isOwedToMe = true;
  bool _setDueDate = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      14,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Add Balance',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('They owe me')),
              ButtonSegment(value: false, label: Text('I owe them')),
            ],
            selected: {_isOwedToMe},
            onSelectionChanged: (value) =>
                setState(() => _isOwedToMe = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Person name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'Rs. ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'What is it for?',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set due date'),
            subtitle: const Text('Optional — set a reminder for payment'),
            value: _setDueDate,
            onChanged: (value) {
              setState(() => _setDueDate = value);
              if (value && _dueDate == null) {
                _dueDate = DateTime.now().add(const Duration(days: 14));
              }
            },
          ),
          if (_setDueDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: _chooseDate,
              leading: const Icon(Icons.event_outlined, color: _violet),
              title: const Text('Due date'),
              subtitle: Text(_date(_dueDate ?? DateTime.now())),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final amount = double.tryParse(_amount.text.replaceAll(',', ''));
                if (_name.text.trim().isEmpty || amount == null || amount <= 0) {
                  return;
                }
                Navigator.pop(
                  context,
                  MoneyEntry(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: _name.text.trim(),
                    amount: amount,
                    note: _note.text.trim().isEmpty
                        ? 'Personal balance'
                        : _note.text.trim(),
                    isOwedToMe: _isOwedToMe,
                    dueDate: _setDueDate ? _dueDate : null,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: const Color(0xFF003732),
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                'Save balance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class KoinLogo extends StatelessWidget {
  const KoinLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/koin_logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    semanticLabel: 'Koin Flow logo',
  );
}

class _CashflowPainter extends CustomPainter {
  const _CashflowPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = values.fold(
      0.0,
      (max, value) => value > max ? value : max,
    );
    final ceiling = maxValue == 0 ? 1.0 : maxValue * 1.25;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final y = maxValue == 0
          ? size.height - 4
          : size.height - (values[index] / ceiling * (size.height - 8));
      points.add(Offset(x, y));
    }
    final area = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      area.lineTo(point.dx, point.dy);
    }
    area
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = _violet.withValues(alpha: .10));
    final line = Paint()
      ..color = _violet
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(path, line);
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = _green);
    }
  }

  @override
  bool shouldRepaint(covariant _CashflowPainter oldDelegate) =>
      oldDelegate.values != values;
}

IconData _categoryIcon(String category) => switch (category) {
  'Food' => Icons.restaurant_rounded,
  'Transport' => Icons.directions_car_rounded,
  'Home' => Icons.home_rounded,
  'Shopping' => Icons.shopping_bag_rounded,
  'Health' => Icons.favorite_rounded,
  _ => Icons.more_horiz_rounded,
};
String _date(DateTime date) => '${date.month}/${date.day}';
String _monthName(int month) => const [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
][month - 1];
String _weekday(DateTime date) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
