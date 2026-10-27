import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../services/joi_service.dart';
import '../theme.dart';
import '../widgets/quick_lock.dart';
import 'note_edit_screen.dart';

class _Msg {
  _Msg(
    this.fromUser,
    this.text, {
    this.notes = const [],
    this.query = '',
    this.online,
    this.debug,
  });

  /// Small grey debug line (error class / detail).
  final String? debug;
  final bool fromUser;

  /// AI answers: true = online (Gemini over internet), false = on device.
  final bool? online;
  final String text;
  final List<Note> notes; // local search hits (tappable)
  final String query;
}

/// "Joi" box (0.6.2): on-device assistant. Chat lives in memory only and is
/// dropped when the screen closes / the vault locks.
class JoiScreen extends StatefulWidget {
  const JoiScreen({
    super.key,
    this.service,
    this.summarize,
    this.consent,
    this.setConsent,
  });

  final JoiService? service;

  /// Test hooks for the online consent (default: SettingsService).
  final bool Function()? consent;
  final Future<void> Function(bool)? setConsent;

  /// Opens directly with a summary of this note.
  final Note? summarize;

  @override
  State<JoiScreen> createState() => _JoiScreenState();
}

class _JoiScreenState extends State<JoiScreen> {
  GizliColors get gc => GizliColors.of(context);
  late final JoiService _joi =
      widget.service ?? JoiService(hasOnlineConsent: _hasConsent);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  JoiStatus? _status;
  bool _busy = false;
  bool _notesMode = false;

  bool _hasConsent() {
    final c = widget.consent;
    if (c != null) return c();
    final app = context.findAncestorStateOfType<GizliAlanAppState>();
    return app?.settings.joiOnlineConsent ?? false;
  }

  Future<void> _storeConsent(bool v) async {
    final c = widget.setConsent;
    if (c != null) return c(v);
    final app = context.findAncestorStateOfType<GizliAlanAppState>();
    await app?.settings.setJoiOnlineConsent(v);
  }

  /// One-time consent before the first online question.
  Future<bool> _ensureConsent() async {
    if (_hasConsent()) return true;
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('joi_consent'),
        title: Text(t('joiConsentTitle')),
        content: SingleChildScrollView(child: Text(t('joiConsentBody'))),
        actions: [
          TextButton(
            key: const ValueKey('joi_consent_deny'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('joiConsentDeny')),
          ),
          FilledButton(
            key: const ValueKey('joi_consent_allow'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('joiConsentAllow')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _storeConsent(true);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final s = await _joi.status();
    if (!mounted) return;
    setState(() => _status = s);
    final n = widget.summarize;
    if (n != null && s == JoiStatus.available && _joi.noteFeatures) {
      _summarize(n);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _ai => _status == JoiStatus.available;

  /// AI answers come from the online backend (general questions only).
  bool get _online => _ai && _joi.isOnline;

  /// Gemini Nano on the device: note features available.
  bool get _nano => _ai && _joi.noteFeatures;

  Future<List<Note>> _notes() async =>
      await context
          .findAncestorStateOfType<GizliAlanAppState>()
          ?.session
          ?.notes
          .list() ??
      const <Note>[];

  void _add(_Msg m) {
    setState(() => _msgs.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final t = L10n.current;
    final q = _input.text.trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    _add(_Msg(true, q));
    setState(() => _busy = true);
    try {
      final all = await _notes();
      final hits = JoiNoteSearch.search(all, q);
      var search = !_ai || (_online && _notesMode);
      if (!search && _online && !await _ensureConsent()) {
        if (!mounted) return;
        _add(_Msg(false, t('joiNoConsent')));
        search = true;
      }
      if (search) {
        // Every device: local keyword search over decrypted notes.
        _add(
          _Msg(
            false,
            hits.isEmpty ? t('joiNoMatch') : t('joiFoundNotes'),
            notes: hits,
            query: q,
          ),
        );
        return;
      }
      if (_online) {
        // ONLY the question goes out — never notes (JoiService.ask).
        // Streaming: one bubble updated as words arrive.
        final idx = _msgs.length;
        _add(_Msg(false, '…', online: true));
        final a = await _joi.ask(
          q,
          lang: L10n.lang,
          onPartial: (p) {
            if (mounted && idx < _msgs.length) {
              setState(() => _msgs[idx] = _Msg(false, p, online: true));
            }
          },
        );
        if (!mounted || idx >= _msgs.length) return;
        setState(
          () => _msgs[idx] = a.text != null
              ? _Msg(false, a.text!, online: true)
              : _Msg(false, switch (a.error) {
                  JoiOnlineError.timeout => t('joiTimeout'),
                  JoiOnlineError.quota => t('joiBusy'),
                  JoiOnlineError.server => t('joiServer'),
                  JoiOnlineError.auth => t('joiAuth'),
                  JoiOnlineError.model => t('joiModelErr'),
                  JoiOnlineError.offline => t('joiOffline'),
                  JoiOnlineError.noConsent => t('joiNoConsent'),
                  _ => t('joiError'),
                }, debug: a.detail ?? a.error?.name),
        );
        return;
      }
      final ctx = _notesMode
          ? (hits.isEmpty ? all.take(5).toList() : hits)
          : const <Note>[];
      final a = await _joi.ask(q, lang: L10n.lang, notes: ctx);
      _add(
        _Msg(
          false,
          a.text ?? t('joiError'),
          notes: _notesMode ? hits : const [],
          query: q,
          online: a.text == null ? null : false,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _summarize(Note n) async {
    final t = L10n.current;
    if (!_joi.noteFeatures) return; // notes never go online
    final title = n.title.isEmpty ? t('untitled') : n.title;
    _add(_Msg(true, t('joiSummarizeAsk').replaceAll('{title}', title)));
    setState(() => _busy = true);
    final r = await _joi.generate(
      JoiService.summarizePrompt(n, lang: L10n.lang),
    );
    if (!mounted) return;
    _add(_Msg(false, r ?? t('joiError'), online: r == null ? null : false));
    setState(() => _busy = false);
  }

  Future<void> _pickNoteToSummarize() async {
    final t = L10n.current;
    final notes = await _notes();
    if (!mounted) return;
    if (notes.isEmpty) {
      _add(_Msg(false, t('emptyNotes')));
      return;
    }
    final n = await showModalBottomSheet<Note>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final n in notes)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(n.title.isEmpty ? t('untitled') : n.title),
                onTap: () => Navigator.pop(ctx, n),
              ),
          ],
        ),
      ),
    );
    if (n != null && mounted) _summarize(n);
  }

  Future<void> _download() async {
    setState(() => _status = JoiStatus.downloading);
    await _joi.download();
    await _checkStatus();
  }

  Widget _statusCard(L10n t) {
    final s = _status;
    if (s == null || _nano) return const SizedBox.shrink();
    final text = _online
        ? t('joiOnlineNote')
        : switch (s) {
            JoiStatus.downloadable => t('joiDownloadable'),
            JoiStatus.downloading => t('joiDownloading'),
            _ => t('joiUnavailable'),
          };
    return Card(
      key: const ValueKey('joi_status'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: gc.textSecondary)),
            if (s == JoiStatus.downloadable)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _download,
                  child: Text(t('joiDownload')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m, L10n t) {
    final bg = m.fromUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.online != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      m.online! ? Icons.cloud_outlined : Icons.phone_android,
                      size: 14,
                      color: gc.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t(m.online! ? 'joiBadgeOnline' : 'joiBadgeDevice'),
                      key: ValueKey(
                        m.online! ? 'joi_badge_online' : 'joi_badge_device',
                      ),
                      style: TextStyle(fontSize: 11, color: gc.textSecondary),
                    ),
                  ],
                ),
              ),
            SelectableText(m.text),
            if (m.debug != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  m.debug!,
                  key: const ValueKey('joi_debug'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: gc.textSecondary),
                ),
              ),
            for (final n in m.notes)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sticky_note_2_outlined, size: 20),
                title: Text(n.title.isEmpty ? t('untitled') : n.title),
                subtitle: Text(
                  JoiNoteSearch.snippet(n, m.query),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  final repo = GizliAlanApp.of(context).session!.notes;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NoteEditScreen(repo: repo, note: n),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(JoiService.name, key: ValueKey('joi_title')),
        actions: const [QuickLockButton()],
      ),
      body: Column(
        children: [
          _statusCard(t),
          Expanded(
            child: _msgs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _online
                            ? t('joiIntroOnline')
                            : _ai || _status == null
                            ? t('joiIntro')
                            : t('joiIntroSearch'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: gc.textSecondary),
                      ),
                    ),
                  )
                : ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [for (final m in _msgs) _bubble(m, t)],
                  ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          if (_ai)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    key: const ValueKey('joi_notes_mode'),
                    label: Text(
                      _online ? t('joiSearchNotes') : t('joiAskNotes'),
                    ),
                    selected: _notesMode,
                    onSelected: (v) => setState(() => _notesMode = v),
                  ),
                  if (_nano)
                    ActionChip(
                      label: Text(t('joiSummarize')),
                      onPressed: _busy ? null : _pickNoteToSummarize,
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('joi_input'),
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _ai && !(_online && _notesMode)
                            ? t('joiHint')
                            : t('joiHintSearch'),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('joi_send'),
                    tooltip: t('joiSend'),
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
