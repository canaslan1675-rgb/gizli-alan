import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/calculator_engine.dart';

CalculatorEngine keys(String k) {
  final e = CalculatorEngine();
  for (final key in k.split(' ')) {
    if (key.isNotEmpty) e.input(key);
  }
  return e;
}

String run(String k) => keys(k).display;

void main() {
  group('precedence and chaining', () {
    test('× ÷ before + −', () {
      expect(run('2 + 3 × 4 ='), '14');
      expect(run('1 0 − 6 ÷ 3 ='), '8');
      expect(run('2 × 3 + 4 × 5 ='), '26');
      expect(run('8 ÷ 2 ÷ 2 ='), '2');
      expect(run('1 0 − 2 − 3 ='), '5');
    });
    test('chaining after a result', () {
      expect(run('2 + 3 = × 4 ='), '20');
      expect(run('9 = − 1 0 ='), '-1');
    });
    test('chained results keep full precision', () {
      expect(run('1 ÷ 3 = × 3 ='), '1');
      expect(run('2 ÷ 3 = + 1 ÷ 3 ='), '1');
    });
    test('typing a number after = starts fresh', () {
      expect(run('2 + 3 = 7'), '7');
      expect(keys('2 + 3 = 7 + 1 =').display, '8');
    });
  });

  group('decimals and display', () {
    test('float noise is hidden', () {
      expect(run('0 . 1 + 0 . 2 ='), '0.3');
      expect(run('0 . 1 × 3 ='), '0.3');
      expect(run('1 . 1 × 1 . 1 ='), '1.21');
      expect(run('0 . 3 − 0 . 1 ='), '0.2');
    });
    test('decimal entry rules', () {
      expect(run('.'), '0.');
      expect(run('. 5 + . 5 ='), '1');
      expect(run('1 . 2 . 3'), '1.23'); // second "." ignored
      expect(run('5 . ='), '5');
      expect(run('5 . +'), '5'); // "5." → "5+"
    });
    test('leading zeros', () {
      expect(run('0 0 7'), '7');
      expect(run('0 0'), '0');
      expect(run('0 . 0 5'), '0.05');
      expect(run('1 + 0 0 3 ='), '4');
    });
    test('very large and very small numbers', () {
      expect(run('9 9 9 9 9 9 9 9 × 9 9 9 9 9 9 9 9 ='), '9.9999998e+15');
      expect(run('1 ÷ 3 ='), '0.3333333333');
      expect(run('1 2 3 4 5 6 7 8 9 . 1 2 3 ='), '123456789.123');
      final small = run('1 ÷ 1 0 0 0 0 0 0 0 0 0 0 0 =');
      expect(small, '1e-11');
      // Results in e-notation can be used again.
      expect(
        run('9 9 9 9 9 9 9 9 × 9 9 9 9 9 9 9 9 = ÷ 9 9 9 9 9 9 9 9 ='),
        '99999999',
      );
    });
    test('max 15 digits per number', () {
      expect(run('1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7'), '123456789012345');
    });
    test('negative zero shows 0', () {
      expect(run('0 × − 5 ='), isNot('-0'));
      expect(CalculatorEngine.format(-0.0), '0');
    });
  });

  group('errors', () {
    test('division by zero → Error, no crash, recovers', () {
      expect(run('5 ÷ 0 ='), 'Error');
      expect(run('0 ÷ 0 ='), 'Error');
      expect(run('5 ÷ 0 = 3 + 4 ='), '7');
      expect(run('5 ÷ 0 = ⌫'), '0');
      expect(run('5 ÷ 0 = + 3'), '3');
      expect(run('5 ÷ 0 = ='), 'Error');
    });
    test('= on empty or only an operator does nothing', () {
      expect(run('='), '0');
      expect(run('− ='), '0');
      expect(run('+ ='), '0');
    });
  });

  group('%, ±, negatives', () {
    test('percent semantics', () {
      expect(run('5 0 %'), '50%');
      expect(run('5 0 % ='), '0.5');
      expect(run('2 0 0 + 1 0 % ='), '220');
      expect(run('2 0 0 − 1 0 % ='), '180');
      expect(run('5 0 × 1 0 % ='), '5');
      expect(run('5 0 % × 8 ='), '4');
      expect(run('% ='), '0');
      expect(run('5 % %'), '5%'); // second % ignored
    });
    test('± toggles the current number', () {
      expect(run('5 ±'), '-5');
      expect(run('5 ± ±'), '5');
      expect(run('5 ± + 3 ='), '-2');
      expect(run('5 × 3 ± ='), '-15');
      expect(run('5 − 3 ± ='), '8');
      expect(run('2 + 3 = ±'), '-5');
      expect(run('2 + 3 = ± × 2 ='), '-10');
    });
    test('negative results and leading minus', () {
      expect(run('3 − 8 ='), '-5');
      expect(run('− 3 × 2 ='), '-6');
      expect(run('3 − 8 = × − 2 ='), '-7'); // × replaced by −
    });
  });

  group('repeated =', () {
    test('repeats the last operation', () {
      expect(run('2 + 3 = ='), '8');
      expect(run('2 + 3 = = ='), '11');
      expect(run('2 × 3 = ='), '18');
      expect(run('1 0 0 ÷ 2 = ='), '25');
      expect(run('5 = ='), '5');
    });
  });

  group('editing', () {
    test('operator twice replaces it', () {
      expect(run('2 + × 3 ='), '6');
      expect(run('2 × + − 3 ='), '-1');
      expect(keys('2 + ×').expression, '2×');
    });
    test('backspace and C', () {
      expect(run('1 2 3 ⌫'), '12');
      expect(run('1 2 3 ⌫ ⌫ ⌫'), '0');
      expect(run('1 2 3 ⌫ ⌫ ⌫ ⌫'), '0');
      expect(keys('1 2 + ⌫').expression, '12');
      expect(run('1 2 + 3 = ⌫'), '0'); // result: ⌫ clears
      expect(run('1 2 3 C'), '0');
      expect(keys('1 2 + 3 C').expression, '');
      expect(run('2 + 3 = C ='), '0'); // C also forgets repeat
    });
  });

  group('vault PIN entry does not change normal math', () {
    test('pinCandidate only for 4–8 freshly typed plain digits', () {
      expect(keys('2 5 8 0').pinCandidate, '2580');
      expect(keys('1 2 3').pinCandidate, isNull);
      expect(keys('1 2 3 4 5 6 7 8 9').pinCandidate, isNull);
      expect(keys('2 5 8 0 +').pinCandidate, isNull);
      expect(keys('2 5 8 0 %').pinCandidate, isNull);
      expect(keys('2 5 . 8').pinCandidate, isNull);
      expect(keys('1 0 0 0 + 1 5 8 0 =').pinCandidate, isNull);
      expect(keys('2 5 8 0 ±').pinCandidate, isNull);
    });
    test('the same digits without a PIN match just evaluate', () {
      // UI only diverts "=" when AuthService confirms a PIN; otherwise:
      expect(run('2 5 8 0 ='), '2580');
      expect(run('2 5 8 0 = + 1 ='), '2581');
      expect(run('1 0 0 0 + 1 5 8 0 ='), '2580');
    });
  });
}
