import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/browser_engine.dart';
import '../services/browser_logic.dart';
import '../theme.dart';

/// In-vault private browser (#32). One tab, Android System WebView. Only
/// pages the user opens are loaded; GizliAlan adds no tracking of its own.
/// History lives in the WebView's memory and disappears with this screen;
/// cookies/cache/storage are wiped on vault lock ("Kilitlenince temizle").
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  BrowserEngine? _engine;
  final _address = TextEditingController();
  final _focus = FocusNode();
  bool _canBack = false;
  bool _canForward = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_engine != null) return;
    final factory = GizliAlanApp.of(context).browserEngineFactory;
    _engine = factory(onBlocked: _blocked)
      ..url.addListener(_onUrl)
      ..progress.addListener(_onProgress);
  }

  BrowserEngine get _e => _engine!;

  void _blocked(String url) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(L10n.current('browserBlockedLink'))));
  }

  void _onUrl() {
    if (!_focus.hasFocus) _address.text = _e.url.value;
    _refreshNav();
  }

  void _onProgress() {
    if (mounted) setState(() {});
    if (_e.progress.value >= 100) _refreshNav();
  }

  Future<void> _refreshNav() async {
    final b = await _e.canGoBack();
    final f = await _e.canGoForward();
    if (mounted) {
      setState(() {
        _canBack = b;
        _canForward = f;
      });
    }
  }

  Future<void> _go(String input) async {
    final uri = BrowserLogic.resolve(
      input,
      GizliAlanApp.of(context).settings.browserSearchEngine,
    );
    if (uri == null) return;
    _focus.unfocus();
    _address.text = uri.toString();
    setState(() => _started = true);
    await _e.load(uri);
  }

  @override
  void dispose() {
    _engine
      ?..url.removeListener(_onUrl)
      ..progress.removeListener(_onProgress)
      ..dispose();
    _address.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final loading = _started && _e.progress.value < 100;
    return PopScope(
      canPop: !_canBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _canBack) _e.goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: TextField(
            key: const ValueKey('browser_address'),
            controller: _address,
            focusNode: _focus,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            enableSuggestions: false,
            // No personalised learning of typed addresses by the keyboard.
            enableIMEPersonalizedLearning: false,
            decoration: InputDecoration(
              hintText: t('browserHint'),
              isDense: true,
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
            ),
            onSubmitted: _go,
          ),
          bottom: loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    value: _e.progress.value / 100,
                  ),
                )
              : null,
        ),
        body: _started ? _e.view() : _StartPage(engine: _engineLabel()),
        bottomNavigationBar: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                key: const ValueKey('browser_back'),
                tooltip: t('browserBack'),
                icon: const Icon(Icons.arrow_back),
                onPressed: _canBack ? () => _e.goBack() : null,
              ),
              IconButton(
                key: const ValueKey('browser_forward'),
                tooltip: t('browserForward'),
                icon: const Icon(Icons.arrow_forward),
                onPressed: _canForward ? () => _e.goForward() : null,
              ),
              IconButton(
                key: const ValueKey('browser_reload'),
                tooltip: t('browserReload'),
                icon: const Icon(Icons.refresh),
                onPressed: _started ? () => _e.reload() : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _engineLabel() =>
      GizliAlanApp.of(context).settings.browserSearchEngine.label;
}

class _StartPage extends StatelessWidget {
  const _StartPage({required this.engine});

  final String engine;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        const Icon(Icons.travel_explore, size: 56, color: GizliTheme.mint),
        const SizedBox(height: 16),
        Text(
          t('browser'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          t('browserSearchWith').replaceAll('{engine}', engine),
          textAlign: TextAlign.center,
          style: const TextStyle(color: GizliTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        Text(
          t('browserPrivacyNote'),
          key: const ValueKey('browser_privacy_note'),
          style: const TextStyle(
            color: GizliTheme.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
