import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/l10n/ru.dart';
import 'package:gizlialan/l10n/tr.dart';

void main() {
  test('tr / en / ru have exactly the same keys', () {
    final t = tr.keys.toSet();
    expect(en.keys.toSet().difference(t), isEmpty, reason: 'en-only keys');
    expect(t.difference(en.keys.toSet()), isEmpty, reason: 'tr-only keys');
    expect(ru.keys.toSet().difference(t), isEmpty, reason: 'ru-only keys');
    expect(t.difference(ru.keys.toSet()), isEmpty, reason: 'missing in ru');
  });

  test('placeholders match across languages', () {
    final re = RegExp(r'\{\w+\}');
    List<String> ph(String s) =>
        re.allMatches(s).map((m) => m.group(0)!).toList()..sort();
    for (final k in tr.keys) {
      expect(ph(ru[k]!), ph(en[k]!), reason: 'ru $k');
      expect(ph(tr[k]!), ph(en[k]!), reason: 'tr $k');
    }
  });

  test('ru locale is registered and selectable', () {
    expect(L10n.supported, containsAll(['tr', 'en', 'ru']));
    L10n.setLang('ru');
    expect(L10n.lang, 'ru');
    expect(L10n.current.t('settings'), 'Настройки');
    expect(
      L10n.current.t('analyticsToggle'),
      'Анонимная статистика и измерение рекламы',
    );
    L10n.setLang('xx');
    expect(L10n.lang, 'tr');
  });
}
