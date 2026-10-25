import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/screens/notes_list_screen.dart';
import 'package:gizlialan/screens/vault_home_screen.dart';

import 'support/harness.dart';

void main() {
  tearDown(() => L10n.setLang('tr'));

  testWidgets('quick lock button in a vault screen locks at once (D)', (
    tester,
  ) async {
    final h = await Harness.start(tester);
    await h.enter(tester);
    h.state.navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const NotesListScreen()),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('quick_lock')));
    await settle(tester);
    expect(h.state.isUnlocked, isFalse);
    expect(find.byType(VaultHomeScreen), findsNothing);
  });

  testWidgets('double-tap on the clock locks (D)', (tester) async {
    final h = await Harness.start(tester);
    await h.enter(tester);
    final clock = find.byKey(const ValueKey('clock_quick_lock'));
    await tester.tap(clock);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(clock);
    await settle(tester);
    expect(h.state.isUnlocked, isFalse);
  });
}
