import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../services/joi_service.dart';
import '../services/joi_tools.dart';
import '../services/pro_entitlement.dart';
import '../widgets/pro_gate.dart';
import '../theme.dart';
import '../services/joi_memory.dart';
import '../services/joi_quota.dart';
import '../services/app_actions.dart';
import 'joi_memory_screen.dart';
import '../widgets/joi_avatar.dart';
import '../widgets/joi_markdown.dart';
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
    this.private = false,
    this.noteId,
    this.images = const [],
    this.saveFirst = false,
    this.memory = false,
    this.voiceHelp = false,
  });

  factory _Msg.fromChat(JoiChatMsg c) => _Msg(
    c.fromUser,
    c.text,
    online: c.online,
    private: c.private,
    noteId: c.noteId,
  );

  JoiChatMsg toChat() => JoiChatMsg(
    fromUser: fromUser,
    text: text,
    online: online,
    // Note search hits are derived from notes: never online context.
    private: private || notes.isNotEmpty,
    noteId: noteId,
  );

  /// Derived from notes (never sent online as context).
  final bool private;

  /// A note Joi created (shows "open note").
  final String? noteId;

  /// Wikimedia Commons results (not persisted).
  final List<CommonsImage> images;

  /// Show buttons to install Google speech services (Play).
  final bool voiceHelp;

  /// "Joi bunu hatırladı" chip (text = the saved facts).
  final bool memory;

  /// Explicit "indir": show the "İlkini galeriye kaydet" button.
  final bool saveFirst;

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
    this.chatStore,
    this.voice,
    this.commons,
    this.platform,
    this.createNote,
    this.isPro,
    this.memoryStore,
    this.memoryEnabled,
    this.quota,
  });

  /// Test hook for the free daily quota (default: SettingsService).
  final JoiDailyQuota? quota;

  /// Test hook for the Pro entitlement (default: [ProEntitlement]).
  final bool Function()? isPro;

  /// Test hooks (defaults: the vault session / platform channels).
  final JoiChatStore? chatStore;
  final JoiMemoryStore? memoryStore;
  final bool Function()? memoryEnabled;
  final JoiVoice? voice;
  final CommonsSearch? commons;
  final JoiPlatform? platform;
  final Future<String?> Function(String title, String body)? createNote;

  final JoiService? service;

  /// Test hooks for the online consent (default: SettingsService).
  final bool Function()? consent;
  final Future<void> Function(bool)? setConsent;

  /// Opens directly with a summary of this note.
  final Note? summarize;

  @override
  State<JoiScreen> createState() => _JoiScreenState();
}

/// User bubble: calm, desaturated teal with near-white text (WCAG AA:
/// ~9:1). Was the bright accent primaryContainer (#7CFFB2) with light text.
const Color _userBubble = Color(0xFF24493F);
const Color _userText = Color(0xFFF1F5F9);

class _JoiScreenState extends State<JoiScreen> with WidgetsBindingObserver {
  // The Joi screen is always dark (portrait wallpaper), in every theme mode.
  GizliColors get gc => GizliColors.dark;
  late final JoiService _joi =
      widget.service ?? JoiService(hasOnlineConsent: _hasConsent);
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  JoiStatus? _status;
  bool _busy = false;
  bool _notesMode = false;
  late final JoiVoice _voice = widget.voice ?? JoiVoice();
  late final CommonsSearch _commons = widget.commons ?? CommonsSearch();
  late final JoiPlatform _platform = widget.platform ?? const JoiPlatform();
  bool _listening = false;
  String _partial = '';
  bool _speaking = false;
  bool _historyLoaded = false;

  GizliAlanAppState? get _app =>
      context.findAncestorStateOfType<GizliAlanAppState>();

  JoiChatStore? get _store => widget.chatStore ?? _app?.session?.joiChat;

  /// Free: plain Q&A only. Pro: notes, photos, note writing, voice,
  /// persistent history (owner decision 0.6.2).
  bool get _pro {
    final f = widget.isPro;
    if (f != null) return f();
    final a = _app;
    return a != null && ProEntitlement.isActive(a.settings);
  }

  /// Free tier: 10 online messages per day (null = unlimited / Pro).
  JoiDailyQuota? get _quota =>
      _pro ? null : (widget.quota ?? _app?.settings.joiQuota);

  bool get _speakOn => _pro && (_app?.settings.joiSpeak ?? false);

  // ------------------------------------------------------------ memory
  JoiMemoryStore? get _memStore =>
      widget.memoryStore ?? _app?.session?.joiMemory;

  bool get _memOn =>
      _pro &&
      _memStore != null &&
      (widget.memoryEnabled?.call() ?? _app?.settings.joiMemory ?? false);

  JoiMemoryEngine? _engineCache;
  JoiMemoryEngine? get _engine {
    final st = _memStore;
    if (st == null) return null;
    return _engineCache ??= JoiMemoryEngine(st, _joi);
  }

  List<JoiChatMsg> _chatList() => [
    for (final m in _msgs)
      if (m.text != '…' && !m.memory) m.toChat(),
  ];

  /// Extraction/summaries after an exchange or on pause/exit ([force]).
  Future<void> _memorize({bool force = false}) async {
    if (!_memOn) return;
    final e = _engine;
    if (e == null) return;
    final added = await e.process(_chatList(), force: force);
    if (added.isEmpty || !mounted) return;
    _add(_Msg(false, added.map((f) => f.text).join(' · '), memory: true));
    _persist();
  }

  Future<String> _memoryBlock(String q) async {
    if (!_memOn) return '';
    try {
      return await _engine!.block(q);
    } catch (_) {
      return '';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _memorize(force: true);
    }
  }

  Future<void> _openMemory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JoiMemoryScreen(
          store: _memStore,
          isPro: widget.isPro,
          enabled: widget.memoryEnabled,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Shows the Pro upsell (and a short chat line) for a Pro-only action.
  Future<void> _upsell(String what) async {
    final t = L10n.current;
    _add(_Msg(false, t('joiProOnly').replaceAll('{what}', what)));
    await showProRequired(
      context,
      title: t('joiProTitle'),
      body: t('joiProBody'),
    );
  }

  Future<void> _loadHistory() async {
    final st = _pro ? _store : null; // free: history only while open
    final h = st == null ? const <JoiChatMsg>[] : await st.load();
    if (!mounted) return;
    setState(() {
      _msgs.insertAll(0, h.map(_Msg.fromChat));
      _historyLoaded = true;
    });
    _toBottom(jump: true);
  }

  Future<void> _persist() async {
    final st = _store;
    if (st == null || !_historyLoaded || !_pro) return;
    try {
      await st.save([
        for (final m in _msgs)
          if (m.text != '…' && !m.memory) m.toChat(),
      ]);
    } catch (_) {}
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(max);
      } else {
        _scroll.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('joi_clear_confirm'),
        title: Text(t('joiClear')),
        content: Text(t('joiClearBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('joi_clear_ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('joiClearOk')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Memories are separate: clearing the chat keeps them.
    await _memorize(force: true);
    await _store?.clear();
    await _memStore?.chatCleared();
    if (mounted) setState(_msgs.clear);
  }

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
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
  void deactivate() {
    // Conversation exit: extract facts from what is left (async; the
    // store/engine are resolved now, while ancestors are still reachable).
    _memorize(force: true);
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll.dispose();
    if (_speaking) _voice.stopSpeaking();
    if (_listening) _voice.stopListening();
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
    _toBottom();
    _persist();
  }

  String _errText(L10n t, JoiOnlineError? e) => switch (e) {
    JoiOnlineError.timeout => t('joiTimeout'),
    JoiOnlineError.quota => t('joiBusy'),
    JoiOnlineError.server => t('joiServer'),
    JoiOnlineError.auth => t('joiAuth'),
    JoiOnlineError.model => t('joiModelErr'),
    JoiOnlineError.offline => t('joiOffline'),
    JoiOnlineError.noConsent => t('joiNoConsent'),
    _ => t('joiError'),
  };

  /// Online context: last 20 non-private turns (never notes).
  List<Map<String, String>> _history() => joiOnlineHistory([
    for (final m in _msgs)
      if (m.text != '…') m.toChat(),
  ]);

  Future<void> _speakIfWanted(String? text, bool viaVoice) async {
    if (text == null || text.isEmpty || !_pro || !(viaVoice || _speakOn)) {
      return;
    }
    setState(() => _speaking = true);
    await _voice.speak(JoiMarkdown.plain(text), L10n.lang);
    if (mounted) setState(() => _speaking = false);
  }

  /// Last image request (for "niye inmedi" follow-ups).
  JoiImageSearch? _lastImage;

  /// Joi asked "Neyin fotoğrafını indireyim?": the next message is the subject.
  bool _awaitSubject = false;

  /// Resolves the subject of an image request from the chat: the online
  /// classifier first (structured JSON), then a local heuristic.
  Future<String?> _resolveSubject(
    String q,
    List<Map<String, String>> history,
  ) async {
    if (_online && _hasConsent()) {
      try {
        final c = await _joi
            .classifyImage(q, history: history)
            .timeout(const Duration(seconds: 10));
        if (c != null && c.isImage && c.query != null) return c.query;
      } catch (_) {}
    }
    return JoiIntent.topicFromHistory(history);
  }

  Future<void> _send({String? text, bool viaVoice = false}) async {
    final t = L10n.current;
    final q = (text ?? _input.text).trim();
    if (q.isEmpty || _busy) return;
    _input.clear();
    // History (last turns) is taken BEFORE adding this question.
    final history = _history();
    _add(_Msg(true, q));
    setState(() => _busy = true);
    String? spoken;
    try {
      var intent = JoiIntent.parse(q);
      if (_awaitSubject) {
        _awaitSubject = false;
        intent ??= JoiImageSearch(q);
      }
      if (intent is JoiImageFollowUp) {
        intent = _lastImage ?? const JoiImageNeedsSubject();
      }
      if (intent == null &&
          _pro &&
          JoiIntent.hasImageWords(q) &&
          _online &&
          _hasConsent()) {
        // Regex unsure but image words present: ask the classifier.
        try {
          final c = await _joi
              .classifyImage(q, history: history)
              .timeout(const Duration(seconds: 10));
          if (c != null && c.isImage) {
            intent = c.query == null
                ? const JoiImageNeedsSubject()
                : JoiImageSearch(
                    c.query!,
                    explicit: RegExp(
                      r'(indir|download|kaydet|save)',
                    ).hasMatch(q.toLowerCase()),
                  );
          }
        } catch (_) {}
      }
      if (intent != null && !_pro) {
        // Tool intents are Pro-only: never executed for free users.
        await _upsell(
          intent is JoiWriteNote ? t('joiProWrite') : t('joiProPhotos'),
        );
        return;
      }
      if (intent is JoiImageNeedsSubject) {
        final subj = await _resolveSubject(q, history);
        if (subj == null) {
          _awaitSubject = true;
          _add(_Msg(false, t('joiImgWhich')));
          spoken = t('joiImgWhich');
          return;
        }
        intent = JoiImageSearch(subj, explicit: intent.explicit);
      }
      if (intent is JoiImageSearch) {
        _lastImage = intent;
        spoken = await _imageSearch(
          intent.query,
          intent.candidates,
          explicit: intent.explicit,
        );
        return;
      }
      if (intent is JoiWriteNote) {
        spoken = await _writeNote(intent);
        return;
      }
      final all = await _notes();
      final hits = JoiNoteSearch.search(all, q);
      if (!_pro && (_notesMode || !_ai)) {
        await _upsell(t('joiProNotes'));
        return;
      }
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
      final quota = _quota;
      if (_online && quota != null && quota.exhausted) {
        _add(_Msg(false, t('joiDailyLimitReached')));
        if (!mounted) return;
        await showProRequired(
          context,
          title: t('joiDailyLimitTitle'),
          body: t('joiDailyLimitBody'),
        );
        return;
      }
      if (_online) {
        // ONLY the question goes out — never notes (JoiService.ask).
        // Streaming: one bubble updated as words arrive.
        final idx = _msgs.length;
        _add(_Msg(false, '…', online: true));
        final memory = await _memoryBlock(q);
        final a = await _joi.ask(
          q,
          lang: L10n.lang,
          history: history,
          memory: memory,
          onPartial: (p) {
            if (mounted && idx < _msgs.length) {
              setState(() => _msgs[idx] = _Msg(false, p, online: true));
            }
          },
        );
        if (!mounted || idx >= _msgs.length) return;
        if (a.text != null && joiClaimsAction(a.text!)) {
          // Hallucination guard: Joi never performs actions itself.
          setState(() => _msgs[idx] = _Msg(false, t('joiNoFakeAction')));
          spoken = t('joiNoFakeAction');
          if (_pro &&
              (JoiIntent.hasImageWords(q) ||
                  JoiIntent.hasImageWords(a.text!))) {
            final subj = await _resolveSubject(q, history);
            if (subj != null && mounted) {
              final i = JoiImageSearch(subj);
              _lastImage = i;
              spoken = await _imageSearch(
                i.query,
                i.candidates,
                explicit: true,
              );
            }
          }
          return;
        }
        setState(
          () => _msgs[idx] = a.text != null
              ? _Msg(false, a.text!, online: true)
              : _Msg(
                  false,
                  _errText(t, a.error),
                  debug: a.detail ?? a.error?.name,
                ),
        );
        spoken = a.text ?? _msgs[idx].text;
        if (a.text != null && quota != null) await quota.consume();
        if (a.text != null) _persist().then((_) => _memorize());
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
          private: _notesMode,
        ),
      );
      spoken = a.text;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _persist();
        _speakIfWanted(spoken, viaVoice);
      }
    }
  }

  // ------------------------------------------------------- image search

  Future<String?> _imageSearch(
    String query,
    List<String> candidates, {
    bool explicit = false,
  }) async {
    final t = L10n.current;
    if (!await _ensureConsent()) {
      if (mounted) _add(_Msg(false, t('joiImgNeedsOnline')));
      return null;
    }
    if (!mounted) return null;
    // "Arıyorum…" bubble, ALWAYS replaced by results or an error.
    final idx = _msgs.length;
    _add(_Msg(false, t('joiImgSearching').replaceAll('{q}', query)));
    _Msg out;
    try {
      final r = await _commons
          .searchAny(candidates)
          .timeout(const Duration(seconds: 25));
      out = _Msg(
        false,
        r.isEmpty
            ? t('joiImgNothing').replaceAll('{q}', query)
            : t('joiImgFound').replaceAll('{q}', query),
        images: r,
        saveFirst: explicit && r.isNotEmpty,
      );
    } catch (e) {
      out = _Msg(
        false,
        joiIsOffline(e) ? t('joiImgOffline') : t('joiImgError'),
        debug: joiDebugName(e),
      );
    }
    if (!mounted) return null;
    setState(() {
      if (idx < _msgs.length) {
        _msgs[idx] = out;
      } else {
        _msgs.add(out);
      }
    });
    _toBottom();
    _persist();
    return out.text;
  }

  Future<void> _openImage(CommonsImage img) async {
    final t = L10n.current;
    final canPictures = await _platform.canSaveToPictures();
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(img.title, maxLines: 2),
              subtitle: Text('${img.author} · ${img.license}'),
            ),
            if (canPictures)
              ListTile(
                key: const ValueKey('joi_img_save_pictures'),
                leading: const Icon(Icons.download_outlined),
                title: Text(t('joiImgSavePictures')),
                onTap: () => Navigator.pop(ctx, 'pictures'),
              ),
            ListTile(
              key: const ValueKey('joi_img_save_vault'),
              leading: const Icon(Icons.lock_outline),
              title: Text(t('joiImgSaveVault')),
              onTap: () => Navigator.pop(ctx, 'vault'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    await _saveImage(img, choice);
  }

  Future<void> _saveImage(CommonsImage img, String choice) async {
    final t = L10n.current;
    if (choice == 'vault' && !await ItemLimit.ensureRoom(context)) return;
    setState(() => _busy = true);
    try {
      final bytes = await _commons.download(img);
      bool ok;
      if (choice == 'pictures') {
        ok =
            await _platform.saveToPictures(
              bytes,
              name: img.fileName,
              mime: img.mime,
              description: img.attribution,
            ) !=
            null;
      } else {
        final s = _app?.session;
        ok = s != null;
        if (s != null) {
          await s.gallery.add(name: img.fileName, bytes: bytes, mime: img.mime);
        }
      }
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              t(
                choice == 'pictures'
                    ? 'joiImgSavedPictures'
                    : 'joiImgSavedVault',
              ),
            ),
          ),
        );
      }
      _add(
        _Msg(
          false,
          ok
              ? '${t(choice == 'pictures' ? 'joiImgSavedPictures' : 'joiImgSavedVault')}\n'
                    '${img.title}\n${t('joiImgCredit')}: ${img.author} · '
                    '${img.license}\n${img.pageUrl}'
              : t('joiImgSaveFailed'),
        ),
      );
    } catch (e) {
      if (mounted) {
        _add(
          _Msg(
            false,
            joiIsOffline(e) ? t('joiOffline') : t('joiImgSaveFailed'),
            debug: joiDebugName(e),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------- write note

  Future<String?> _createNote(String title, String body) async {
    final c = widget.createNote;
    if (c != null) return c(title, body);
    final s = _app?.session;
    if (s == null) return null;
    if (!await ItemLimit.ensureRoom(context)) return null;
    return (await s.notes.create(title: title, body: body)).id;
  }

  Future<String?> _writeNote(JoiWriteNote w) async {
    final t = L10n.current;
    String? content = w.literal;
    var online = false;
    if (content == null) {
      if (!_ai) {
        _add(_Msg(false, t('joiNoteNeedsAi')));
        return null;
      }
      if (_online && !await _ensureConsent()) {
        if (mounted) _add(_Msg(false, t('joiNoConsent')));
        return null;
      }
      online = _online;
      final idx = _msgs.length;
      _add(_Msg(false, '…', online: online, private: true));
      final a = await _joi.writeNoteText(
        w,
        lang: L10n.lang,
        onPartial: (p) {
          if (mounted && idx < _msgs.length) {
            setState(
              () => _msgs[idx] = _Msg(false, p, online: online, private: true),
            );
          }
        },
      );
      if (!mounted) return null;
      if (a.text == null) {
        setState(
          () => _msgs[idx] = _Msg(
            false,
            _errText(t, a.error),
            debug: a.detail ?? a.error?.name,
          ),
        );
        return _msgs[idx].text;
      }
      content = a.text!;
      setState(() => _msgs.removeAt(idx));
    }
    final (title, body) = JoiWriteNote.titleBody(
      content,
      fallback: w.literal != null ? t('joiNoteTitle') : (w.request ?? ''),
    );
    final id = await _createNote(title, body);
    if (!mounted) return null;
    if (id == null) {
      _add(_Msg(false, t('joiNoteFailed')));
      return null;
    }
    final msg = t('joiNoteCreated').replaceAll('{title}', title);
    _add(
      _Msg(
        false,
        '$msg\n\n$body',
        online: w.literal != null ? null : online,
        private: true,
        noteId: id,
      ),
    );
    return msg;
  }

  Future<void> _openNote(String id) async {
    final s = _app?.session;
    if (s == null) return;
    final n = (await s.notes.list()).where((n) => n.id == id).firstOrNull;
    if (n == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(repo: s.notes, note: n),
      ),
    );
  }

  // --------------------------------------------------------------- voice

  Future<void> _mic() async {
    final t = L10n.current;
    if (!_pro) return _upsell(t('joiProVoice'));
    if (_listening) {
      await _voice.stopListening();
      return;
    }
    if (_speaking) {
      await _voice.stopSpeaking();
      setState(() => _speaking = false);
    }
    if (!await _voice.hasPermission()) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: const ValueKey('joi_mic_rationale'),
          title: Text(t('joiMicTitle')),
          content: Text(t('joiMicBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t('joiMicContinue')),
            ),
          ],
        ),
      );
      if (go != true) return;
      if (!await _voice.requestPermission()) {
        if (mounted) _add(_Msg(false, t('joiMicDenied')));
        return;
      }
    }
    setState(() => _listening = true);
    _voice.onPartial = (p) {
      if (mounted) setState(() => _partial = p);
    };
    setState(() => _partial = '');
    String? heard;
    try {
      heard = await _voice.listen(L10n.lang);
    } on PlatformException catch (e) {
      if (mounted) {
        _add(
          _Msg(
            false,
            voiceErrorText(t, e.code),
            debug: 'voice [${e.code}]: ${e.message ?? '-'}',
            voiceHelp: e.code == 'no_service' || e.code == 'unavailable',
          ),
        );
      }
    } catch (e) {
      // MissingPluginException etc.: never silent, show the type.
      if (mounted) {
        _add(
          _Msg(
            false,
            '${t('joiVoiceException')} (${t('joiVoiceCode')} ${e.runtimeType})',
            debug: 'voice: $e',
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      _partial = '';
    });
    if (heard != null && heard.trim().isNotEmpty) {
      await _send(text: heard, viaVoice: true);
    }
  }

  // ------------------------------------------------------------ examples

  /// (text, Pro-only). Tapping sends the example directly.
  List<(String, bool)> _examples(L10n t) => [
    (t('joiEx4'), false),
    (t('joiEx5'), false),
    (t('joiEx1'), true),
    (t('joiEx2'), true),
    (t('joiEx3'), true),
    (t('joiEx6'), true),
    if (_nano) (t('joiExNotes'), true),
  ];

  Widget _empty(L10n t) {
    final intro = _online
        ? t('joiIntroOnline')
        : _ai || _status == null
        ? t('joiIntro')
        : t('joiIntroSearch');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      children: [
        Text(
          intro,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, height: 1.35),
        ),
        if (_ai) ...[
          const SizedBox(height: 18),
          Text(
            t('joiTry'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, (e, pro)) in _examples(t).indexed)
                ActionChip(
                  key: ValueKey('joi_example_$i'),
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                  side: const BorderSide(color: Color(0x88FF8FD8)),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          e,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      if (pro && !_pro) ...[
                        const SizedBox(width: 6),
                        const _ProBadge(),
                      ],
                    ],
                  ),
                  onPressed: _busy ? null : () => _send(text: e),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _summarize(Note n) async {
    final t = L10n.current;
    if (!_joi.noteFeatures) return; // notes never go online
    if (!_pro) return _upsell(t('joiProNotes'));
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
    if (!_pro) return _upsell(t('joiProNotes'));
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
            // Once the chat has messages the note collapses to one line so
            // it never covers the conversation (tap to read it all).
            _msgs.isEmpty || s == JoiStatus.downloadable
                ? Text(text, style: TextStyle(color: gc.textSecondary))
                : InkWell(
                    key: const ValueKey('joi_status_compact'),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: Text(text),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(t('updOk')),
                          ),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: gc.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: gc.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  /// Play AI-Generated Content policy: users can flag any Joi answer.
  /// Opens the user's mail app to our support address with the reason and
  /// ONLY the reported Joi answer (no notes, no logs, no device data). The
  /// user sees and sends the mail themselves.
  Future<void> _report(_Msg m) async {
    final t = L10n.current;
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          key: const ValueKey('joi_report_sheet'),
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t('joiReportTitle'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(t('joiReportInfo')),
            ),
            for (final k in const [
              'joiReportHarmful',
              'joiReportSexual',
              'joiReportWrong',
              'joiReportOther',
            ])
              ListTile(
                key: ValueKey('joi_report_$k'),
                leading: const Icon(Icons.flag_outlined),
                title: Text(t(k)),
                onTap: () => Navigator.pop(ctx, t(k)),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final ok = await AppActions.sendFeedback(
      'GizliAlan Joi bildirimi: $reason',
      body: '${t('joiReportMailIntro')}\n\n"${m.text}"',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t(ok ? 'joiReportThanks' : 'joiReportFailed'))),
    );
  }

  Widget _bubble(_Msg m, L10n t) {
    if (m.memory) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            key: const ValueKey('joi_memory_chip'),
            avatar: const Icon(Icons.psychology_outlined, size: 18),
            label: Text(
              '${t('joiMemorySaved')}: ${m.text}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: _openMemory,
          ),
        ),
      );
    }
    final bg = m.fromUser
        ? _userBubble
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final bubble = Container(
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
          if (m.fromUser)
            SelectableText(m.text, style: const TextStyle(color: _userText))
          else
            JoiMarkdown(m.text),
          if (!m.fromUser && m.online != null && m.text != '…')
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('joi_report'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: gc.textSecondary,
                ),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: Text(
                  t('joiReport'),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () => _report(m),
              ),
            ),
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
          if (m.noteId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('joi_open_note'),
                icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                label: Text(t('joiOpenNote')),
                onPressed: () => _openNote(m.noteId!),
              ),
            ),
          if (m.voiceHelp)
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const ValueKey('joi_voice_open_google'),
                  icon: const Icon(Icons.shop_outlined, size: 18),
                  label: Text(t('joiVoiceOpenGoogle')),
                  onPressed: () => _voice.openStore(
                    'com.google.android.googlequicksearchbox',
                  ),
                ),
                TextButton.icon(
                  key: const ValueKey('joi_voice_open_speech'),
                  icon: const Icon(Icons.shop_outlined, size: 18),
                  label: Text(t('joiVoiceOpenSpeech')),
                  onPressed: () => _voice.openStore('com.google.android.tts'),
                ),
              ],
            ),
          if (m.saveFirst && m.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton.icon(
                key: const ValueKey('joi_img_save_first'),
                icon: const Icon(Icons.download),
                label: Text(t('joiImgSaveFirst')),
                onPressed: _busy
                    ? null
                    : () async {
                        final p = await _platform.canSaveToPictures();
                        await _saveImage(
                          m.images.first,
                          p ? 'pictures' : 'vault',
                        );
                      },
              ),
            ),
          if (m.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, img) in m.images.indexed)
                    SizedBox(
                      width: 140,
                      child: InkWell(
                        key: ValueKey('joi_img_$i'),
                        onTap: () => _openImage(img),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                img.thumbUrl,
                                width: 140,
                                height: 100,
                                fit: BoxFit.cover,
                                cacheWidth: 420,
                                headers: const {
                                  'User-Agent': CommonsSearch.userAgent,
                                },
                                errorBuilder: (_, _, _) => Container(
                                  width: 140,
                                  height: 100,
                                  color: Colors.black26,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            Text(
                              img.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            Text(
                              '${img.author} · ${img.license}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: gc.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
    );
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: m.fromUser
          ? bubble
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10, top: 6),
                  child: JoiAvatar(size: 26),
                ),
                Flexible(child: bubble),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    // Joi portrait as wallpaper, darkened (~62 % black + gradient) so
    // bubbles and text stay readable.
    return Theme(
      data: GizliTheme.dark(),
      child: Container(
        key: const ValueKey('joi_wallpaper'),
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            image: const AssetImage('assets/joi/joi_512.webp'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.62),
              BlendMode.darken,
            ),
            onError: (_, _) {},
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
          child: _scaffold(t),
        ),
      ),
    );
  }

  /// "Bugün 7/10" + "Pro'ya geç" (free tier only).
  Widget _quotaBar(L10n t, JoiDailyQuota q) => Padding(
    key: const ValueKey('joi_quota_bar'),
    padding: const EdgeInsets.fromLTRB(12, 4, 6, 0),
    child: Row(
      children: [
        Icon(Icons.chat_bubble_outline, size: 16, color: gc.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            t('joiQuotaToday').replaceAll('{n}', q.label),
            key: const ValueKey('joi_quota_label'),
            style: TextStyle(
              fontSize: 13,
              color: q.exhausted ? const Color(0xFFFF8FD8) : gc.textSecondary,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('joi_quota_pro'),
          onPressed: () => openPro(context),
          child: Text(t('joiGoPro')),
        ),
      ],
    ),
  );

  Widget _scaffold(L10n t) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        title: const Row(
          children: [
            JoiAvatar(size: 36),
            SizedBox(width: 10),
            Text(JoiService.name, key: ValueKey('joi_title')),
          ],
        ),
        actions: [
          if (_speaking)
            IconButton(
              key: const ValueKey('joi_stop_speaking'),
              tooltip: t('joiStopSpeaking'),
              icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () async {
                await _voice.stopSpeaking();
                if (mounted) setState(() => _speaking = false);
              },
            )
          else
            IconButton(
              key: const ValueKey('joi_speak_toggle'),
              tooltip: t('joiSpeakToggle'),
              icon: Icon(
                _speakOn ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              ),
              onPressed: () async {
                if (!_pro) return _upsell(t('joiProVoice'));
                await _app?.settings.setJoiSpeak(!_speakOn);
                if (mounted) setState(() {});
              },
            ),
          PopupMenuButton<String>(
            key: const ValueKey('joi_menu'),
            onSelected: (v) {
              if (v == 'clear') _clearChat();
              if (v == 'memory') _openMemory();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                key: const ValueKey('joi_menu_memory'),
                value: 'memory',
                child: Text(t('joiMemoryTitle')),
              ),
              PopupMenuItem(
                key: const ValueKey('joi_menu_clear'),
                value: 'clear',
                child: Text(t('joiClear')),
              ),
            ],
          ),
          const QuickLockButton(),
        ],
      ),
      body: Column(
        children: [
          _statusCard(t),
          if (_quota != null && _online) _quotaBar(t, _quota!),
          Expanded(
            child: _msgs.isEmpty
                ? _empty(t)
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
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_online ? t('joiSearchNotes') : t('joiAskNotes')),
                        if (!_pro) ...[
                          const SizedBox(width: 6),
                          const _ProBadge(),
                        ],
                      ],
                    ),
                    selected: _notesMode,
                    onSelected: (v) {
                      if (!_pro) {
                        _upsell(t('joiProNotes'));
                        return;
                      }
                      setState(() => _notesMode = v);
                    },
                  ),
                  if (_nano)
                    ActionChip(
                      label: Text(t('joiSummarize')),
                      onPressed: _busy ? null : _pickNoteToSummarize,
                    ),
                ],
              ),
            ),
          if (_listening)
            Container(
              key: const ValueKey('joi_listening'),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x88FF8FD8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.graphic_eq, color: Color(0xFFFF8FD8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _partial.isEmpty ? t('joiListening') : _partial,
                      style: const TextStyle(color: Colors.white),
                    ),
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
                  // Tap = start/stop; press-and-hold = talk while held,
                  // sends on release.
                  Tooltip(
                    message: t('joiMic'),
                    child: GestureDetector(
                      key: const ValueKey('joi_mic'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _busy ? null : _mic,
                      onLongPressStart: _busy || _listening
                          ? null
                          : (_) => _mic(),
                      onLongPressEnd: (_) {
                        if (_listening) _voice.stopListening();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: _listening
                              ? const Color(0xFFFF8FD8)
                              : Colors.transparent,
                          child: Icon(
                            _listening ? Icons.mic : Icons.mic_none,
                            color: _listening ? Colors.black : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('joi_send'),
                    tooltip: t('joiSend'),
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : () => _send(),
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

class _ProBadge extends StatelessWidget {
  const _ProBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: const Color(0xFFFFC857),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'Pro',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
  );
}

/// Turkish/EN message per speech-recognition error code (VoiceChannel.kt).
/// Turkish message for a voice error; numeric recogniser errors ("e7")
/// get a distinct text plus "(kod 7)" so bug reports show the cause.
String voiceErrorText(L10n t, String code) {
  final m = RegExp(r'^e(\d+)$').firstMatch(code);
  if (m != null) {
    final n = int.parse(m.group(1)!);
    final key = (n >= 1 && n <= 13) ? 'joiVoiceE$n' : 'joiVoiceEOther';
    return '${t(key)} (${t('joiVoiceCode')} $n)';
  }
  if (code.startsWith('x:')) {
    // Native exception in the recogniser chain: show its type.
    return '${t('joiVoiceException')} (${t('joiVoiceCode')} ${code.substring(2)})';
  }
  return switch (code) {
    'no_match' => t('joiVoiceNoMatch'),
    'offline' => t('joiVoiceOffline'),
    'no_permission' => t('joiMicDenied'),
    'busy' => t('joiVoiceBusy'),
    'language' => t('joiVoiceLanguage'),
    'unavailable' || 'no_service' => t('joiVoiceNoService'),
    'dialog_cancel' => t('joiVoiceDialogCancel'),
    _ => '${t('joiMicError')} (${t('joiVoiceCode')} $code)',
  };
}
