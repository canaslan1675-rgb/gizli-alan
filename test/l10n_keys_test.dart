import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show Locale;

import 'package:gizlialan/l10n/de.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/es.dart';
import 'package:gizlialan/l10n/fr.dart';
import 'package:gizlialan/l10n/it.dart';
import 'package:gizlialan/l10n/nl.dart';
import 'package:gizlialan/l10n/l10n.dart';
import 'package:gizlialan/l10n/ru.dart';
import 'package:gizlialan/l10n/tr.dart';
import 'package:gizlialan/l10n/zh.dart';

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

  final all = {
    'tr': tr,
    'ru': ru,
    'fr': fr,
    'de': de,
    'zh': zh,
    'es': es,
    'it': it,
    'nl': nl,
  };

  test('every language has exactly the keys of en', () {
    final e = en.keys.toSet();
    for (final MapEntry(:key, :value) in all.entries) {
      expect(
        e.difference(value.keys.toSet()),
        isEmpty,
        reason: 'missing in $key',
      );
      expect(
        value.keys.toSet().difference(e),
        isEmpty,
        reason: 'extra in $key',
      );
    }
  });

  test('placeholders match en in every language, no empty strings', () {
    final re = RegExp(r'\{\w+\}');
    List<String> ph(String s) =>
        re.allMatches(s).map((m) => m.group(0)!).toList()..sort();
    for (final MapEntry(:key, :value) in all.entries) {
      for (final k in en.keys) {
        expect(ph(value[k]!), ph(en[k]!), reason: '$key $k');
        expect(value[k]!.trim(), isNotEmpty, reason: '$key $k');
      }
    }
  });

  test('all languages are registered with labels', () {
    for (final c in ['tr', 'en', ...all.keys]) {
      expect(L10n.supported, contains(c));
      expect(L10n.labels[c], isNotNull);
      L10n.setLang(c);
      expect(L10n.lang, c);
    }
    L10n.setLang('fr');
    expect(L10n.current.t('settings'), 'Réglages');
    L10n.setLang('zh');
    expect(L10n.current.t('settings'), '设置');
    L10n.setLang('tr');
  });

  test('device locale picks the default language', () {
    String f(List<String> c) => L10n.fromLocales(c.map(Locale.new));
    expect(f(['tr']), 'tr');
    expect(f(['ru']), 'ru');
    expect(f(['fr']), 'fr');
    expect(f(['de']), 'de');
    expect(f(['zh']), 'zh');
    expect(f(['es']), 'es');
    expect(f(['it']), 'it');
    expect(f(['nl']), 'nl');
    expect(f(['en']), 'en');
    expect(f(['hi']), 'en');
    expect(f(['ms', 'zh']), 'zh');
    expect(f(['lb']), 'en');
    expect(f([]), 'en');
  });
}
