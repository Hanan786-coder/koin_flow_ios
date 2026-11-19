import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'theme.dart';

const _cupertinoDark = CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: K.brass,
);

Widget _dark(Widget child) =>
    CupertinoTheme(data: _cupertinoDark, child: child);

class IOSAction<T> {
  const IOSAction(
    this.label,
    this.value, {
    this.destructive = false,
    this.isDefault = false,
  });
  final String label;
  final T value;
  final bool destructive;
  final bool isDefault;
}

/// Native-style iOS alert.
Future<T?> showIOSAlert<T>(
  BuildContext context, {
  required String title,
  String? message,
  required List<IOSAction<T>> actions,
}) => showCupertinoDialog<T>(
  context: context,
  barrierDismissible: true,
  builder: (ctx) => _dark(
    CupertinoAlertDialog(
      title: Text(title),
      content: message == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message),
            ),
      actions: [
        for (final a in actions)
          CupertinoDialogAction(
            isDestructiveAction: a.destructive,
            isDefaultAction: a.isDefault,
            onPressed: () => Navigator.pop(ctx, a.value),
            child: Text(a.label),
          ),
      ],
    ),
  ),
);

/// iOS alert with a text field. Returns null when cancelled.
Future<String?> showIOSPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String initial = '',
  String placeholder = '',
  String confirm = 'Save',
  bool multiline = false,
  TextCapitalization capitalization = TextCapitalization.sentences,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showCupertinoDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _dark(
      CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 10),
                child: Text(message),
              )
            else
              const SizedBox(height: 10),
            CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: placeholder,
              minLines: multiline ? 5 : 1,
              maxLines: multiline ? 8 : 1,
              textCapitalization: capitalization,
              style: K.body(15, color: K.parchment),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: K.ledger,
                borderRadius: BorderRadius.circular(10),
              ),
              onSubmitted: multiline ? null : (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(confirm),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}

/// iOS action sheet listing [options]; returns the chosen one.
Future<String?> showIOSChoice(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
}) => showCupertinoModalPopup<String>(
  context: context,
  builder: (ctx) => _dark(
    CupertinoActionSheet(
      title: Text(title),
      actions: [
        for (final o in options)
          CupertinoActionSheetAction(
            isDefaultAction: o == selected,
            onPressed: () => Navigator.pop(ctx, o),
            child: Text(o),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('Cancel'),
      ),
    ),
  ),
);

/// iOS wheel date picker in a bottom popup.
Future<DateTime?> pickDateIOS(
  BuildContext context, {
  required DateTime initial,
  DateTime? minimum,
  DateTime? maximum,
  String title = 'Choose a date',
}) {
  var value = dayOnly(initial);
  final min = minimum == null ? null : dayOnly(minimum);
  final max = maximum == null ? null : dayOnly(maximum);
  if (min != null && value.isBefore(min)) value = min;
  if (max != null && value.isAfter(max)) value = max;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => _dark(
      Container(
        height: 330,
        decoration: const BoxDecoration(
          color: K.felt,
          borderRadius: BorderRadius.vertical(top: Radius.circular(K.rCard)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: K.body(16, color: K.sage)),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: K.body(16, weight: FontWeight.w700),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx, value),
                      child: Text(
                        'Done',
                        style: K.body(
                          16,
                          color: K.brass,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: value,
                  minimumDate: min,
                  maximumDate: max,
                  dateOrder: DatePickerDateOrder.dmy,
                  onDateTimeChanged: (d) {
                    HapticFeedback.selectionClick();
                    value = d;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TabItem {
  const TabItem(this.label, this.symbol, this.icon);
  final String label;
  final String symbol; // SF Symbol for the native bar
  final IconData icon; // Flutter icon for the glass replica
}

/// Floating "liquid glass" tab bar that mirrors the iOS 26 native bar.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<TabItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottom > 0 ? bottom - 14 : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF233A31).withValues(alpha: .62),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: .09)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: .07),
                  Colors.white.withValues(alpha: .01),
                ],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: K.motion(context, 380),
                      curve: Curves.easeOutBack,
                      left: w * index,
                      top: 0,
                      bottom: 0,
                      width: w,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(36),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: Semantics(
                              selected: i == index,
                              button: true,
                              label: items[i].label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onTap(i),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedScale(
                                        duration: K.motion(context, 260),
                                        curve: Curves.easeOutBack,
                                        scale: i == index ? 1.08 : 1,
                                        child: Icon(
                                          items[i].icon,
                                          size: 23,
                                          color: i == index
                                              ? K.brass
                                              : K.parchment.withValues(
                                                  alpha: .85,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        items[i].label,
                                        style: K.body(
                                          10.5,
                                          weight: FontWeight.w600,
                                          color: i == index
                                              ? K.brass
                                              : K.parchment.withValues(
                                                  alpha: .85,
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// iPhone 16 frame used only by the preview build (`--dart-define=DEMO=true`).
class IPhoneFrame extends StatelessWidget {
  const IPhoneFrame({super.key, required this.child});
  final Widget child;

  static const _screen = Size(393, 852);
  static const _bezel = 13.0;

  @override
  Widget build(BuildContext context) {
    final outer = Size(_screen.width + _bezel * 2, _screen.height + _bezel * 2);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFF2B302E),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              child: Container(
                width: outer.width,
                height: outer.height,
                padding: const EdgeInsets.all(_bezel),
                decoration: BoxDecoration(
                  color: const Color(0xFF050505),
                  borderRadius: BorderRadius.circular(68),
                  border: Border.all(
                    color: const Color(0xFF5A5E5C),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 40,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(55),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: _screen,
                      padding: const EdgeInsets.only(top: 59, bottom: 34),
                      viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(child: child),
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(child: _StatusBar()),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 140,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .9),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: Stack(
      children: [
        Positioned(
          top: 11,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 124,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        Positioned(
          left: 44,
          top: 19,
          child: Text(
            '9:41',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontFamilyFallback: const ['Figtree'],
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -.3,
            ),
          ),
        ),
        const Positioned(
          right: 32,
          top: 21,
          child: Row(
            children: [
              Icon(
                Icons.signal_cellular_alt_rounded,
                size: 17,
                color: Colors.white,
              ),
              SizedBox(width: 5),
              Icon(Icons.wifi_rounded, size: 17, color: Colors.white),
              SizedBox(width: 5),
              _Battery(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Battery extends StatelessWidget {
  const _Battery();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 25,
        height: 12,
        padding: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .45)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Container(
        width: 1.5,
        height: 4,
        margin: const EdgeInsets.only(left: 1),
        color: Colors.white.withValues(alpha: .45),
      ),
    ],
  );
}
