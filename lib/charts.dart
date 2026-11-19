import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'ios.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

enum InsightView { spending, pace, calendar, categories }

extension on InsightView {
  String get label => switch (this) {
    InsightView.spending => 'Spending',
    InsightView.pace => 'Pace',
    InsightView.calendar => 'Calendar',
    InsightView.categories => 'Categories',
  };
}

class _Pills extends StatelessWidget {
  const _Pills({
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in options)
        PillChip(label: o, selected: o == value, onTap: () => onChanged(o)),
    ],
  );
}

double _sum(Iterable<Expense> list) => list.fold(0, (s, e) => s + e.amount);
bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// One card, four ways to look at your money.
class InsightsCard extends StatefulWidget {
  const InsightsCard({
    super.key,
    required this.expenses,
    required this.now,
    required this.budget,
    required this.hidden,
  });

  final List<Expense> expenses;
  final DateTime now;
  final double budget;
  final bool hidden;

  @override
  State<InsightsCard> createState() => _InsightsCardState();
}

class _InsightsCardState extends State<InsightsCard> {
  InsightView _view = InsightView.spending;

  @override
  Widget build(BuildContext context) {
    final child = switch (_view) {
      InsightView.spending => _SpendingView(
        expenses: widget.expenses,
        now: widget.now,
        hidden: widget.hidden,
      ),
      InsightView.pace => _PaceView(
        expenses: widget.expenses,
        now: widget.now,
        budget: widget.budget,
        hidden: widget.hidden,
      ),
      InsightView.calendar => _CalendarView(
        expenses: widget.expenses,
        now: widget.now,
        hidden: widget.hidden,
      ),
      InsightView.categories => _CategoryView(
        expenses: widget.expenses,
        now: widget.now,
        hidden: widget.hidden,
      ),
    };
    return Panel(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text('Insights', style: K.display(20, spacing: -0.3)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Segmented(
              options: [for (final v in InsightView.values) v.label],
              value: _view.label,
              onChanged: (label) => setState(
                () => _view = InsightView.values.firstWhere(
                  (v) => v.label == label,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AnimatedSize(
              duration: K.motion(context, 320),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: K.motion(context, 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, .03),
                      end: Offset.zero,
                    ).animate(a),
                    child: c,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(key: ValueKey(_view), child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title + prev/next row used by every view.
class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({
    required this.title,
    required this.subtitle,
    required this.onPrev,
    required this.onNext,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  Widget _btn(IconData icon, String tip, VoidCallback? onTap) => IconButton(
    tooltip: tip,
    onPressed: onTap == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            onTap();
          },
    icon: Icon(icon, size: 22),
    color: K.parchment,
    disabledColor: K.seam,
    visualDensity: VisualDensity.compact,
    style: IconButton.styleFrom(
      backgroundColor: K.feltHigh,
      disabledBackgroundColor: K.feltHigh.withValues(alpha: .5),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: K.motion(context, 200),
              child: Text(
                title,
                key: ValueKey(title),
                style: K.body(16, weight: FontWeight.w700),
              ),
            ),
            AnimatedSwitcher(
              duration: K.motion(context, 200),
              child: Text(
                subtitle,
                key: ValueKey(subtitle),
                style: K.body(13, color: K.sage),
              ),
            ),
          ],
        ),
      ),
      _btn(Icons.chevron_left_rounded, 'Previous', onPrev),
      const SizedBox(width: 6),
      _btn(Icons.chevron_right_rounded, 'Next', onNext),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: K.body(12, color: K.sage)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: K.display(16)),
        ),
      ],
    ),
  );
}

// ───────────────────────── Spending (bars) ─────────────────────────

class _SpendingView extends StatefulWidget {
  const _SpendingView({
    required this.expenses,
    required this.now,
    required this.hidden,
  });
  final List<Expense> expenses;
  final DateTime now;
  final bool hidden;

  @override
  State<_SpendingView> createState() => _SpendingViewState();
}

class _SpendingViewState extends State<_SpendingView> {
  String _range = 'Week';
  int _offset = 0;
  String _category = 'All categories';

  Iterable<Expense> get _pool => _category == 'All categories'
      ? widget.expenses
      : widget.expenses.where((e) => e.category == _category);

  ({
    List<double> values,
    List<String> labels,
    int? highlight,
    String title,
    String unit,
  })
  _data() {
    final now = widget.now;
    final today = dayOnly(now);
    final pool = _pool.toList();
    if (_range == 'Year') {
      final year = now.year + _offset;
      return (
        values: [
          for (var m = 1; m <= 12; m++)
            _sum(pool.where((e) => e.date.year == year && e.date.month == m)),
        ],
        labels: [for (var m = 1; m <= 12; m++) monthShort(m)],
        highlight: _offset == 0 ? now.month - 1 : null,
        title: '$year',
        unit: 'month',
      );
    }
    if (_range == 'Month') {
      final month = DateTime(now.year, now.month + _offset);
      final days = daysInMonth(month);
      final weeks = (days / 7).ceil();
      return (
        values: [
          for (var w = 0; w < weeks; w++)
            _sum(
              pool.where(
                (e) =>
                    _sameMonth(e.date, month) &&
                    e.date.day > w * 7 &&
                    e.date.day <= math.min(days, (w + 1) * 7),
              ),
            ),
        ],
        labels: [
          for (var w = 0; w < weeks; w++)
            '${w * 7 + 1}–${math.min(days, (w + 1) * 7)}',
        ],
        highlight: _offset == 0 ? (now.day - 1) ~/ 7 : null,
        title: '${monthLong(month.month)} ${month.year}',
        unit: 'week',
      );
    }
    final weekStart = today
        .subtract(Duration(days: today.weekday - 1))
        .add(Duration(days: 7 * _offset));
    return (
      values: [
        for (var i = 0; i < 7; i++)
          _sum(
            pool.where(
              (e) => dayOnly(e.date) == weekStart.add(Duration(days: i)),
            ),
          ),
      ],
      labels: [
        for (var i = 0; i < 7; i++)
          weekdayShort(weekStart.add(Duration(days: i))),
      ],
      highlight: _offset == 0 ? today.weekday - 1 : null,
      title: _offset == 0
          ? 'This week'
          : _offset == -1
          ? 'Last week'
          : 'Week of ${shortDate(weekStart)}',
      unit: 'day',
    );
  }

  Future<void> _pickCategory() async {
    final picked = await showIOSChoice(
      context,
      title: 'Show spending for',
      options: ['All categories', ...K.categories],
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  @override
  Widget build(BuildContext context) {
    final d = _data();
    final total = d.values.fold(0.0, (s, v) => s + v);
    // Average over periods that have started.
    final elapsed = d.highlight == null ? d.values.length : d.highlight! + 1;
    final avg = elapsed == 0 ? 0.0 : total / elapsed;
    var top = 0;
    for (var i = 1; i < d.values.length; i++) {
      if (d.values[i] > d.values[top]) top = i;
    }
    final h = widget.hidden;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Pills(
          options: const ['Week', 'Month', 'Year'],
          value: _range,
          onChanged: (v) => setState(() {
            _range = v;
            _offset = 0;
          }),
        ),
        const SizedBox(height: 16),
        _PeriodHeader(
          title: d.title,
          subtitle: _category,
          onPrev: () => setState(() => _offset--),
          onNext: _offset >= 0 ? null : () => setState(() => _offset++),
        ),
        const SizedBox(height: 6),
        SpendBars(
          key: ValueKey('$_range$_offset$_category'),
          values: d.values,
          labels: d.labels,
          highlight: d.highlight,
          hidden: h,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _Stat('Total', rs(total, hidden: h)),
            _Stat('Avg per ${d.unit}', rs(avg, hidden: h)),
            _Stat(
              'Highest',
              total == 0
                  ? '—'
                  : '${d.labels[top]} · ${rs(d.values[top], hidden: h)}',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Pressable(
          onTap: _pickCategory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: K.feltHigh,
              borderRadius: BorderRadius.circular(K.rInput),
            ),
            child: Row(
              children: [
                Icon(
                  _category == 'All categories'
                      ? Icons.filter_list_rounded
                      : K.categoryIcon(_category),
                  size: 18,
                  color: _category == 'All categories'
                      ? K.sage
                      : K.categoryColor(_category),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _category == 'All categories'
                        ? 'Filter by category'
                        : 'Showing $_category only',
                    style: K.body(14, weight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.unfold_more_rounded, size: 18, color: K.sage),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Pace (cumulative line) ─────────────────────────

class _PaceView extends StatefulWidget {
  const _PaceView({
    required this.expenses,
    required this.now,
    required this.budget,
    required this.hidden,
  });
  final List<Expense> expenses;
  final DateTime now;
  final double budget;
  final bool hidden;

  @override
  State<_PaceView> createState() => _PaceViewState();
}

class _PaceViewState extends State<_PaceView> {
  int _offset = 0;

  List<double> _cumulative(DateTime month, int upToDay) {
    final days = daysInMonth(month);
    final daily = List<double>.filled(days, 0);
    for (final e in widget.expenses) {
      if (_sameMonth(e.date, month)) daily[e.date.day - 1] += e.amount;
    }
    final out = <double>[];
    var run = 0.0;
    for (var i = 0; i < math.min(upToDay, days); i++) {
      run += daily[i];
      out.add(run);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final month = DateTime(now.year, now.month + _offset);
    final prev = DateTime(month.year, month.month - 1);
    final days = daysInMonth(month);
    final current = _offset == 0;
    final upTo = current ? now.day : days;
    final thisLine = _cumulative(month, upTo);
    final lastLine = _cumulative(prev, daysInMonth(prev));
    final spent = thisLine.isEmpty ? 0.0 : thisLine.last;
    final paceNow = widget.budget * upTo / days;
    final gap = paceNow - spent;
    final h = widget.hidden;
    final lastSame = lastLine.isEmpty
        ? 0.0
        : lastLine[math.min(upTo, lastLine.length) - 1];

    final String verdict;
    final Color color;
    if (spent == 0) {
      verdict = 'Nothing spent yet.';
      color = K.sage;
    } else if (gap >= 0) {
      verdict = current
          ? '${rs(gap, hidden: h)} under budget pace — nice.'
          : 'Finished ${rs(widget.budget - spent, hidden: h)} under budget.';
      color = K.mint;
    } else {
      verdict = current
          ? '${rs(-gap, hidden: h)} ahead of budget pace. Ease off a little.'
          : 'Finished ${rs(spent - widget.budget, hidden: h)} over budget.';
      color = K.rose;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeriodHeader(
          title: '${monthLong(month.month)} ${month.year}',
          subtitle: 'Running total vs your budget',
          onPrev: () => setState(() => _offset--),
          onNext: _offset >= 0 ? null : () => setState(() => _offset++),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 190,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_offset),
            tween: Tween(begin: 0, end: 1),
            duration: K.motion(context, 1100),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => CustomPaint(
              size: Size.infinite,
              painter: _PacePainter(
                days: days,
                budget: widget.budget,
                current: thisLine,
                previous: lastLine,
                progress: t,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 ${monthShort(month.month)}',
              style: K.body(11, color: K.sage),
            ),
            Text(
              '$days ${monthShort(month.month)}',
              style: K.body(11, color: K.sage),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _legend(K.brass, monthShort(month.month), solid: true),
            _legend(K.sage, monthShort(prev.month)),
            _legend(
              K.parchment.withValues(alpha: .5),
              'Budget pace',
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Stat('Spent so far', rs(spent, hidden: h)),
            _Stat('Budget pace', rs(paceNow, hidden: h)),
            _Stat(
              '${monthShort(prev.month)} by day $upTo',
              rs(lastSame, hidden: h),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          verdict,
          style: K.body(14, color: color, weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _legend(
    Color c,
    String label, {
    bool solid = false,
    bool dashed = false,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 18,
        height: 4,
        child: dashed
            ? Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 4,
                      height: 2,
                      margin: const EdgeInsets.only(right: 3),
                      color: c,
                    ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: solid ? c : c.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
      ),
      const SizedBox(width: 6),
      Text(label, style: K.body(12, color: K.sage)),
    ],
  );
}

class _PacePainter extends CustomPainter {
  _PacePainter({
    required this.days,
    required this.budget,
    required this.current,
    required this.previous,
    required this.progress,
  });

  final int days;
  final double budget;
  final List<double> current;
  final List<double> previous;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = [
      budget,
      if (current.isNotEmpty) current.last,
      if (previous.isNotEmpty) previous.last,
    ].reduce(math.max);
    final ceiling = maxV <= 0 ? 1.0 : maxV * 1.08;
    Offset pt(int dayIndex, double v, int span) => Offset(
      size.width * dayIndex / math.max(1, span - 1),
      size.height - (v / ceiling) * size.height,
    );

    // Grid.
    final grid = Paint()
      ..color = K.seam.withValues(alpha: .6)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Budget pace — dashed diagonal, plus the budget ceiling line.
    final dash = Paint()
      ..color = K.parchment.withValues(alpha: .45)
      ..strokeWidth = 1.5;
    final a = pt(0, 0, days);
    final b = pt(days - 1, budget, days);
    const seg = 6.0;
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (var d = 0.0; d < len * progress; d += seg * 2) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + seg, len), dash);
    }
    final by = pt(0, budget, days).dy;
    for (var x = 0.0; x < size.width; x += seg * 2) {
      canvas.drawLine(
        Offset(x, by),
        Offset(math.min(x + seg, size.width), by),
        dash..color = K.parchment.withValues(alpha: .18),
      );
    }

    Path line(List<double> v, int span) {
      final p = Path();
      final n = math.max(1, (v.length * progress).ceil());
      for (var i = 0; i < math.min(n, v.length); i++) {
        final o = pt(i, v[i], span);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      return p;
    }

    // Last month.
    if (previous.isNotEmpty) {
      canvas.drawPath(
        line(previous, previous.length),
        Paint()
          ..color = K.sage.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // This month, with a soft area.
    if (current.isNotEmpty) {
      final path = line(current, days);
      final n = math.min(
        current.length,
        math.max(1, (current.length * progress).ceil()),
      );
      final end = pt(n - 1, current[n - 1], days);
      final area = Path.from(path)
        ..lineTo(end.dx, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              K.brass.withValues(alpha: .28),
              K.brass.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = K.brass
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawCircle(end, 6, Paint()..color = K.ledger);
      canvas.drawCircle(end, 4.5, Paint()..color = K.brass);
    }
  }

  @override
  bool shouldRepaint(covariant _PacePainter old) =>
      old.progress != progress ||
      old.current != current ||
      old.previous != previous ||
      old.budget != budget;
}

// ───────────────────────── Calendar heatmap ─────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView({
    required this.expenses,
    required this.now,
    required this.hidden,
  });
  final List<Expense> expenses;
  final DateTime now;
  final bool hidden;

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  int _offset = 0;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final now = widget.now;
    final month = DateTime(now.year, now.month + _offset);
    final days = daysInMonth(month);
    final lead = DateTime(month.year, month.month, 1).weekday - 1;
    final totals = List<double>.filled(days, 0);
    final byDay = List.generate(days, (_) => <Expense>[]);
    for (final e in widget.expenses) {
      if (_sameMonth(e.date, month)) {
        totals[e.date.day - 1] += e.amount;
        byDay[e.date.day - 1].add(e);
      }
    }
    final maxV = totals.fold<double>(0, math.max);
    final spendDays = totals.where((v) => v > 0).length;
    final today = _offset == 0 ? now.day : null;
    final sel = _selected ?? today;
    final h = widget.hidden;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PeriodHeader(
          title: '${monthLong(month.month)} ${month.year}',
          subtitle: '$spendDays spending day${spendDays == 1 ? '' : 's'}',
          onPrev: () => setState(() {
            _offset--;
            _selected = null;
          }),
          onNext: _offset >= 0
              ? null
              : () => setState(() {
                  _offset++;
                  _selected = null;
                }),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: K.body(11, color: K.sage, weight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              _cell(
                d,
                totals[d - 1],
                maxV,
                isToday: d == today,
                isFuture: today != null && d > today,
                selected: d == sel,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Less', style: K.body(11, color: K.sage)),
            const SizedBox(width: 6),
            for (final a in const [.0, .25, .5, .75, 1.0])
              Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: a == 0
                      ? K.feltHigh
                      : K.brass.withValues(alpha: .18 + a * .82),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            const SizedBox(width: 3),
            Text('More', style: K.body(11, color: K.sage)),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: K.motion(context, 200),
          child: sel == null
              ? Text(
                  'Tap a day to see what you spent.',
                  key: const ValueKey('hint'),
                  style: K.body(13, color: K.sage),
                )
              : _dayDetail(
                  DateTime(month.year, month.month, sel),
                  byDay[sel - 1],
                  h,
                ),
        ),
      ],
    );
  }

  Widget _cell(
    int day,
    double v,
    double maxV, {
    required bool isToday,
    required bool isFuture,
    required bool selected,
  }) {
    final intensity = maxV == 0 ? 0.0 : math.sqrt(v / maxV);
    final bg = v == 0
        ? K.feltHigh
        : K.brass.withValues(alpha: .18 + intensity * .82);
    final fg = intensity > .55 ? K.brassDeep : K.parchment;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = day);
      },
      child: AnimatedContainer(
        duration: K.motion(context, 200),
        decoration: BoxDecoration(
          color: isFuture ? K.feltHigh.withValues(alpha: .4) : bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? K.parchment
                : isToday
                ? K.brass
                : Colors.transparent,
            width: selected ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: K.body(
            12,
            weight: FontWeight.w600,
            color: isFuture ? K.sage.withValues(alpha: .5) : fg,
          ),
        ),
      ),
    );
  }

  Widget _dayDetail(DateTime day, List<Expense> list, bool h) {
    final total = _sum(list);
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return Container(
      key: ValueKey(day),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: K.feltHigh,
        borderRadius: BorderRadius.circular(K.rInput),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${weekdayShort(day)}, ${shortDate(day)}',
                  style: K.body(14, weight: FontWeight.w700),
                ),
              ),
              Text(
                rs(total, hidden: h),
                style: K.display(16, color: K.brass),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (list.isEmpty)
            Text('No spending. A good day.', style: K.body(13, color: K.mint))
          else
            for (final e in list.take(3))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      K.categoryIcon(e.category),
                      size: 15,
                      color: K.categoryColor(e.category),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.title,
                        style: K.body(13, color: K.sage),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      rs(e.amount, hidden: h),
                      style: K.body(13, color: K.sage),
                    ),
                  ],
                ),
              ),
          if (list.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${list.length - 3} more',
                style: K.body(12, color: K.sage.withValues(alpha: .7)),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Categories (donut) ─────────────────────────

class _CategoryView extends StatefulWidget {
  const _CategoryView({
    required this.expenses,
    required this.now,
    required this.hidden,
  });
  final List<Expense> expenses;
  final DateTime now;
  final bool hidden;

  @override
  State<_CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<_CategoryView> {
  String _period = 'This month';
  String? _selected;

  ({
    bool Function(DateTime) current,
    bool Function(DateTime) previous,
    String compare,
  })
  get _ranges {
    final now = widget.now;
    final lastMonth = DateTime(now.year, now.month - 1);
    final twoBack = DateTime(now.year, now.month - 2);
    return switch (_period) {
      'Last month' => (
        current: (d) => _sameMonth(d, lastMonth),
        previous: (d) => _sameMonth(d, twoBack),
        compare: 'vs ${monthShort(twoBack.month)}',
      ),
      'This year' => (
        current: (d) => d.year == now.year,
        previous: (d) => d.year == now.year - 1,
        compare: 'vs ${now.year - 1}',
      ),
      _ => (
        current: (d) => _sameMonth(d, now),
        previous: (d) => _sameMonth(d, lastMonth),
        compare: 'vs ${monthShort(lastMonth.month)}',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = _ranges;
    Map<String, double> totals(bool Function(DateTime) test) {
      final m = <String, double>{};
      for (final e in widget.expenses.where((e) => test(e.date))) {
        final c = K.categories.contains(e.category) ? e.category : 'Other';
        m[c] = (m[c] ?? 0) + e.amount;
      }
      return m;
    }

    final now = totals(r.current);
    final before = totals(r.previous);
    final total = now.values.fold(0.0, (s, v) => s + v);
    final sorted = now.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final h = widget.hidden;
    final sel = _selected != null && now.containsKey(_selected)
        ? _selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) {
            final now = widget.now;
            final labels = {
              'This month': monthLong(now.month),
              'Last month': monthLong(DateTime(now.year, now.month - 1).month),
              'This year': '${now.year}',
            };
            return _Pills(
              options: labels.values.toList(),
              value: labels[_period]!,
              onChanged: (v) => setState(() {
                _period = labels.entries.firstWhere((e) => e.value == v).key;
                _selected = null;
              }),
            );
          },
        ),
        const SizedBox(height: 20),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'Nothing spent in this period.',
                style: K.body(14, color: K.sage),
              ),
            ),
          )
        else ...[
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(_period),
                tween: Tween(begin: 0, end: 1),
                duration: K.motion(context, 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  painter: _DonutPainter(
                    slices: [
                      for (final e in sorted)
                        (K.categoryColor(e.key), e.value / total, e.key == sel),
                    ],
                    progress: t,
                    dimOthers: sel != null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: K.motion(context, 200),
                      child: Column(
                        key: ValueKey(sel),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sel ?? 'Total',
                            style: K.body(13, color: K.sage),
                          ),
                          Text(
                            rs(sel == null ? total : now[sel]!, hidden: h),
                            style: K.display(24, spacing: -0.6),
                          ),
                          if (sel != null)
                            Text(
                              '${(now[sel]! / total * 100).round()}% of spending',
                              style: K.body(12, color: K.sage),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (final e in sorted)
            _row(
              e.key,
              e.value,
              total,
              before[e.key] ?? 0,
              r.compare,
              e.key == sel,
              h,
            ),
        ],
      ],
    );
  }

  Widget _row(
    String cat,
    double v,
    double total,
    double prev,
    String compare,
    bool selected,
    bool h,
  ) {
    final String delta;
    final Color dc;
    if (prev == 0) {
      delta = 'New';
      dc = K.sage;
    } else {
      final pct = ((v - prev) / prev * 100).round();
      delta = pct == 0 ? 'Same' : '${pct > 0 ? '↑' : '↓'} ${pct.abs()}%';
      dc = pct > 0 ? K.rose : (pct < 0 ? K.mint : K.sage);
    }
    return Pressable(
      onTap: () => setState(() => _selected = selected ? null : cat),
      scale: .98,
      child: AnimatedContainer(
        duration: K.motion(context, 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? K.feltHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CategoryBadge(cat, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat, style: K.body(14, weight: FontWeight.w600)),
                  Text(
                    '${(v / total * 100).round()}%  ·  $delta $compare',
                    style: K.body(12, color: dc),
                  ),
                ],
              ),
            ),
            Text(
              rs(v, hidden: h),
              style: K.display(15, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.progress,
    required this.dimOthers,
  });

  final List<(Color, double, bool)> slices;
  final double progress;
  final bool dimOthers;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - stroke / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = K.feltHigh
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    const gap = .035;
    var start = -math.pi / 2;
    final total = math.pi * 2 * progress;
    for (final (color, frac, selected) in slices) {
      final sweep = total * frac;
      if (sweep > gap) {
        canvas.drawArc(
          selected ? rect.inflate(4) : rect,
          start + gap / 2,
          sweep - gap,
          false,
          Paint()
            ..color = dimOthers && !selected
                ? color.withValues(alpha: .3)
                : color
            ..style = PaintingStyle.stroke
            ..strokeWidth = selected ? stroke + 6 : stroke
            ..strokeCap = StrokeCap.butt,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress ||
      old.dimOthers != dimOthers ||
      old.slices != slices;
}
