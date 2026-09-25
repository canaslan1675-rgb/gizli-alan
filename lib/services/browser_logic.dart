/// Pure logic of the in-vault private browser (issue #32): search engines,
/// address-bar parsing and which navigations are allowed. No networking
/// here — the WebView only loads what the user typed or tapped.
library;

enum SearchEngine {
  duckduckgo('DuckDuckGo', 'https://duckduckgo.com/?q='),
  startpage('Startpage', 'https://www.startpage.com/do/search?q='),
  brave('Brave Search', 'https://search.brave.com/search?q='),
  google('Google', 'https://www.google.com/search?q='),
  bing('Bing', 'https://www.bing.com/search?q=');

  const SearchEngine(this.label, this.queryPrefix);

  final String label;
  final String queryPrefix;

  static SearchEngine parse(String? v) => SearchEngine.values.firstWhere(
    (e) => e.name == v,
    orElse: () => SearchEngine.duckduckgo,
  );

  Uri search(String query) =>
      Uri.parse('$queryPrefix${Uri.encodeQueryComponent(query.trim())}');
}

class BrowserLogic {
  BrowserLogic._();

  static const allowedSchemes = {'http', 'https'};

  /// Address bar input → URL to load. Web URLs load directly (bare domains
  /// get https://); anything else — including `file:`, `content:`,
  /// `javascript:`, `intent:` — is treated as a search query, never opened.
  /// Returns null for empty input.
  static Uri? resolve(String input, SearchEngine engine) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final direct = Uri.tryParse(text);
    if (direct != null &&
        allowedSchemes.contains(direct.scheme.toLowerCase()) &&
        direct.host.isNotEmpty) {
      return direct;
    }
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(text);
    if (!text.contains(' ') && !hasScheme && text.contains('.')) {
      final guess = Uri.tryParse('https://$text');
      final host = guess?.host ?? '';
      if (guess != null &&
          host.contains('.') &&
          !host.startsWith('.') &&
          !host.endsWith('.')) {
        return guess;
      }
    }
    if (hasScheme && !text.contains(' ') && _looksLikeHostPort(text)) {
      final guess = Uri.tryParse('https://$text');
      if (guess != null && guess.host.isNotEmpty) return guess;
    }
    return engine.search(text);
  }

  // "localhost:8080" / "example.com:8443/x" parse as scheme:path.
  static bool _looksLikeHostPort(String t) =>
      RegExp(r'^[a-zA-Z0-9.-]+:\d{1,5}(/.*)?$').hasMatch(t);

  /// Only http(s) pages (and the blank start page) may load inside the
  /// vault browser. tel:, mailto:, intent:, market:, file:, content: … are
  /// blocked so nothing leaves the vault to another app.
  static bool isAllowedNavigation(String url) {
    if (url == 'about:blank') return true;
    final u = Uri.tryParse(url);
    return u != null && allowedSchemes.contains(u.scheme.toLowerCase());
  }
}
