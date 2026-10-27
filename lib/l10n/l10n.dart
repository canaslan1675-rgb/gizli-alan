import 'package:flutter/widgets.dart';

import '../flavor.dart';
import 'de.dart';
import 'en.dart';
import 'es.dart';
import 'fr.dart';
import 'it.dart';
import 'nl.dart';
import 'ru.dart';
import 'tr.dart';
import 'zh.dart';

/// Tiny map-based l10n (TR default, EN, RU). Keys missing in a map fall back to
/// the other language, then to the key itself.
class L10n {
  L10n._(this._map, this._fallback);
  final Map<String, String> _map;
  final Map<String, String> _fallback;

  static String _lang = 'tr';

  static String get lang => _lang;

  static const supported = [
    'tr',
    'en',
    'ru',
    'fr',
    'de',
    'zh',
    'es',
    'it',
    'nl',
  ];

  /// Display labels for the language pickers.
  static const labels = {
    'tr': 'Türkçe',
    'en': 'English',
    'ru': 'Русский',
    'fr': 'Français',
    'de': 'Deutsch',
    'zh': '中文',
    'es': 'Español',
    'it': 'Italiano',
    'nl': 'Nederlands',
  };

  /// Language to use when the user has not chosen one yet: the first device
  /// locale we support; English for anything else.
  static String fromLocales(Iterable<Locale> locales) {
    for (final l in locales) {
      if (supported.contains(l.languageCode)) return l.languageCode;
    }
    return 'en';
  }

  static void setLang(String code) {
    _lang = supported.contains(code) ? code : 'tr';
  }

  static L10n get current => switch (_lang) {
    'en' => L10n._(en, tr),
    'ru' => L10n._(ru, en),
    'fr' => L10n._(fr, en),
    'de' => L10n._(de, en),
    'zh' => L10n._(zh, en),
    'es' => L10n._(es, en),
    'it' => L10n._(it, en),
    'nl' => L10n._(nl, en),
    _ => L10n._(tr, en),
  };

  /// Same as [current] but registers [context] for rebuilds when the language
  /// changes (see [L10nScope]).
  static L10n of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<L10nScope>();
    return current;
  }

  /// Keys may have a `<key>_play` variant used by the `play` flavor (texts
  /// that would otherwise mention the Second phone, which that build lacks).
  String t(String key) {
    if (!Flavor.hasSecondPhone) {
      final v = _map['${key}_play'] ?? _fallback['${key}_play'];
      if (v != null) return v;
    }
    return _map[key] ?? _fallback[key] ?? key;
  }

  String call(String key) => t(key);
}

/// Placed above MaterialApp; rebuilds dependents when the language changes.
class L10nScope extends InheritedWidget {
  const L10nScope({super.key, required this.lang, required super.child});

  final String lang;

  @override
  bool updateShouldNotify(L10nScope oldWidget) => oldWidget.lang != lang;
}
