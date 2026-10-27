import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/joi_quota.dart';

void main() {
  test('10 per day, resets at local midnight', () async {
    var now = DateTime(2026, 10, 27, 23, 50);
    final q = JoiDailyQuota.memory(now: () => now);
    expect(q.label, '0/10');
    for (var i = 0; i < 10; i++) {
      expect(q.exhausted, isFalse);
      await q.consume();
    }
    expect(q.exhausted, isTrue);
    expect(q.label, '10/10');
    now = DateTime(2026, 10, 28, 0, 1);
    expect(q.used, 0);
    expect(q.exhausted, isFalse);
    await q.consume();
    expect(q.label, '1/10');
  });
}
