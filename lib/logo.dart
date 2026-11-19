import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// The Koin Flow mark: a milled brass coin with a K whose lower leg flows out.
/// Pure geometry, so the same painter draws the in-app logo and the app icon.
class KoinMarkPainter extends CustomPainter {
  const KoinMarkPainter({this.background = false});

  /// Fill the square with ledger green (for the app icon).
  final bool background;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);

    if (background) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.3, -.4),
            radius: 1.1,
            colors: [Color(0xFF1B3A2F), K.ledger],
          ).createShader(Offset.zero & size),
      );
    }

    final r = background ? s * .36 : s * .5;

    // Coin body.
    final body = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6D488), K.brass, Color(0xFFB98A2E)],
        ).createShader(body),
    );

    // Milled edge.
    final mill = Paint()
      ..color = const Color(0xFF9C7220).withValues(alpha: .55)
      ..strokeWidth = math.max(1, r * .028)
      ..strokeCap = StrokeCap.round;
    const notches = 48;
    for (var i = 0; i < notches; i++) {
      final a = math.pi * 2 * i / notches;
      final o = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + o * r * .87, c + o * r * .95, mill);
    }

    // Inner face.
    canvas.drawCircle(
      c,
      r * .8,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFC46C), Color(0xFFD9A645)],
        ).createShader(Rect.fromCircle(center: c, radius: r * .8)),
    );

    // The K.
    final ink = Paint()
      ..color = K.brassDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .17
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => c + Offset(x * r, y * r);

    canvas.drawLine(p(-.3, -.42), p(-.3, .42), ink); // stem
    canvas.drawLine(p(-.24, .02), p(.28, -.42), ink); // upper arm
    // Lower leg flows out to the right like a current.
    final leg = Path()
      ..moveTo(p(-.12, -.06).dx, p(-.12, -.06).dy)
      ..quadraticBezierTo(
        p(.1, .14).dx,
        p(.1, .14).dy,
        p(.16, .3).dx,
        p(.16, .3).dy,
      )
      ..quadraticBezierTo(
        p(.22, .44).dx,
        p(.22, .44).dy,
        p(.42, .42).dx,
        p(.42, .42).dy,
      );
    canvas.drawPath(leg, ink);
  }

  @override
  bool shouldRepaint(covariant KoinMarkPainter old) =>
      old.background != background;
}
