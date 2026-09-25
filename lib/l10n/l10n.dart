import 'package:flutter/widgets.dart';

import 'en.dart';
import 'tr.dart';

/// Tiny map-based l10n (TR default, EN). Keys missing in a map fall back to
/// the other language, then to the key itself.
class L10n {
  L10n._(this._map, this._fallback);
  final Map<String, String> _map;
  final Map<String, String> _fallback;

  static String _lang = 'tr';

  static String get lang => _lang;

  static const supported = ['tr', 'en'];

  static void setLang(String code) {
    _lang = (code == 'en') ? 'en' : 'tr';
  }

  static L10n get current => _lang == 'en' ? L10n._(en, tr) : L10n._(tr, en);

  /// Same as [current] but registers [context] for rebuilds when the language
  /// changes (see [L10nScope]).
  static L10n of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<L10nScope>();
    return current;
  }

  String t(String key) => _map[key] ?? _fallback[key] ?? key;

  String call(String key) => t(key);
}

/// Placed above MaterialApp; rebuilds dependents when the language changes.
class L10nScope extends InheritedWidget {
  const L10nScope({super.key, required this.lang, required super.child});

  final String lang;

  @override
  bool updateShouldNotify(L10nScope oldWidget) => oldWidget.lang != lang;
}
