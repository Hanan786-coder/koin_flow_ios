import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'charts.dart';
import 'demo.dart';
import 'format.dart';
import 'ios.dart';
import 'models.dart';
import 'sheets.dart';
import 'theme.dart';
import 'widgets.dart';

const _dateFilters = [
  'All time',
  'Today',
  'This week',
  'This month',
  'Last month',
  'Pick a date',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.now});

  /// Injected clock for tests.
  final DateTime Function()? now;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  double _budget = 240000;
  DateTime? _budgetExpenseStart;
  List<Expense> _expenses = [];
  List<MoneyEntry> _debts = [];
  List<Bill> _bills = [];
  String _name = 'Abdul Hanan';
  bool _hideAmounts = false;

  String _expenseQuery = '';
  String _debtQuery = '';
  String _expenseCategory = 'All';
  String _dateFilter = 'All time';
  DateTime? _specificDate;
  bool _sortNewestFirst = true;

  OverlayEntry? _toastEntry;
  Timer? _toastTimer;
  final _toastKey = GlobalKey<_ToastState>();

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    super.dispose();
  }

  // ───────────────────────── persistence ─────────────────────────

  /// Records we couldn't read are kept verbatim and written back on save,
  /// so an unexpected format never deletes anything.
  final _unreadable = <String, List<String>>{
    'expenses': [],
    'debts': [],
    'bills': [],
  };

  /// Saving is blocked until stored data has been read, so a slow or failed
  /// load can never overwrite existing data with an empty list.
  bool _loaded = false;

  List<T> _decodeAll<T>(
    String key,
    List<String> raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final out = <T>[];
    for (final item in raw) {
      try {
        out.add(fromJson(Map<String, dynamic>.from(jsonDecode(item) as Map)));
      } catch (_) {
        _unreadable[key]!.add(item);
      }
    }
    return out;
  }

  Future<void> _load() async {
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return; // Storage unavailable: stay read-only rather than risk data.
    }
    final expenses = _decodeAll(
      'expenses',
      prefs.getStringList('expenses') ?? [],
      Expense.fromJson,
    );
    // Older saves derived ids from title + time; make sure none collide.
    final seen = <String>{};
    for (var i = 0; i < expenses.length; i++) {
      if (!seen.add(expenses[i].id)) {
        final e = expenses[i];
        expenses[i] = Expense(
          title: e.title,
          amount: e.amount,
          category: e.category,
          date: e.date,
          note: e.note,
        );
        seen.add(expenses[i].id);
      }
    }
    final debts = _decodeAll(
      'debts',
      prefs.getStringList('debts') ?? [],
      MoneyEntry.fromJson,
    );
    final bills = _decodeAll(
      'bills',
      prefs.getStringList('bills') ?? [],
      Bill.fromJson,
    );
    final startRaw = prefs.getString('budgetExpenseStart');
    if (!mounted) return;
    {
      setState(() {
        _loaded = true;
        _expenses = expenses;
        _debts = debts;
        _bills = bills;
        final budget = prefs.get('budget');
        _budget = budget is num && budget > 0 ? budget.toDouble() : 240000;
        _budgetExpenseStart = startRaw == null
            ? null
            : DateTime.tryParse(startRaw);
        final hide = prefs.get('privacyLock');
        _hideAmounts = hide is bool && hide;
        final name = prefs.get('userName');
        _name = name is String && name.trim().isNotEmpty ? name : 'Abdul Hanan';
        if (kDemo && _expenses.isEmpty && _bills.isEmpty) {
          final demo = demoData(_now);
          _expenses = demo.expenses;
          _debts = demo.debts;
          _bills = demo.bills;
          _budget = 150000;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expenses', [
      ..._expenses.map((e) => jsonEncode(e.toJson())),
      ..._unreadable['expenses']!,
    ]);
    await prefs.setStringList('debts', [
      ..._debts.map((e) => jsonEncode(e.toJson())),
      ..._unreadable['debts']!,
    ]);
    await prefs.setStringList('bills', [
      ..._bills.map((e) => jsonEncode(e.toJson())),
      ..._unreadable['bills']!,
    ]);
    await prefs.setDouble('budget', _budget);
    if (_budgetExpenseStart == null) {
      await prefs.remove('budgetExpenseStart');
    } else {
      await prefs.setString(
        'budgetExpenseStart',
        _budgetExpenseStart!.toIso8601String(),
      );
    }
    await prefs.setBool('privacyLock', _hideAmounts);
    await prefs.setString('userName', _name);
  }

  // ───────────────────────── numbers ─────────────────────────

  bool _inMonth(DateTime d, DateTime month) =>
      d.year == month.year && d.month == month.month;

  /// Expenses that count toward this month's budget.
  Iterable<Expense> get _budgetExpenses => _expenses.where(
    (e) =>
        _inMonth(e.date, _now) &&
        (_budgetExpenseStart == null || !e.date.isBefore(_budgetExpenseStart!)),
  );

  double get _spent => _budgetExpenses.fold(0, (s, e) => s + e.amount);

  double get _spentToday {
    final t = dayOnly(_now);
    return _expenses
        .where((e) => dayOnly(e.date) == t)
        .fold(0, (s, e) => s + e.amount);
  }

  /// Spent in the same days of last month (1st → today's date).
  double get _spentSameTimeLastMonth {
    final now = _now;
    final lastMonth = DateTime(now.year, now.month - 1);
    final cutoff = math.min(now.day, daysInMonth(lastMonth));
    return _expenses
        .where((e) => _inMonth(e.date, lastMonth) && e.date.day <= cutoff)
        .fold(0, (s, e) => s + e.amount);
  }

  double get _received => _debts
      .where((e) => e.isOwedToMe && !e.settled)
      .fold(0, (s, e) => s + e.amount);

  double get _owed => _debts
      .where((e) => !e.isOwedToMe && !e.settled)
      .fold(0, (s, e) => s + e.amount);

  List<Bill> get _unpaidBills =>
      _bills.where((b) => !b.isPaidFor(_now)).toList()
        ..sort((a, b) => a.dueDay.compareTo(b.dueDay));

  double get _reserved => _unpaidBills.fold(0, (s, b) => s + b.amount);

  /// Money lent out is treated as already gone from the budget.
  double get _left => _budget - _spent - _received;

  int get _daysLeft => daysInMonth(_now) - _now.day + 1;

  double get _safePerDay => math.max(0, _left - _reserved) / _daysLeft;

  // ───────────────────────── filtering ─────────────────────────

  bool _matchesDate(DateTime date) {
    final today = dayOnly(_now);
    final d = dayOnly(date);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return switch (_dateFilter) {
      'Today' => d == today,
      'This week' =>
        !d.isBefore(weekStart) &&
            d.isBefore(weekStart.add(const Duration(days: 7))),
      'This month' => _inMonth(d, today),
      'Last month' => _inMonth(d, DateTime(today.year, today.month - 1)),
      'Pick a date' => _specificDate != null && d == dayOnly(_specificDate!),
      _ => true,
    };
  }

  String get _dateFilterLabel =>
      _dateFilter == 'Pick a date' && _specificDate != null
      ? relativeDay(_specificDate!, now: _now)
      : _dateFilter;

  List<Expense> get _filteredExpenses {
    final q = _expenseQuery.toLowerCase();
    final result = _expenses
        .where(
          (e) =>
              (_expenseCategory == 'All' || e.category == _expenseCategory) &&
              (q.isEmpty ||
                  e.title.toLowerCase().contains(q) ||
                  e.note.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q)) &&
              _matchesDate(e.date),
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
    final q = _debtQuery.toLowerCase();
    final result = _debts
        .where(
          (e) =>
              q.isEmpty ||
              e.name.toLowerCase().contains(q) ||
              e.note.toLowerCase().contains(q),
        )
        .toList();
    result.sort((a, b) {
      final ad = a.dueDate ?? DateTime(2099);
      final bd = b.dueDate ?? DateTime(2099);
      return ad.compareTo(bd);
    });
    return result;
  }

  // ───────────────────────── actions ─────────────────────────

  Future<T?> _sheet<T>(Widget child) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => child,
  );

  Future<void> _openExpense([Expense? initial]) async {
    final result = await _sheet<ExpenseSheetResult>(
      AddExpenseSheet(initial: initial),
    );
    if (result == null || !mounted) return;
    if (result.deleted) {
      _deleteExpense(result.expense);
      return;
    }
    final e = result.expense;
    setState(() {
      final i = _expenses.indexWhere((x) => x.id == e.id);
      if (i >= 0) {
        _expenses[i] = e;
      } else {
        _expenses = [e, ..._expenses];
      }
    });
    await _save();
    if (!mounted) return;
    final left = _left - _reserved;
    _toast(
      initial == null
          ? '${e.title} added · ${rs(math.max(0, left), hidden: _hideAmounts)} left to spend'
          : 'Changes saved',
    );
  }

  void _deleteExpense(Expense e) {
    final index = _expenses.indexWhere((x) => x.id == e.id);
    if (index < 0) return;
    setState(() => _expenses.removeAt(index));
    _save();
    _toast(
      '${e.title} deleted',
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Undo',
      onAction: () {
        setState(() => _expenses.insert(math.min(index, _expenses.length), e));
        _save();
      },
    );
  }

  Future<void> _addDebt() async {
    final result = await _sheet<MoneyEntry>(const AddMoneySheet());
    if (result == null || !mounted) return;
    setState(() => _debts = [result, ..._debts]);
    await _save();
    if (mounted) _toast('Balance added for ${result.name}');
  }

  Future<void> _settleDebt(MoneyEntry item) async {
    HapticFeedback.mediumImpact();
    final before = List<MoneyEntry>.of(_debts);
    final beforeExpenses = List<Expense>.of(_expenses);
    setState(() {
      _debts = _debts
          .map((e) => e.id == item.id ? e.copyWith(settled: true) : e)
          .toList();
      // Paying someone back is money leaving your pocket.
      if (!item.isOwedToMe) {
        _expenses = [
          Expense(
            title: '${item.name} — settled',
            amount: item.amount,
            category: 'Other',
            date: _now,
          ),
          ..._expenses,
        ];
      }
    });
    await _save();
    if (!mounted) return;
    _toast(
      item.isOwedToMe
          ? '${item.name} paid you back'
          : 'Paid ${item.name} · logged as an expense',
      actionLabel: 'Undo',
      onAction: () {
        setState(() {
          _debts = before;
          _expenses = beforeExpenses;
        });
        _save();
      },
    );
  }

  void _deleteDebt(MoneyEntry item) {
    final index = _debts.indexWhere((e) => e.id == item.id);
    if (index < 0) return;
    setState(() => _debts.removeAt(index));
    _save();
    _toast(
      '${item.name} removed',
      icon: Icons.delete_outline_rounded,
      actionLabel: 'Undo',
      onAction: () {
        setState(() => _debts.insert(math.min(index, _debts.length), item));
        _save();
      },
    );
  }

  Future<void> _openBill([Bill? initial]) async {
    final result = await _sheet<BillSheetResult>(
      AddBillSheet(initial: initial),
    );
    if (result == null || !mounted) return;
    final bill = result.bill;
    if (result.deleted) {
      final index = _bills.indexWhere((b) => b.id == bill.id);
      setState(() => _bills.removeWhere((b) => b.id == bill.id));
      await _save();
      if (!mounted) return;
      _toast(
        '${bill.name} removed',
        icon: Icons.delete_outline_rounded,
        actionLabel: 'Undo',
        onAction: () {
          setState(() => _bills.insert(math.max(0, index), bill));
          _save();
        },
      );
      return;
    }
    setState(() {
      final i = _bills.indexWhere((b) => b.id == bill.id);
      if (i >= 0) {
        _bills[i] = bill;
      } else {
        _bills = [..._bills, bill];
      }
    });
    await _save();
    if (mounted) {
      _toast(
        initial == null
            ? '${bill.name} added · due every ${ordinal(bill.dueDay)}'
            : 'Changes saved',
      );
    }
  }

  Future<void> _payBill(Bill bill) async {
    HapticFeedback.mediumImpact();
    final expense = Expense(
      title: bill.name,
      amount: bill.amount,
      category: 'Bills',
      date: _now,
      note: 'Monthly bill',
    );
    final key = Bill.monthKey(_now);
    setState(() {
      _bills = _bills
          .map(
            (b) => b.id == bill.id
                ? b.copyWith(paidMonths: [...b.paidMonths, key])
                : b,
          )
          .toList();
      _expenses = [expense, ..._expenses];
    });
    await _save();
    if (!mounted) return;
    _toast(
      '${bill.name} paid · logged as an expense',
      actionLabel: 'Undo',
      onAction: () {
        setState(() {
          _bills = _bills
              .map(
                (b) => b.id == bill.id
                    ? b.copyWith(
                        paidMonths: b.paidMonths
                            .where((m) => m != key)
                            .toList(),
                      )
                    : b,
              )
              .toList();
          _expenses.removeWhere((e) => e.id == expense.id);
        });
        _save();
      },
    );
  }

  Future<void> _editBudget() async {
    final value = await _sheet<double>(
      BudgetSheet(current: _budget, spent: _spent),
    );
    if (value == null || value == _budget || !mounted) return;
    final countIt = await showIOSAlert<bool?>(
      context,
      title: 'Set budget to ${rs(value)}?',
      message:
          'You\'ve spent ${rs(_spent)} this month. Should that count toward the new budget?',
      actions: const [
        IOSAction<bool?>('Count it', true, isDefault: true),
        IOSAction<bool?>('Start fresh from today', false),
        IOSAction<bool?>('Cancel', null),
      ],
    );
    if (countIt == null || !mounted) return;
    setState(() {
      _budget = value;
      _budgetExpenseStart = countIt ? null : _now;
    });
    await _save();
    if (mounted) _toast('Monthly budget set to ${rs(value)}');
  }

  Future<bool> _confirmDestructive({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showIOSAlert<bool>(
      context,
      title: title,
      message: message,
      actions: [
        const IOSAction('Cancel', false, isDefault: true),
        IOSAction(confirmLabel, true, destructive: true),
      ],
    );
    return result ?? false;
  }

  Future<void> _deleteAllExpenses() async {
    if (_expenses.isEmpty) {
      _toast(
        'There are no expenses to delete',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    final ok = await _confirmDestructive(
      title: 'Delete all expenses?',
      message:
          'This permanently removes ${_expenses.length} expenses. It can\'t be undone.',
      confirmLabel: 'Delete all',
    );
    if (!ok || !mounted) return;
    setState(() {
      _expenses = [];
      _unreadable['expenses']!.clear();
    });
    await _save();
    if (mounted) _toast('All expenses deleted');
  }

  Future<void> _deleteAllPeople() async {
    if (_debts.isEmpty) {
      _toast(
        'There are no balances to delete',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    final ok = await _confirmDestructive(
      title: 'Delete all balances?',
      message: 'This permanently removes every person and balance, including settled ones.',
      confirmLabel: 'Delete all',
    );
    if (!ok || !mounted) return;
    setState(() {
      _debts = [];
      _unreadable['debts']!.clear();
    });
    await _save();
    if (mounted) _toast('All balances deleted');
  }

  void _showCheckIn() {
    final open = _debts.where((e) => !e.settled).toList();
    final today = dayOnly(_now);
    final dueSoon = _unpaidBills.where((b) => b.daysUntilDue(today) <= 7);
    final lines = <String>[
      'You can spend about ${rs(_safePerDay)} a day for the next $_daysLeft days.',
      if (dueSoon.isEmpty)
        'No bills due in the next 7 days.'
      else
        '${dueSoon.length} bill${dueSoon.length == 1 ? '' : 's'} due soon, ${rs(dueSoon.fold(0.0, (s, b) => s + b.amount))} in total.',
      if (open.isEmpty)
        'No open balances with people.'
      else
        '${rs(_received)} owed to you, ${rs(_owed)} you owe.',
    ];
    showIOSAlert<void>(
      context,
      title: 'Your check-in',
      message: lines.join('\n\n'),
      actions: const [IOSAction('Done', null, isDefault: true)],
    );
  }

  Map<String, dynamic> get _backup => {
    'expenses': _expenses.map((e) => e.toJson()).toList(),
    'balances': _debts.map((e) => e.toJson()).toList(),
    'bills': _bills.map((e) => e.toJson()).toList(),
    'monthlyBudget': _budget,
    'currency': 'PKR',
  };

  Future<void> _showExport() async {
    final copy = await showIOSAlert<bool>(
      context,
      title: 'Back up your ledger',
      message:
          'Copies ${_expenses.length} expenses, ${_debts.length} balances, ${_bills.length} bills and your budget as text. Paste it into Notes or send it to yourself.',
      actions: const [
        IOSAction('Cancel', false),
        IOSAction('Copy backup', true, isDefault: true),
      ],
    );
    if (copy != true || !mounted) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_backup)),
    );
    if (mounted) _toast('Backup copied. Paste it somewhere safe');
  }

  Future<void> _showImport() async {
    final backup = await showIOSPrompt(
      context,
      title: 'Restore a backup',
      message: 'Paste the text you copied with Back up your ledger.',
      placeholder: 'Paste backup here',
      confirm: 'Restore',
      multiline: true,
    );
    if (backup == null || backup.trim().isEmpty || !mounted) return;
    try {
      final decoded = jsonDecode(backup);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('the backup isn\'t a ledger.');
      }
      final ex = decoded['expenses'];
      final bal = decoded['balances'];
      if (ex is! List || bal is! List) {
        throw const FormatException('expenses or balances are missing.');
      }
      final expenses = ex
          .map((e) => Expense.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final debts = bal
          .map((e) => MoneyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final billsRaw = decoded['bills'];
      final bills = billsRaw is List
          ? billsRaw
                .map((e) => Bill.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList()
          : _bills;
      if (!mounted) return;
      final ok = await _confirmDestructive(
        title: 'Replace data on this phone?',
        message:
            'The backup has ${expenses.length} expenses and ${debts.length} balances. What\'s on this phone now will be replaced.',
        confirmLabel: 'Replace',
      );
      if (!ok || !mounted) return;
      final budget = decoded['monthlyBudget'];
      setState(() {
        _expenses = expenses;
        _debts = debts;
        _bills = bills;
        if (budget is num && budget > 0) _budget = budget.toDouble();
      });
      await _save();
      if (mounted) _toast('Ledger restored');
    } on FormatException catch (e) {
      _toast(
        'Couldn\'t restore: ${e.message}',
        icon: Icons.error_outline_rounded,
      );
    } on TypeError {
      _toast(
        'Couldn\'t restore: some entries are damaged',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<void> _editName() async {
    final name = await showIOSPrompt(
      context,
      title: 'What should we call you?',
      initial: _name,
      placeholder: 'Your name',
      capitalization: TextCapitalization.words,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() => _name = name.trim());
    _save();
  }

  void _toggleHidden() {
    HapticFeedback.selectionClick();
    setState(() => _hideAmounts = !_hideAmounts);
    _save();
  }

  // ───────────────────────── toast ─────────────────────────

  void _toast(
    String message, {
    IconData icon = Icons.check_circle_rounded,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    void close() {
      _toastTimer?.cancel();
      _toastKey.currentState?.dismiss().then((_) {
        if (entry.mounted) entry.remove();
        if (identical(_toastEntry, entry)) _toastEntry = null;
      });
    }

    entry = OverlayEntry(
      builder: (_) => _Toast(
        key: _toastKey,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onAction();
                close();
              },
      ),
    );
    _toastEntry = entry;
    overlay.insert(entry);
    _toastTimer = Timer(Duration(seconds: actionLabel == null ? 3 : 5), close);
  }

  // ───────────────────────── layout ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = [_overview(), _expensesPage(), _peoplePage(), _planPage()];
    final fab = switch (_tab) {
      0 || 1 => ('Add expense', () => _openExpense()),
      2 => ('Add balance', _addDebt),
      _ => ('Add bill', () => _openBill()),
    };
    return Scaffold(
      extendBody: true,
      body: TweenAnimationBuilder<double>(
        key: ValueKey(_tab),
        tween: Tween(begin: 0, end: 1),
        duration: K.motion(context, 320),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: child,
          ),
        ),
        child: IndexedStack(index: _tab, children: pages),
      ),
      floatingActionButton: _AddButton(label: fab.$1, onTap: fab.$2),
      bottomNavigationBar: _TabBar(
        index: _tab,
        onTap: (i) {
          if (i == _tab) return;
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
      ),
    );
  }

  /// A tab page. With [title] it gets an iOS large-title navigation bar that
  /// collapses on scroll; otherwise [header] is drawn under the status bar.
  Widget _page({
    String? title,
    String? subtitle,
    Widget? header,
    List<Widget> actions = const [],
    required List<Widget> children,
  }) => Builder(
    builder: (context) {
      final pad = MediaQuery.paddingOf(context);
      final scroll = CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (title != null)
            CupertinoSliverNavigationBar(
              heroTag: 'nav-$title',
              transitionBetweenRoutes: false,
              automaticallyImplyLeading: false,
              backgroundColor: K.ledger.withValues(alpha: .82),
              border: null,
              largeTitle: Text(title, style: K.display(34, spacing: -0.9)),
              middle: Text(title, style: K.body(17, weight: FontWeight.w700)),
              alwaysShowMiddle: false,
              trailing: actions.isEmpty
                  ? null
                  : Row(mainAxisSize: MainAxisSize.min, children: actions),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, pad.top + 10, 20, 0),
              sliver: SliverToBoxAdapter(child: header),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              title == null ? 20 : 4,
              20,
              pad.bottom + 110,
            ),
            sliver: SliverList.list(
              children: [
                if (subtitle != null) ...[
                  Text(subtitle, style: K.body(14, color: K.sage)),
                  const SizedBox(height: 16),
                ],
                ...children,
              ],
            ),
          ),
        ],
      );
      if (title != null) return scroll;
      // Fade content out under the status bar, like iOS does.
      return Stack(
        children: [
          scroll,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: pad.top + 14,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [K.ledger, K.ledger.withValues(alpha: 0)],
                    stops: const [.6, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: Pressable(
          onTap: onTap,
          semanticLabel: tooltip,
          child: Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(left: 8),
            decoration: const BoxDecoration(
              color: K.felt,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: K.parchment),
          ),
        ),
      );

  // ───────────────────────── overview ─────────────────────────

  Widget _overview() {
    final first = _name.split(' ').first;
    return _page(
      header: Row(
        children: [
          const KoinLogo(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${greeting(_now)}, $first',
                  style: K.display(22, spacing: -0.4),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(longDate(_now), style: K.body(13, color: K.sage)),
              ],
            ),
          ),
          _iconButton(
            _hideAmounts
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            _hideAmounts ? 'Show amounts' : 'Hide amounts',
            _toggleHidden,
          ),
          _iconButton(
            Icons.notifications_none_rounded,
            'Your check-in',
            _showCheckIn,
          ),
        ],
      ),
      children: [
        _hero(),
        const SizedBox(height: 14),
        _pace(),
        ..._dueSoon(),
        const SizedBox(height: 28),
        InsightsCard(
          expenses: _expenses,
          now: _now,
          budget: _budget,
          hidden: _hideAmounts,
        ),
        const SizedBox(height: 28),
        SectionHeader(
          'Recent',
          action: _expenses.isEmpty ? null : 'See all',
          onAction: () => setState(() => _tab = 1),
        ),
        if (_expenses.isEmpty)
          EmptyNote(
            icon: Icons.receipt_long_rounded,
            title: 'Your ledger is open',
            body: 'Add what you spend and Koin Flow works out a daily limit for you.',
            action: 'Add first expense',
            onAction: () => _openExpense(),
          )
        else
          Panel(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                for (final e in (List.of(
                  _expenses,
                )..sort((a, b) => b.date.compareTo(a.date))).take(4))
                  _expenseRow(e, swipe: false),
              ],
            ),
          ),
        const SizedBox(height: 28),
        SectionHeader(
          'People',
          action: 'Manage',
          onAction: () => setState(() => _tab = 2),
        ),
        Row(
          children: [
            _miniStat('Owed to you', _received, K.mint),
            const SizedBox(width: 12),
            _miniStat('You owe', _owed, K.rose),
          ],
        ),
      ],
    );
  }

  Widget _hero() {
    final spentRatio = _budget <= 0 ? 0.0 : (_spent + _received) / _budget;
    final reservedRatio = _budget <= 0 ? 0.0 : _reserved / _budget;
    final monthRatio = _now.day / daysInMonth(_now);
    final over = _left < 0;
    return Panel(
      radius: K.rHero,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      child: Column(
        children: [
          BudgetRing(
            spentRatio: spentRatio,
            reservedRatio: reservedRatio,
            monthRatio: monthRatio,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  over ? 'Over budget by' : 'Left this month',
                  style: K.body(14, color: K.sage),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34),
                    child: CountUp(
                      value: _left.abs(),
                      hidden: _hideAmounts,
                      duration: 1200,
                      style: K.display(
                        38,
                        spacing: -1.2,
                        color: over ? K.rose : K.parchment,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of ${rs(_budget, hidden: _hideAmounts)}',
                  style: K.body(13, color: K.sage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _heroFact(
                'Safe per day',
                _safePerDay,
                K.brass,
                '$_daysLeft days left',
              ),
              _divider(),
              _heroFact(
                'Spent today',
                _spentToday,
                _spentToday > _safePerDay && _spentToday > 0
                    ? K.rose
                    : K.parchment,
                _spentToday > _safePerDay && _spentToday > 0
                    ? 'Above your limit'
                    : 'Within limit',
              ),
              _divider(),
              _heroFact(
                'For bills',
                _reserved,
                K.parchment,
                _unpaidBills.isEmpty
                    ? 'All paid'
                    : '${_unpaidBills.length} unpaid',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: K.seam,
  );

  Widget _heroFact(String label, double value, Color color, String foot) =>
      Expanded(
        child: Column(
          children: [
            Text(label, style: K.body(12, color: K.sage)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: CountUp(
                value: value,
                hidden: _hideAmounts,
                style: K.display(17, color: color),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              foot,
              style: K.body(11, color: K.sage.withValues(alpha: .8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _pace() {
    final last = _spentSameTimeLastMonth;
    final now = _spent;
    if (last == 0 && now == 0) return const SizedBox.shrink();
    final String text;
    final Color color;
    final IconData icon;
    if (last == 0) {
      text = 'First month on record — keep logging to see your trend.';
      color = K.sage;
      icon = Icons.insights_rounded;
    } else {
      final diff = now - last;
      final pct = (diff.abs() / last * 100).round();
      if (pct == 0) {
        text = 'Spending at the same pace as last month.';
        color = K.sage;
        icon = Icons.trending_flat_rounded;
      } else if (diff < 0) {
        text =
            '${_hideAmounts ? '' : '${rs(diff.abs())} · '}$pct% less than this time last month.';
        color = K.mint;
        icon = Icons.trending_down_rounded;
      } else {
        text =
            '${_hideAmounts ? '' : '${rs(diff)} · '}$pct% more than this time last month.';
        color = K.rose;
        icon = Icons.trending_up_rounded;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: K.body(13, color: color, height: 1.3)),
          ),
        ],
      ),
    );
  }

  List<Widget> _dueSoon() {
    final today = dayOnly(_now);
    final bills = _unpaidBills
        .where((b) => b.daysUntilDue(today) <= 7)
        .toList();
    final debts = _debts
        .where(
          (d) =>
              !d.settled &&
              d.dueDate != null &&
              dayOnly(d.dueDate!).difference(today).inDays <= 7,
        )
        .toList();
    if (bills.isEmpty && debts.isEmpty) return const [];
    return [
      const SizedBox(height: 28),
      const SectionHeader('Coming up'),
      SizedBox(
        height: 128,
        child: ListView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          children: [
            for (final b in bills) _dueCard(bill: b),
            for (final d in debts) _dueCard(debt: d),
          ],
        ),
      ),
    ];
  }

  Widget _dueCard({Bill? bill, MoneyEntry? debt}) {
    final today = dayOnly(_now);
    final days = bill != null
        ? bill.daysUntilDue(today)
        : dayOnly(debt!.dueDate!).difference(today).inDays;
    final when = days < 0
        ? '${-days} day${days == -1 ? '' : 's'} late'
        : days == 0
        ? 'Due today'
        : days == 1
        ? 'Due tomorrow'
        : 'Due in $days days';
    final late = days < 0;
    final title = bill?.name ?? debt!.name;
    final amount = bill?.amount ?? debt!.amount;
    final action = bill != null
        ? 'Mark paid'
        : (debt!.isOwedToMe ? 'Got it' : 'Paid');
    return Container(
      width: 168,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: K.felt,
        borderRadius: BorderRadius.circular(K.rTile),
        border: Border.all(
          color: late ? K.rose.withValues(alpha: .5) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            when,
            style: K.body(
              12,
              color: late ? K.rose : K.brass,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: K.body(15, weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            rs(amount, hidden: _hideAmounts),
            style: K.display(16, color: K.sage, weight: FontWeight.w600),
          ),
          const Spacer(),
          Pressable(
            onTap: () => bill != null ? _payBill(bill) : _settleDebt(debt!),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: K.brass.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                action,
                style: K.body(13, color: K.brass, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, double value, Color color) => Expanded(
    child: Panel(
      radius: K.rTile,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: K.body(13, color: K.sage)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUp(
              value: value,
              hidden: _hideAmounts,
              style: K.display(22, color: color),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _expenseRow(Expense e, {bool swipe = true, bool showDate = true}) {
    final row = Pressable(
      onTap: () => _openExpense(e),
      scale: .985,
      semanticLabel: '${e.title}, ${rs(e.amount)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CategoryBadge(e.category),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: K.body(15, weight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      e.category,
                      if (showDate) relativeDay(e.date, now: _now),
                      if (e.note.isNotEmpty) e.note,
                    ].join('  ·  '),
                    style: K.body(13, color: K.sage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _hideAmounts ? 'Rs ••••' : '−${rs(e.amount)}',
              style: K.display(16, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    if (!swipe) return row;
    return Dismissible(
      key: ValueKey('exp-${e.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteExpense(e),
      background: _swipeBackground(),
      child: row,
    );
  }

  Widget _swipeBackground() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 22),
    decoration: BoxDecoration(
      color: K.rose.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(K.rTile),
    ),
    child: const Icon(Icons.delete_outline_rounded, color: K.rose),
  );

  // ───────────────────────── expenses ─────────────────────────

  Future<void> _showFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          void update(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter and sort', style: K.display(22)),
                const SizedBox(height: 18),
                Text('When', style: K.body(13, color: K.sage)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final f in _dateFilters)
                      PillChip(
                        label:
                            f == 'Pick a date' &&
                                _dateFilter == f &&
                                _specificDate != null
                            ? relativeDay(_specificDate!, now: _now)
                            : f,
                        icon: f == 'Pick a date'
                            ? Icons.calendar_today_rounded
                            : null,
                        selected: _dateFilter == f,
                        onTap: () async {
                          if (f == 'Pick a date') {
                            final picked = await pickDateIOS(
                              sheetContext,
                              initial: _specificDate ?? _now,
                              minimum: DateTime(2020),
                              maximum: DateTime(2100),
                              title: 'Show expenses on',
                            );
                            if (picked == null) return;
                            update(() {
                              _specificDate = picked;
                              _dateFilter = f;
                            });
                          } else {
                            update(() => _dateFilter = f);
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Order', style: K.body(13, color: K.sage)),
                const SizedBox(height: 10),
                Segmented(
                  options: const ['Newest first', 'Oldest first'],
                  value: _sortNewestFirst ? 'Newest first' : 'Oldest first',
                  onChanged: (v) =>
                      update(() => _sortNewestFirst = v == 'Newest first'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => update(() {
                          _dateFilter = 'All time';
                          _specificDate = null;
                          _sortNewestFirst = true;
                        }),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Show results'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchRow({
    required String hint,
    required ValueChanged<String> onChanged,
    VoidCallback? onFilter,
    bool filterActive = false,
  }) => Row(
    children: [
      Expanded(
        child: CupertinoSearchTextField(
          placeholder: hint,
          onChanged: onChanged,
          style: K.body(16, color: K.parchment),
          placeholderStyle: K.body(16, color: K.sage.withValues(alpha: .75)),
          backgroundColor: K.feltHigh,
          borderRadius: BorderRadius.circular(12),
          itemColor: K.sage,
          padding: const EdgeInsets.fromLTRB(6, 11, 8, 11),
        ),
      ),
      if (onFilter != null) ...[
        const SizedBox(width: 10),
        Pressable(
          onTap: onFilter,
          semanticLabel: 'Filter and sort',
          child: AnimatedContainer(
            duration: K.motion(context, 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: filterActive ? K.brass : K.feltHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: filterActive ? K.brassDeep : K.parchment,
            ),
          ),
        ),
      ],
    ],
  );

  Widget _expensesPage() {
    final list = _filteredExpenses;
    final total = list.fold(0.0, (s, e) => s + e.amount);
    final filtered =
        _dateFilter != 'All time' ||
        !_sortNewestFirst ||
        _expenseCategory != 'All';

    // Group by day.
    final groups = <DateTime, List<Expense>>{};
    for (final e in list) {
      groups.putIfAbsent(dayOnly(e.date), () => []).add(e);
    }

    return _page(
      title: 'Expenses',
      subtitle:
          '${list.length} ${list.length == 1 ? 'entry' : 'entries'} · ${rs(total, hidden: _hideAmounts)}',

      children: [
        _searchRow(
          hint: 'Search expenses',
          onChanged: (v) => setState(() => _expenseQuery = v),
          onFilter: _showFilters,
          filterActive: _dateFilter != 'All time' || !_sortNewestFirst,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              for (final c in ['All', ...K.categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PillChip(
                    label: c,
                    color: c == 'All' ? K.brass : K.categoryColor(c),
                    selected: _expenseCategory == c,
                    onTap: () => setState(() => _expenseCategory = c),
                  ),
                ),
            ],
          ),
        ),
        if (filtered) ...[
          const SizedBox(height: 10),
          Text(
            '$_dateFilterLabel · ${_sortNewestFirst ? 'Newest first' : 'Oldest first'}${_expenseCategory == 'All' ? '' : ' · $_expenseCategory'}',
            style: K.body(13, color: K.sage),
          ),
        ],
        const SizedBox(height: 18),
        if (list.isEmpty)
          EmptyNote(
            icon: _expenses.isEmpty
                ? Icons.receipt_long_rounded
                : Icons.search_off_rounded,
            title: _expenses.isEmpty ? 'No expenses yet' : 'Nothing matches',
            body: _expenses.isEmpty
                ? 'Log a purchase and it shows up here, grouped by day.'
                : 'Try another search, category or date.',
            action: _expenses.isEmpty ? 'Add expense' : null,
            onAction: () => _openExpense(),
          )
        else
          for (final day in groups.keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      relativeDay(day, now: _now),
                      style: K.body(14, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    rs(
                      groups[day]!.fold(0.0, (s, e) => s + e.amount),
                      hidden: _hideAmounts,
                    ),
                    style: K.body(13, color: K.sage),
                  ),
                ],
              ),
            ),
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              radius: K.rTile,
              child: Column(
                children: [
                  for (final e in groups[day]!) _expenseRow(e, showDate: false),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Tap an expense to edit it. Swipe left to delete.',
              textAlign: TextAlign.center,
              style: K.body(12, color: K.sage.withValues(alpha: .7)),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── people ─────────────────────────

  Widget _peoplePage() {
    final list = _filteredDebts;
    final open = list.where((e) => !e.settled).toList();
    final settled = list.where((e) => e.settled).toList();
    return _page(
      title: 'People',
      subtitle: 'Money lent and borrowed',
      children: [
        Row(
          children: [
            _miniStat('Owed to you', _received, K.mint),
            const SizedBox(width: 12),
            _miniStat('You owe', _owed, K.rose),
          ],
        ),
        const SizedBox(height: 18),
        _searchRow(
          hint: 'Search people or notes',
          onChanged: (v) => setState(() => _debtQuery = v),
        ),
        const SizedBox(height: 22),
        const SectionHeader('Open'),
        if (open.isEmpty)
          EmptyNote(
            icon: Icons.handshake_rounded,
            title: _debts.isEmpty ? 'No balances yet' : 'All square',
            body: _debts.isEmpty
                ? 'Lent someone money or borrowed some? Add it so neither of you forgets.'
                : 'Nobody owes anybody right now.',
            action: 'Add balance',
            onAction: _addDebt,
          )
        else
          for (final e in open) _debtTile(e),
        if (settled.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionHeader('Settled · ${settled.length}'),
          for (final e in settled) _debtTile(e),
        ],
      ],
    );
  }

  Widget _debtTile(MoneyEntry item) {
    final color = item.isOwedToMe ? K.mint : K.rose;
    final today = dayOnly(_now);
    final late =
        !item.settled &&
        item.dueDate != null &&
        dayOnly(item.dueDate!).isBefore(today);
    final sub = [
      item.isOwedToMe ? 'Owes you' : 'You owe',
      if (item.note.isNotEmpty && item.note != 'Personal balance') item.note,
      if (item.dueDate != null)
        late
            ? 'Late since ${shortDate(item.dueDate!)}'
            : 'Due ${relativeDay(item.dueDate!, now: _now)}',
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('debt-${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => _deleteDebt(item),
        background: _swipeBackground(),
        child: AnimatedOpacity(
          duration: K.motion(context, 300),
          opacity: item.settled ? .55 : 1,
          child: Panel(
            radius: K.rTile,
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    item.name.characters.first.toUpperCase(),
                    style: K.display(18, color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: K.body(15, weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: K.body(13, color: late ? K.rose : K.sage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hideAmounts
                          ? 'Rs ••••'
                          : '${item.isOwedToMe ? '+' : '−'}${rs(item.amount)}',
                      style: K.display(16, color: color),
                    ),
                    const SizedBox(height: 4),
                    if (item.settled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: K.sage,
                          ),
                          const SizedBox(width: 4),
                          Text('Settled', style: K.body(12, color: K.sage)),
                        ],
                      )
                    else
                      Pressable(
                        onTap: () => _settleDebt(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: K.feltHigh,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Text(
                            'Settle',
                            style: K.body(
                              13,
                              color: K.brass,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── plan ─────────────────────────

  Widget _planPage() => _page(
    title: 'Plan',
    subtitle: 'Budget, bills and settings',
    children: [
      _budgetCard(),
      const SizedBox(height: 28),
      SectionHeader(
        'Monthly bills',
        action: _bills.isEmpty ? null : 'Add bill',
        onAction: () => _openBill(),
      ),
      if (_bills.isEmpty)
        EmptyNote(
          icon: Icons.event_repeat_rounded,
          title: 'Add your regular bills',
          body: 'Rent, internet, electricity, subscriptions. Koin Flow sets the money aside and reminds you before each is due.',
          action: 'Add bill',
          onAction: () => _openBill(),
        )
      else
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              for (final b in List.of(
                _bills,
              )..sort((a, b) => a.dueDay.compareTo(b.dueDay)))
                _billRow(b),
            ],
          ),
        ),
      const SizedBox(height: 28),
      const SectionHeader('Settings'),
      Panel(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            _settingRow(Icons.person_rounded, 'Your name', _name, _editName),
            _settingRow(
              _hideAmounts
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              'Hide amounts',
              'Mask money on screen, handy in public',
              _toggleHidden,
              trailing: CupertinoSwitch(
                value: _hideAmounts,
                activeTrackColor: K.brass,
                onChanged: (_) => _toggleHidden(),
              ),
            ),
            _settingRow(
              Icons.payments_rounded,
              'Currency',
              'Pakistani rupee (PKR)',
              null,
            ),
            _settingRow(
              Icons.ios_share_rounded,
              'Back up your ledger',
              'Copy everything as text',
              _showExport,
            ),
            _settingRow(
              Icons.settings_backup_restore_rounded,
              'Restore a backup',
              'Paste a backup to bring data back',
              _showImport,
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Panel(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            _settingRow(
              Icons.delete_sweep_rounded,
              'Delete all expenses',
              null,
              _deleteAllExpenses,
              danger: true,
            ),
            _settingRow(
              Icons.group_remove_rounded,
              'Delete all balances',
              null,
              _deleteAllPeople,
              danger: true,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Center(
        child: Text(
          'Koin Flow 1.2 · Your data stays on this phone',
          style: K.body(12, color: K.sage.withValues(alpha: .7)),
        ),
      ),
    ],
  );

  Widget _budgetCard() {
    final h = _hideAmounts;
    final free = math.max(0.0, _left - _reserved);
    final parts = [
      ('Spent', _spent, K.brass),
      ('Lent out', _received, K.mint),
      ('Bills set aside', _reserved, const Color(0xFFF0A86B)),
      ('Free to spend', free, K.seam),
    ];
    final total = math.max(_budget, parts.fold(0.0, (s, p) => s + p.$2));
    final over = _left - _reserved < 0;
    return Pressable(
      onTap: _editBudget,
      scale: .985,
      semanticLabel: 'Monthly budget ${rs(_budget)}. Tap to change.',
      child: Panel(
        radius: K.rHero,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: K.body(14, color: K.sage),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: K.brass.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded, size: 14, color: K.brass),
                      const SizedBox(width: 5),
                      Text(
                        'Change',
                        style: K.body(
                          13,
                          color: K.brass,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CountUp(
              value: _budget,
              hidden: h,
              style: K.display(40, spacing: -1.2),
            ),
            Text(
              'About ${rs(_budget / daysInMonth(_now), hidden: h)} a day in ${monthLong(_now.month)}',
              style: K.body(13, color: K.sage),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: K.motion(context, 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => SizedBox(
                  height: 14,
                  child: Row(
                    children: [
                      for (final p in parts.take(3))
                        if (p.$2 > 0)
                          Expanded(
                            flex: math.max(
                              1,
                              (p.$2 / total * 1000 * t).round(),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(right: 2),
                              color: p.$3,
                            ),
                          ),
                      Expanded(
                        flex: math.max(
                          1,
                          (1000 -
                                  parts.take(3).fold(0.0, (s, p) => s + p.$2) /
                                      total *
                                      1000 *
                                      t)
                              .round(),
                        ),
                        child: const ColoredBox(color: K.seam),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final p in parts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.$3 == K.seam ? K.sage : p.$3,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.$1, style: K.body(14))),
                    Text(
                      rs(p.$2, hidden: h),
                      style: K.display(
                        15,
                        weight: FontWeight.w600,
                        color: p.$1 == 'Free to spend'
                            ? (over ? K.rose : K.mint)
                            : K.parchment,
                      ),
                    ),
                  ],
                ),
              ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Your bills and spending are more than this budget.',
                  style: K.body(13, color: K.rose),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(Bill b) {
    final paid = b.isPaidFor(_now);
    final days = b.daysUntilDue(_now);
    final when = paid
        ? 'Paid for ${monthLong(_now.month)}'
        : days < 0
        ? '${-days} day${days == -1 ? '' : 's'} late'
        : days == 0
        ? 'Due today'
        : 'Due ${ordinal(b.dueDay)} · in $days day${days == 1 ? '' : 's'}';
    return Pressable(
      onTap: () => _openBill(b),
      scale: .985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const CategoryBadge('Bills'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name, style: K.body(15, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: K.body(
                      13,
                      color: paid
                          ? K.mint
                          : days < 0
                          ? K.rose
                          : K.sage,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              rs(b.amount, hidden: _hideAmounts),
              style: K.display(16, weight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: paid ? 'Paid' : 'Mark ${b.name} paid',
              child: Pressable(
                onTap: paid ? null : () => _payBill(b),
                semanticLabel: paid ? 'Paid' : 'Mark ${b.name} paid',
                child: AnimatedContainer(
                  duration: K.motion(context, 260),
                  curve: Curves.easeOutBack,
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: paid ? K.mint : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: paid ? K.mint : K.seam, width: 2),
                  ),
                  child: AnimatedSwitcher(
                    duration: K.motion(context, 200),
                    transitionBuilder: (c, a) =>
                        ScaleTransition(scale: a, child: c),
                    child: paid
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('paid'),
                            size: 18,
                            color: K.ledger,
                          )
                        : const SizedBox.shrink(key: ValueKey('unpaid')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(
    IconData icon,
    String title,
    String? subtitle,
    VoidCallback? onTap, {
    Widget? trailing,
    bool danger = false,
  }) {
    final color = danger ? K.rose : K.parchment;
    return Pressable(
      onTap: onTap,
      scale: .985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: danger ? K.rose : K.brass),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: K.body(15, weight: FontWeight.w600, color: color),
                  ),
                  if (subtitle != null)
                    Text(subtitle, style: K.body(13, color: K.sage)),
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded, color: K.sage)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── chrome ─────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .94,
    semanticLabel: label,
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: K.brass,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: K.brass.withValues(alpha: .28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_rounded, color: K.brassDeep, size: 24),
          const SizedBox(width: 6),
          AnimatedSize(
            duration: K.motion(context, 240),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: K.motion(context, 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: K.body(16, weight: FontWeight.w700, color: K.brassDeep),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Native UITabBar on iPhone; a matching glass bar elsewhere (preview build).
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    TabItem('Overview', 'circle.grid.2x2.fill', Icons.donut_large_rounded),
    TabItem('Expenses', 'receipt.fill', Icons.receipt_long_rounded),
    TabItem('People', 'person.2.fill', Icons.people_alt_rounded),
    TabItem('Plan', 'calendar', Icons.event_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isApple =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (isApple) {
      return CNTabBar(
        currentIndex: index,
        onTap: onTap,
        tint: K.brass,
        items: [
          for (final i in _items)
            CNTabBarItem(label: i.label, icon: CNSymbol(i.symbol)),
        ],
      );
    }
    return GlassTabBar(items: _items, index: index, onTap: onTap);
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    super.key,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  Future<void> dismiss() => _c.reverse();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 150,
      child: FadeTransition(
        opacity: _c,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .6),
            end: Offset.zero,
          ).animate(curve),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                constraints: const BoxConstraints(minHeight: 52, maxWidth: 440),
                decoration: BoxDecoration(
                  color: K.parchment,
                  borderRadius: BorderRadius.circular(K.rInput),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: K.ledger, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: K.body(
                          14,
                          weight: FontWeight.w600,
                          color: K.ledger,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: widget.onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8A5F0F),
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    ] else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
