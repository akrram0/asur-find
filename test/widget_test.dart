// Smoke test: verifies the app root constructs and renders the shell.
//
// This file is committed intentionally — `flutter create .` in CI only
// generates template files that do NOT already exist, so keeping a real
// test here prevents the broken MyApp template test from appearing.
//
// Note: the default flutter_test surface is 800x600 logical px, which is
// tight for a desktop window shell. We set a realistic desktop surface
// before pumping to avoid spurious layout/overflow failures.

import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:asur_find/main.dart';
import 'package:asur_find/data.dart';

void main() {
  testWidgets('MacosApp builds and shows the Dashboard shell', (
    WidgetTester tester,
  ) async {
    // Emulate a realistic desktop window (1440x900 @ 1x DPR).
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AsurFindApp());

    // Multiple frames: first builds, second lets post-layout work settle
    // (deliberately NOT pumpAndSettle, which can hang on looping UI).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Sidebar nav + Dashboard header both render the label.
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Dev Clutter'), findsOneWidget);
    expect(find.text('Large Files'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  test('mock data integrity — every cleanup item has a valid action', () {
    for (final item in kCleanupItems) {
      if (item.safety == SafetyLevel.locked) {
        expect(item.action, isNull);
      } else {
        expect(item.action, isNotNull);
      }
    }
  });
}

