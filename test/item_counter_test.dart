import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/widgets/pro_gate.dart';

void main() {
  group('item counter (0.6.0 B)', () {
    test('free: n/50, full at 50, never negative above the limit', () {
      expect(ItemLimit.counterLabel(pro: false, stored: 42), '42/50');
      expect(ItemLimit.isFull(pro: false, stored: 42), isFalse);
      expect(ItemLimit.isFull(pro: false, stored: 50), isTrue);
      expect(ItemLimit.leftFor(pro: false, stored: 63), 0);
      expect(ItemLimit.counterLabel(pro: false, stored: 63), '63/50');
    });
    test('Pro: no counter, never full', () {
      expect(ItemLimit.counterLabel(pro: true, stored: 500), isNull);
      expect(ItemLimit.isFull(pro: true, stored: 500), isFalse);
      expect(ItemLimit.leftFor(pro: true, stored: 500), isNull);
    });
  });
}
