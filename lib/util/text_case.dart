/// Locale-aware upper case. Dart's [String.toUpperCase] maps `i` → `I`,
/// which is wrong in Turkish ("GÜVENLIK"): there `i` → `İ` and `ı` → `I`.
String upperFor(String text, String lang) {
  if (lang == 'tr' || lang == 'az') {
    text = text.replaceAll('i', 'İ').replaceAll('ı', 'I');
  }
  return text.toUpperCase();
}
