import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/services/auth_service.dart';
import 'package:gizlialan/services/secure_kv.dart';

import 'support/harness.dart';

void main() {
  tearDown(() => L10n.setLang('tr'));

  group('PIN hint (0.6.0 F)', () {
    late AuthService auth;
    late MemorySecureKv kv;
    setUp(() async {
      kv = MemorySecureKv();
      auth = AuthService(storage: kv, pbkdf2Iterations: 1000);
      await auth.setPin('2580');
      await auth.setDecoyPin('1111');
    });

    test('stored in the secret store, trimmed, removable', () async {
      expect(await auth.pinHint(), isNull);
      await auth.setPinHint('  annemin doğum yılı  ');
      expect(await auth.pinHint(), 'annemin doğum yılı');
      expect(kv.data.values, contains('annemin doğum yılı'));
      await auth.setPinHint('');
      expect(await auth.pinHint(), isNull);
    });

    test('rejects the real or decoy PIN and over-long hints', () async {
      expect(() => auth.setPinHint('kod 2580 :)'), throwsArgumentError);
      expect(() => auth.setPinHint('x11112'), throwsArgumentError);
      expect(() => auth.setPinHint('a' * 61), throwsArgumentError);
      await auth.setPinHint('ev numarası 1923');
      expect(await auth.pinHint(), 'ev numarası 1923');
    });
  });

  testWidgets('long-press the calculator display shows the hint', (
    tester,
  ) async {
    final h = await Harness.start(tester, calculator: true);
    await tester.runAsync(() => h.auth.setPinHint('kedinin adı + 1'));
    final area = find.byKey(const ValueKey('calc_display_area'));
    expect(area, findsOneWidget);
    await tester.longPress(area);
    await settle(tester);
    expect(find.text('kedinin adı + 1'), findsOneWidget);
  });
}
