import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/l10n/en.dart';
import 'package:gizlialan/l10n/tr.dart';
import 'package:gizlialan/util/text_case.dart';

void main() {
  test('Turkish upper case: i → İ, ı → I', () {
    expect(upperFor('Güvenlik', 'tr'), 'GÜVENLİK');
    expect(
      upperFor('İkinci telefon uygulamaları', 'tr'),
      'İKİNCİ TELEFON UYGULAMALARI',
    );
    expect(upperFor('Tarayıcı', 'tr'), 'TARAYICI');
    expect(upperFor('Security', 'en'), 'SECURITY');
    expect(upperFor('Güvenlik', 'tr'), isNot(contains('I')));
    expect(upperFor('Giriş', 'tr'), 'GİRİŞ');
    expect(upperFor(tr['security']!, 'tr'), 'GÜVENLİK');
    expect(upperFor(tr['entry']!, 'tr'), 'GİRİŞ');
  });

  test('Turkish strings fixed by the store audit', () {
    expect(tr['confirmPin'], "PIN'i tekrar gir");
    expect(tr['importedN'], contains('telefonunun galerisinde'));
    expect(tr['importedN'], isNot(contains('telefon galerinde')));
  });

  test('delete-original hint: one short sentence, no second phone', () {
    for (final s in [tr['deleteOriginalHint']!, en['deleteOriginalHint']!]) {
      expect('.'.allMatches(s).length, 1);
      expect(s.toLowerCase(), isNot(contains('ikinci telefon')));
      expect(s.toLowerCase(), isNot(contains('iş profili')));
      expect(s.toLowerCase(), isNot(contains('second phone')));
      expect(s.toLowerCase(), isNot(contains('work profile')));
      expect(s.length, lessThan(80));
    }
  });

  test('browser intro is at most 2 short sentences', () {
    for (final s in [tr['browserPrivacyNote']!, en['browserPrivacyNote']!]) {
      expect(RegExp(r'[.!?](\s|$)').allMatches(s).length, lessThanOrEqualTo(2));
      expect(s.length, lessThan(160));
    }
  });
}
