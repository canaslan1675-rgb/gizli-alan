import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/services/vault_space.dart';

import 'support/harness.dart';

void main() {
  tearDown(() => L10n.setLang('tr'));

  testWidgets('wrong-PIN summary: text only, real vault, once (E)', (
    tester,
  ) async {
    final h = await Harness.start(tester);
    await tester.runAsync(() async {
      for (var i = 0; i < 3; i++) {
        await h.auth.check('9999');
      }
    });
    await h.enter(tester);
    expect(find.text('3 wrong attempts since your last entry'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('failed_summary')));
    await tester.pump();
    expect(find.byKey(const ValueKey('failed_summary')), findsNothing);
    // Next entry: counter was consumed.
    h.state.lockVaultExplicit();
    await settle(tester);
    await h.enter(tester);
    expect(find.byKey(const ValueKey('failed_summary')), findsNothing);
  });

  testWidgets('decoy vault never shows the summary (E)', (tester) async {
    final h = await Harness.start(tester);
    await tester.runAsync(() => h.auth.check('9999'));
    await h.enter(tester, VaultSpace.decoy);
    expect(find.byKey(const ValueKey('failed_summary')), findsNothing);
  });

  test('Turkish wording is neutral', () {
    L10n.setLang('tr');
    final s = L10n.current('failedSummary');
    expect(s, 'Son girişten beri {n} hatalı deneme');
    for (final w in ['casus', 'davetsiz', 'spy', 'intruder']) {
      expect(s.toLowerCase().contains(w), isFalse);
    }
  });
}
