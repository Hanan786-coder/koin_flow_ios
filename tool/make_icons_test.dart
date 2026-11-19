// Renders the Koin Flow mark into every iOS app-icon size.
// Run from the project root:  flutter test tool/make_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koin_flow/logo.dart';

const _dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _sizes = {
  'Icon-App-20x20@1x.png': 20,
  'Icon-App-20x20@2x.png': 40,
  'Icon-App-20x20@3x.png': 60,
  'Icon-App-29x29@1x.png': 29,
  'Icon-App-29x29@2x.png': 58,
  'Icon-App-29x29@3x.png': 87,
  'Icon-App-40x40@1x.png': 40,
  'Icon-App-40x40@2x.png': 80,
  'Icon-App-40x40@3x.png': 120,
  'Icon-App-60x60@2x.png': 120,
  'Icon-App-60x60@3x.png': 180,
  'Icon-App-76x76@1x.png': 76,
  'Icon-App-76x76@2x.png': 152,
  'Icon-App-83.5x83.5@2x.png': 167,
  'Icon-App-1024x1024@1x.png': 1024,
};

void main() {
  testWidgets('write app icons', (tester) async {
    await tester.runAsync(() async {
      for (final entry in _sizes.entries) {
        final px = entry.value.toDouble();
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const KoinMarkPainter(background: true).paint(canvas, Size(px, px));
        final image = await recorder.endRecording().toImage(
          entry.value,
          entry.value,
        );
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$_dir/${entry.key}').writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    });
  });
}
