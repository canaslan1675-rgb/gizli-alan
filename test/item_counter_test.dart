import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/widgets/pro_gate.dart';

void main() {
  group('item counter (0.6.0 B)', () {
    test('free: n/10, full at 10, never negative above the limit', () {
      expect(ItemLimit.counterLabel(pro: false, stored: 7), '7/10');
      expect(ItemLimit.isFull(pro: false, stored: 7), isFalse);
      expect(ItemLimit.isFull(pro: false, stored: 10), isTrue);
      expect(ItemLimit.leftFor(pro: false, stored: 63), 0);
      expect(ItemLimit.counterLabel(pro: false, stored: 63), '63/10');
    });
    test('Pro: no counter, never full', () {
      expect(ItemLimit.counterLabel(pro: true, stored: 500), isNull);
      expect(ItemLimit.isFull(pro: true, stored: 500), isFalse);
      expect(ItemLimit.leftFor(pro: true, stored: 500), isNull);
    });
  });

  test(
    'existing free vault above the new limit (e.g. 50 items from <=0.6.0) keeps everything, cannot grow',
    () {
      expect(ItemLimit.leftFor(pro: false, stored: 50), 0);
      expect(ItemLimit.isFull(pro: false, stored: 50), isTrue);
      expect(ItemLimit.counterLabel(pro: false, stored: 50), '50/10');
      expect(ItemLimit.leftFor(pro: false, stored: 9), 1);
      expect(ItemLimit.leftFor(pro: true, stored: 50), isNull);
    },
  );
}
