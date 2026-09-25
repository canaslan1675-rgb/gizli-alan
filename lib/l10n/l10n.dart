import 'en.dart';
import 'tr.dart';

/// Tiny map-based l10n. Turkish is default.
class L10n {
  L10n._(this._map);
  final Map<String, String> _map;

  static String _lang = 'tr';

  static String get lang => _lang;

  static void setLang(String code) {
    _lang = (code == 'en') ? 'en' : 'tr';
  }

  static L10n get current => L10n._(_lang == 'en' ? en : tr);

  String t(String key) => _map[key] ?? key;

  String call(String key) => t(key);
}
