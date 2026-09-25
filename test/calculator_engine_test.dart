import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/calculator_engine.dart';

String run(String keys) {
  final e = CalculatorEngine();
  for (final k in keys.split(' ')) {
    e.input(k);
  }
  return e.display;
}

void main() {
  test('basic arithmetic with precedence', () {
    expect(run('1 2 + 3 × 4 ='), '24');
    expect(run('1 0 ÷ 4 ='), '2.5');
    expect(run('7 − 1 0 ='), '-3');
    expect(run('0 . 1 + 0 . 2 ='), '0.3');
    expect(run('5 0 % × 8 ='), '4');
  });

  test('division by zero shows Error', () {
    expect(run('5 ÷ 0 ='), 'Error');
  });

  test('operator replacement and chaining after result', () {
    expect(run('2 + × 3 ='), '6');
    expect(run('2 + 3 = × 4 ='), '20');
  });

  test('backspace and clear', () {
    expect(run('1 2 3 ⌫'), '12');
    expect(run('1 2 3 C'), '0');
  });

  test('pinCandidate only for 4–8 freshly typed digits', () {
    final e = CalculatorEngine();
    for (final k in ['2', '5', '8', '0']) {
      e.input(k);
    }
    expect(e.pinCandidate, '2580');
    e.input('+');
    expect(e.pinCandidate, isNull);

    final r = CalculatorEngine();
    for (final k in '1000+234='.split('')) {
      r.input(k);
    }
    expect(r.display, '1234');
    expect(r.pinCandidate, isNull, reason: 'results never count as a PIN');

    final s = CalculatorEngine();
    for (final k in ['1', '2', '3']) {
      s.input(k);
    }
    expect(s.pinCandidate, isNull);
  });

  test('evaluateExpression / format helpers', () {
    expect(CalculatorEngine.evaluateExpression('−2×3'), -6);
    expect(CalculatorEngine.evaluateExpression('2+'), 2);
    expect(CalculatorEngine.evaluateExpression('×'), isNull);
    expect(CalculatorEngine.format(1 / 3), '0.3333333333');
  });
}
