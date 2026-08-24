// Smoke test: verifies the app root constructs and renders the shell.
//
// This file is committed intentionally — `flutter create .` in CI only
// generates template files that do NOT already exist, so keeping a real
// test here prevents the broken MyApp template test from appearing.

import 'package:flutter_test/flutter_test.dart';

import 'package:asur_find/main.dart';
import 'package:asur_find/data.dart';

void main() {
  testWidgets('MacosApp builds and shows the Dashboard shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AsurFindApp());
    // Let the window shell finish its first layout pass.
    await tester.pump();

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
