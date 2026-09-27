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
  });

  test('Turkish strings fixed by the store audit', () {
    expect(tr['confirmPin'], "PIN'i tekrar gir");
    expect(tr['importedN'], contains('telefonunun galerisinde'));
    expect(tr['importedN'], isNot(contains('telefon galerinde')));
  });

  test('play delete-original hint mentions no second phone / work profile', () {
    for (final s in [
      tr['deleteOriginalHintPlay']!,
      en['deleteOriginalHintPlay']!,
    ]) {
      expect(s.toLowerCase(), isNot(contains('ikinci telefon')));
      expect(s.toLowerCase(), isNot(contains('iş profili')));
      expect(s.toLowerCase(), isNot(contains('second phone')));
      expect(s.toLowerCase(), isNot(contains('work profile')));
      expect(s.length, lessThan(220));
    }
  });
}
