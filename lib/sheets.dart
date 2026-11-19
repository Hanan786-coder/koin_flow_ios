import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'ios.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Result from the expense sheet: either a saved expense or a delete request.
class ExpenseSheetResult {
  ExpenseSheetResult.saved(this.expense) : deleted = false;
  ExpenseSheetResult.deleted(this.expense) : deleted = true;
  final Expense expense;
  final bool deleted;
}

double? parseAmount(String text) {
  final v = double.tryParse(
    text.replaceAll(',', '').replaceAll('Rs', '').replaceAll('.', '.').trim(),
  );
  return (v == null || v <= 0) ? null : v;
}

/// Big, centered amount input — the first thing in every entry sheet.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.color,
    this.autofocus = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final Color color;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text(
        'Rs',
        style: K.display(24, color: K.sage, weight: FontWeight.w600),
      ),
      const SizedBox(width: 8),
      IntrinsicWidth(
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          textAlign: TextAlign.center,
          cursorColor: color,
          style: K.display(48, color: color, weight: FontWeight.w700),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: '0',
            hintStyle: K.display(48, color: K.seam),
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    ],
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: K.display(22))),
      ?trailing,
    ],
  );
}

class _Shake extends StatelessWidget {
  const _Shake({required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(trigger),
    tween: Tween(begin: trigger == 0 ? 1 : 0, end: 1),
    duration: K.motion(context, 420),
    builder: (context, t, c) => Transform.translate(
      offset: Offset(math.sin(t * math.pi * 6) * 9 * (1 - t), 0),
      child: c,
    ),
    child: child,
  );
}

class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key, this.initial});
  final Expense? initial;

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : groupDigits(
            widget.initial!.amount,
            decimals: widget.initial!.amount % 1 == 0 ? 0 : 2,
          ).replaceAll(',', ''),
  );
  late final _note = TextEditingController(text: widget.initial?.note ?? '');
  late String _category = widget.initial?.category ?? 'Food';
  late DateTime _date = widget.initial?.date ?? DateTime.now();
  int _shake = 0;
  String? _error;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickDateIOS(
      context,
      initial: _date,
      minimum: DateTime(2020),
      maximum: DateTime.now().add(const Duration(days: 365)),
      title: 'Expense date',
    );
    if (picked != null) {
      final now = DateTime.now();
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        ),
      );
    }
  }

  void _setDay(int daysAgo) {
    final now = DateTime.now().subtract(Duration(days: daysAgo));
    setState(() => _date = now);
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    final title = _title.text.trim();
    if (amount == null || title.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _shake++;
        _error = amount == null
            ? 'Enter an amount above zero.'
            : 'Add a short name, like "Groceries".';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    final expense =
        widget.initial?.copyWith(
          title: title,
          amount: amount,
          category: _category,
          date: _date,
          note: _note.text.trim(),
        ) ??
        Expense(
          title: title,
          amount: amount,
          category: _category,
          date: _date,
          note: _note.text.trim(),
        );
    Navigator.pop(context, ExpenseSheetResult.saved(expense));
  }

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final d = dayOnly(_date);
    final isToday = d == today;
    final isYesterday = d == today.subtract(const Duration(days: 1));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              _editing ? 'Edit expense' : 'New expense',
              trailing: _editing
                  ? IconButton(
                      tooltip: 'Delete expense',
                      onPressed: () => Navigator.pop(
                        context,
                        ExpenseSheetResult.deleted(widget.initial!),
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: K.rose,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            _Shake(
              trigger: _shake,
              child: _AmountField(
                controller: _amount,
                color: K.parchment,
                autofocus: !_editing,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            AnimatedSize(
              duration: K.motion(context, 200),
              child: _error == null
                  ? const SizedBox(height: 18)
                  : Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Center(
                        child: Text(_error!, style: K.body(13, color: K.rose)),
                      ),
                    ),
            ),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                hintText: 'What was it for?',
                prefixIcon: Icon(Icons.edit_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 18),
            Text('Category', style: K.body(13, color: K.sage)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in K.categories)
                  PillChip(
                    label: c,
                    icon: K.categoryIcon(c),
                    color: K.categoryColor(c),
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Date', style: K.body(13, color: K.sage)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillChip(
                  label: 'Today',
                  selected: isToday,
                  onTap: () => _setDay(0),
                ),
                PillChip(
                  label: 'Yesterday',
                  selected: isYesterday,
                  onTap: () => _setDay(1),
                ),
                PillChip(
                  label: isToday || isYesterday
                      ? 'Pick a date'
                      : relativeDay(_date),
                  icon: Icons.calendar_today_rounded,
                  selected: !isToday && !isYesterday,
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _submit,
              child: Text(_editing ? 'Save changes' : 'Add expense'),
            ),
          ],
        ),
      ),
    );
  }
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
  int _shake = 0;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final picked = await pickDateIOS(
      context,
      initial: _dueDate ?? DateTime.now().add(const Duration(days: 14)),
      minimum: DateTime.now().subtract(const Duration(days: 365)),
      maximum: DateTime.now().add(const Duration(days: 3650)),
      title: 'Due date',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    if (_name.text.trim().isEmpty || amount == null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _shake++;
        _error = amount == null
            ? 'Enter an amount above zero.'
            : 'Add the person\'s name.';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      MoneyEntry(
        id: newId(),
        name: _name.text.trim(),
        amount: amount,
        note: _note.text.trim().isEmpty
            ? 'Personal balance'
            : _note.text.trim(),
        isOwedToMe: _isOwedToMe,
        dueDate: _dueDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _isOwedToMe ? K.mint : K.rose;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetTitle('New balance'),
            const SizedBox(height: 16),
            Segmented(
              options: const ['They owe me', 'I owe them'],
              value: _isOwedToMe ? 'They owe me' : 'I owe them',
              onChanged: (v) =>
                  setState(() => _isOwedToMe = v == 'They owe me'),
            ),
            const SizedBox(height: 18),
            _Shake(
              trigger: _shake,
              child: _AmountField(
                controller: _amount,
                color: color,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            AnimatedSize(
              duration: K.motion(context, 200),
              child: _error == null
                  ? const SizedBox(height: 18)
                  : Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 10),
                      child: Center(
                        child: Text(_error!, style: K.body(13, color: K.rose)),
                      ),
                    ),
            ),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _error = null),
              decoration: const InputDecoration(
                hintText: 'Person\'s name',
                prefixIcon: Icon(Icons.person_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What is it for? (optional)',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillChip(
                  label: 'No due date',
                  selected: _dueDate == null,
                  onTap: () => setState(() => _dueDate = null),
                ),
                PillChip(
                  label: _dueDate == null
                      ? 'Set due date'
                      : 'Due ${relativeDay(_dueDate!)}',
                  icon: Icons.event_rounded,
                  selected: _dueDate != null,
                  onTap: _chooseDate,
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: _submit, child: const Text('Add balance')),
          ],
        ),
      ),
    );
  }
}

class BillSheetResult {
  BillSheetResult.saved(this.bill) : deleted = false;
  BillSheetResult.deleted(this.bill) : deleted = true;
  final Bill bill;
  final bool deleted;
}

class AddBillSheet extends StatefulWidget {
  const AddBillSheet({super.key, this.initial});
  final Bill? initial;

  @override
  State<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends State<AddBillSheet> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.amount.toStringAsFixed(0),
  );
  late int _dueDay = widget.initial?.dueDay ?? DateTime.now().day.clamp(1, 28);
  int _shake = 0;
  String? _error;

  bool get _editing => widget.initial != null;

  static const _suggestions = [
    'Electricity',
    'Internet',
    'Mobile',
    'Rent',
    'Gas',
    'Netflix',
    'Gym',
  ];

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    final name = _name.text.trim();
    if (amount == null || name.isEmpty) {
      HapticFeedback.heavyImpact();
      setState(() {
        _shake++;
        _error = amount == null
            ? 'Enter an amount above zero.'
            : 'Name the bill, like "Internet".';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    final bill =
        widget.initial?.copyWith(name: name, amount: amount, dueDay: _dueDay) ??
        Bill(name: name, amount: amount, dueDay: _dueDay);
    Navigator.pop(context, BillSheetResult.saved(bill));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetTitle(
            _editing ? 'Edit bill' : 'New monthly bill',
            trailing: _editing
                ? IconButton(
                    tooltip: 'Delete bill',
                    onPressed: () => Navigator.pop(
                      context,
                      BillSheetResult.deleted(widget.initial!),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: K.rose,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            'Unpaid bills are set aside from what you can spend each day.',
            style: K.body(14, color: K.sage, height: 1.4),
          ),
          const SizedBox(height: 18),
          _Shake(
            trigger: _shake,
            child: _AmountField(
              controller: _amount,
              color: K.brass,
              autofocus: !_editing,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          AnimatedSize(
            duration: K.motion(context, 200),
            child: _error == null
                ? const SizedBox(height: 18)
                : Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 10),
                    child: Center(
                      child: Text(_error!, style: K.body(13, color: K.rose)),
                    ),
                  ),
          ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(
              hintText: 'Bill name',
              prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
            ),
          ),
          if (!_editing) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in _suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PillChip(
                        label: s,
                        selected: _name.text == s,
                        onTap: () => setState(() {
                          _name.text = s;
                          _error = null;
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due every month on the',
                  style: K.body(15, color: K.sage),
                ),
              ),
              Text(ordinal(_dueDay), style: K.display(20, color: K.brass)),
            ],
          ),
          Slider(
            value: _dueDay.toDouble(),
            min: 1,
            max: 28,
            divisions: 27,
            label: ordinal(_dueDay),
            onChanged: (v) {
              if (v.round() != _dueDay) HapticFeedback.selectionClick();
              setState(() => _dueDay = v.round());
            },
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: Text(_editing ? 'Save changes' : 'Add bill'),
          ),
        ],
      ),
    ),
  );
}

/// Set the monthly budget by typing it, or tap a quick amount.
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key, required this.current, required this.spent});
  final double current;
  final double spent;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  late final _amount = TextEditingController(
    text: widget.current.toStringAsFixed(0),
  );
  int _shake = 0;
  String? _error;

  static const _quick = [50000.0, 100000.0, 150000.0, 200000.0, 300000.0];

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final v = parseAmount(_amount.text);
    if (v == null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _shake++;
        _error = 'Enter a budget above zero.';
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final typed = parseAmount(_amount.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetTitle('Monthly budget'),
            const SizedBox(height: 6),
            Text(
              'How much do you want to spend in a month, including bills?',
              style: K.body(14, color: K.sage, height: 1.4),
            ),
            const SizedBox(height: 22),
            _Shake(
              trigger: _shake,
              child: _AmountField(
                controller: _amount,
                color: K.brass,
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            AnimatedSize(
              duration: K.motion(context, 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: Center(
                  child: Text(
                    _error ??
                        (typed == null
                            ? ' '
                            : 'About ${rs(typed / 30)} a day · ${rs(widget.spent)} spent so far'),
                    style: K.body(13, color: _error == null ? K.sage : K.rose),
                  ),
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final q in _quick)
                  PillChip(
                    label: 'Rs ${groupDigits(q / 1000)}k',
                    selected: typed == q,
                    onTap: () => setState(() {
                      _amount.text = q.toStringAsFixed(0);
                      _amount.selection = TextSelection.collapsed(
                        offset: _amount.text.length,
                      );
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _submit, child: const Text('Set budget')),
          ],
        ),
      ),
    );
  }
}
