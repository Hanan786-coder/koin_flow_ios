import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'logo.dart';
import 'theme.dart';

/// Animates a number from its previous value to [value].
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.style,
    this.hidden = false,
    this.prefix = 'Rs ',
    this.duration = 900,
  });

  final double value;
  final TextStyle style;
  final bool hidden;
  final String prefix;
  final int duration;

  @override
  Widget build(BuildContext context) {
    if (hidden) return Text('$prefix••••', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: K.motion(context, duration),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${groupDigits(v)}', style: style, maxLines: 1),
    );
  }
}

/// Scales down slightly while pressed, with a light haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = .97,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: widget.onTap != null,
    label: widget.semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onLongPress: widget.onLongPress,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: K.motion(context, 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    ),
  );
}

/// Flat surface used for every card. Radius encodes hierarchy.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = K.rCard,
    this.color = K.felt,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: K.display(19, spacing: -0.3))),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                action!,
                style: K.body(14, color: K.brass, weight: FontWeight.w700),
              ),
            ),
          ),
      ],
    ),
  );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: K.brass.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: K.brass, size: 24),
        ),
        const SizedBox(height: 12),
        Text(title, style: K.display(17), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          body,
          style: K.body(14, color: K.sage, height: 1.4),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: 14),
          Pressable(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: K.feltHigh,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                action!,
                style: K.body(14, color: K.brass, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge(this.category, {super.key, this.size = 44});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = K.categoryColor(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(size * .34),
      ),
      child: Icon(K.categoryIcon(category), color: c, size: size * .46),
    );
  }
}

/// Pill chip with animated selection.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = K.brass,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    child: AnimatedContainer(
      duration: K.motion(context, 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: .18) : K.feltHigh,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: selected ? color.withValues(alpha: .7) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: selected ? color : K.sage),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: K.body(
              14,
              weight: FontWeight.w600,
              color: selected ? color : K.sage,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The hero: a brass ring showing how much of the month's budget is used.
class BudgetRing extends StatelessWidget {
  const BudgetRing({
    super.key,
    required this.spentRatio,
    required this.reservedRatio,
    required this.monthRatio,
    required this.child,
    this.size = 248,
  });

  /// 0..1+ portion of budget already spent.
  final double spentRatio;

  /// Portion reserved for unpaid bills (drawn after spent).
  final double reservedRatio;

  /// How far through the month we are, drawn as a tick on the ring.
  final double monthRatio;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: K.motion(context, 1300),
    curve: Curves.easeOutQuart,
    builder: (context, t, inner) => SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          spent: (spentRatio * t).clamp(0, 1),
          reserved: (reservedRatio * t).clamp(0, 1),
          tick: monthRatio,
          over: spentRatio > 1,
          tickOpacity: t,
        ),
        child: Center(child: inner),
      ),
    ),
    child: child,
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.spent,
    required this.reserved,
    required this.tick,
    required this.over,
    required this.tickOpacity,
  });

  final double spent;
  final double reserved;
  final double tick;
  final bool over;
  final double tickOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    const full = math.pi * 2;

    // Track — the "coin edge" with fine milling marks.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = K.seam
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    final mill = Paint()
      ..color = K.ledger.withValues(alpha: .55)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 120; i++) {
      final a = full * i / 120;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + o * (radius + stroke / 2 + 7),
        center + o * (radius + stroke / 2 + 11),
        Paint()
          ..color = K.seam.withValues(alpha: .8)
          ..strokeWidth = 1,
      );
      if (i.isEven) {
        canvas.drawLine(
          center + o * (radius - stroke / 2 + 2),
          center + o * (radius + stroke / 2 - 2),
          mill,
        );
      }
    }

    // Reserved for bills.
    if (reserved > 0) {
      canvas.drawArc(
        rect,
        start + full * spent,
        full * math.min(reserved, 1 - spent),
        false,
        Paint()
          ..color = K.brass.withValues(alpha: .28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Spent.
    if (spent > 0) {
      final color = over ? K.rose : K.brass;
      canvas.drawArc(
        rect,
        start,
        full * spent,
        false,
        Paint()
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: full,
            transform: const GradientRotation(start),
            colors: [color.withValues(alpha: .65), color],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // "Today" tick — how far through the month.
    final a = start + full * tick.clamp(0, 1);
    final o = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
      center + o * (radius - stroke / 2 - 6),
      center + o * (radius + stroke / 2 + 6),
      Paint()
        ..color = K.parchment.withValues(alpha: tickOpacity)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.spent != spent ||
      old.reserved != reserved ||
      old.tick != tick ||
      old.over != over ||
      old.tickOpacity != tickOpacity;
}

/// Bar chart; bars grow in, tapping one reveals its value.
class SpendBars extends StatefulWidget {
  const SpendBars({
    super.key,
    required this.values,
    required this.labels,
    this.highlight,
    this.hidden = false,
  });

  final List<double> values;
  final List<String> labels;
  final int? highlight;
  final bool hidden;

  @override
  State<SpendBars> createState() => _SpendBarsState();
}

class _SpendBarsState extends State<SpendBars> {
  int? _selected;

  @override
  void didUpdateWidget(covariant SpendBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final maxV = widget.values.fold<double>(0, math.max);
    final ceiling = maxV == 0 ? 1.0 : maxV;
    final shown = _selected ?? widget.highlight;
    return Column(
      children: [
        SizedBox(
          height: 26,
          child: AnimatedSwitcher(
            duration: K.motion(context, 180),
            child: shown == null
                ? const SizedBox.shrink()
                : Text(
                    '${widget.labels[shown]} · ${rs(widget.values[shown], hidden: widget.hidden)}',
                    key: ValueKey(shown),
                    style: K.body(13, color: K.sage, weight: FontWeight.w600),
                  ),
          ),
        ),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < widget.values.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = _selected == i ? null : i);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.values.length > 8 ? 2.5 : 5,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: widget.values[i] / ceiling),
                        duration: K.motion(context, 650 + i * 45),
                        curve: Curves.easeOutBack,
                        builder: (context, h, _) => Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: K.motion(context, 200),
                            height: math.max(6, 140 * h.clamp(0, 1.05)),
                            decoration: BoxDecoration(
                              color: i == shown
                                  ? K.brass
                                  : (widget.values[i] == 0
                                        ? K.seam
                                        : K.brass.withValues(alpha: .38)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              Expanded(
                child: Text(
                  widget.labels[i].length > 3
                      ? widget.labels[i].substring(0, 3)
                      : widget.labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: K.body(
                    11,
                    color: i == shown ? K.parchment : K.sage,
                    weight: i == shown ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Slim segmented control (Weekly / Monthly / Yearly etc.).
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth / options.length;
      final index = options.indexOf(value);
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: K.feltHigh,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: K.motion(context, 260),
              curve: Curves.easeOutCubic,
              left: w * index + 3,
              top: 3,
              bottom: 3,
              width: w - 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: K.brass,
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
            Row(
              children: [
                for (final o in options)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChanged(o);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: K.motion(context, 200),
                          style: K.body(
                            13,
                            weight: FontWeight.w700,
                            color: o == value ? K.brassDeep : K.sage,
                          ),
                          child: Text(o),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class KoinLogo extends StatelessWidget {
  const KoinLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Koin Flow logo',
    image: true,
    child: CustomPaint(
      size: Size.square(size),
      painter: const KoinMarkPainter(),
    ),
  );
}
