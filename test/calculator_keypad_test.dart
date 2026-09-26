import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/screens/decoy_calculator_screen.dart';

void main() {
  Future<void> press(WidgetTester t, String keys) async {
    for (final k in keys.split(' ')) {
      await t.tap(find.byKey(ValueKey('calc_$k')));
      await t.pump();
    }
  }

  String display(WidgetTester t) =>
      t.widget<Text>(find.byKey(const ValueKey('calc_display'))).data!;

  testWidgets('keypad: every key exists and basic math works', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: DecoyCalculatorScreen()));
    for (final k in [
      ...'0123456789'.split(''),
      '.', '+', '−', '×', '÷', '%', '±', '=', 'C', '⌫', //
    ]) {
      expect(find.byKey(ValueKey('calc_$k')), findsOneWidget, reason: k);
    }
    await press(t, '2 + 3 × 4 =');
    expect(display(t), '14');
    await press(t, 'C 0 . 1 + 0 . 2 =');
    expect(display(t), '0.3');
    await press(t, 'C 5 ÷ 0 =');
    expect(display(t), 'Error');
    await press(t, 'C 7 ± × 3 =');
    expect(display(t), '-21');
    await press(t, 'C 1 2 3 ⌫');
    expect(display(t), '12');
    expect(
      t.widget<Text>(find.byKey(const ValueKey('calc_expression'))).data,
      '12',
    );
    // Not the vault entry: no ⓘ button.
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });
}
