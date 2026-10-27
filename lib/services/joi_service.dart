import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';

/// Availability of Gemini Nano (AICore) on this device.
enum JoiStatus { available, downloadable, downloading, unavailable }

/// "Joi" — GizliAlan's on-device assistant (0.6.2).
///
/// Note content never leaves the device: note features run only on Gemini
/// Nano (ML Kit GenAI Prompt API inside Android AICore, JoiChannel.kt). On
/// phones without Nano, general questions may go to the opt-in online
/// backend ([JoiOnlineBackend], consent required); notes stay with
/// [JoiNoteSearch] (local keyword search).
/// One model backend for Joi.
abstract class JoiBackend {
  String get id;
  Future<JoiStatus> status();
  Future<bool> download();
  Future<String?> generate(String prompt);
}

/// Gemini Nano via ML Kit GenAI Prompt API / AICore (JoiChannel.kt).
/// Only on supported flagships (e.g. Pixel 9+, recent Galaxy S/Fold);
/// elsewhere it reports [JoiStatus.unavailable].
class NanoBackend implements JoiBackend {
  NanoBackend({MethodChannel? channel})
    : _ch = channel ?? const MethodChannel('gizlialan/joi');

  final MethodChannel _ch;

  @override
  String get id => 'gemini_nano';

  @override
  Future<JoiStatus> status() async {
    try {
      final s = await _ch.invokeMethod<String>('status');
      return switch (s) {
        'available' => JoiStatus.available,
        'downloadable' => JoiStatus.downloadable,
        'downloading' => JoiStatus.downloading,
        _ => JoiStatus.unavailable,
      };
    } catch (e) {
      debugPrint('joi status: $e');
      return JoiStatus.unavailable;
    }
  }

  /// Asks AICore to fetch Gemini Nano (system download; no user text sent).
  @override
  Future<bool> download() async {
    try {
      return await _ch.invokeMethod<bool>('download') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> generate(String prompt) async {
    try {
      final r = await _ch.invokeMethod<String>('generate', {'prompt': prompt});
      final s = r?.trim();
      return (s == null || s.isEmpty) ? null : s;
    } catch (e) {
      debugPrint('joi generate failed');
      return null;
    }
  }
}

/// Build-time config for the opt-in online backend (Firebase AI Logic,
/// Gemini Developer API). Injected with `--dart-define`, never in git:
/// FIREBASE_API_KEY, FIREBASE_APP_ID (1:…:android:…), FIREBASE_PROJECT_ID,
/// optional JOI_ONLINE_MODEL / JOI_ONLINE_FALLBACK_MODEL (default
/// gemini-3.5-flash-lite → gemini-flash-lite-latest: ~0.7 s to first token
/// measured 2026-10-27; gemini-3.8-flash timed out / 429 on the free tier), optional JOI_APPCHECK_DEBUG_TOKEN (test builds only). Empty => the online
/// backend is compiled in but always unavailable (graceful fallback).
class JoiOnlineConfig {
  const JoiOnlineConfig({
    this.apiKey = const String.fromEnvironment('FIREBASE_API_KEY'),
    this.appId = const String.fromEnvironment('FIREBASE_APP_ID'),
    this.projectId = const String.fromEnvironment('FIREBASE_PROJECT_ID'),
    this.model = const String.fromEnvironment(
      'JOI_ONLINE_MODEL',
      defaultValue: 'gemini-3.5-flash-lite',
    ),
    this.fallbackModel = const String.fromEnvironment(
      'JOI_ONLINE_FALLBACK_MODEL',
      defaultValue: 'gemini-flash-lite-latest',
    ),
    this.appCheckDebugToken = const String.fromEnvironment(
      'JOI_APPCHECK_DEBUG_TOKEN',
    ),
  });

  final String apiKey;
  final String appId;
  final String projectId;
  final String model;
  final String fallbackModel;
  final String appCheckDebugToken;

  bool get configured =>
      apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  Map<String, String> toMap() => {
    'apiKey': apiKey,
    'appId': appId,
    'projectId': projectId,
    'model': model,
    'fallbackModel': fallbackModel,
    'appCheckDebugToken': appCheckDebugToken,
  };
}

/// Why an online answer failed (shown as a Turkish/EN/RU message).
enum JoiOnlineError {
  timeout,
  quota,
  auth,
  model,
  server,
  offline,
  failed,
  noConsent,
}

/// Opt-in ONLINE backend (0.6.2, owner decision): Gemini via Firebase AI
/// Logic (Gemini Developer API) — only for GENERAL questions on phones
/// without Gemini Nano.
///
/// HARD RULES (enforced here and in [JoiService.ask], covered by tests):
///  - only the user's typed question (+ fixed system prompt) is sent; note
///    titles/bodies are NEVER sent ([JoiService] never routes note prompts
///    here, and [generate] refuses anything carrying the notes marker);
///  - no network call without the user's stored consent ([hasConsent]);
///  - input capped at [maxQuestionChars], output at 400 tokens (native).
class JoiOnlineBackend implements JoiBackend {
  JoiOnlineBackend({
    MethodChannel? channel,
    this.config = const JoiOnlineConfig(),
    required this.hasConsent,
  }) : _ch = channel ?? const MethodChannel('gizlialan/joi');

  final MethodChannel _ch;
  final JoiOnlineConfig config;
  final bool Function() hasConsent;

  static const int maxQuestionChars = 500;

  /// Error of the last failed [generate] call (null after success).
  JoiOnlineError? lastError;

  /// Native debug detail of the last error (model chain, exception).
  String? lastDetail;

  static const _stream = MethodChannel('gizlialan/joi_stream');
  static int _seq = 0;
  static final _partials = <int, void Function(String)>{};
  static bool _streamHooked = false;

  static void _hookStream() {
    if (_streamHooked) return;
    _streamHooked = true;
    _stream.setMethodCallHandler((c) async {
      if (c.method != 'chunk') return;
      final a = c.arguments as Map;
      _partials[a['id'] as int]?.call(a['text'] as String);
    });
  }

  @override
  String get id => 'gemini_online';

  /// "Available" means: configured in this build. Consent is checked per
  /// call (the UI asks for it on first use).
  @override
  Future<JoiStatus> status() async =>
      config.configured ? JoiStatus.available : JoiStatus.unavailable;

  @override
  Future<bool> download() async => false;

  /// [prompt] must be the bare user question (see [JoiService.ask]).
  @override
  Future<String?> generate(
    String prompt, {
    String lang = 'tr',
    void Function(String partial)? onPartial,
  }) async {
    lastError = null;
    lastDetail = null;
    if (!config.configured) {
      lastError = JoiOnlineError.failed;
      return null;
    }
    if (!hasConsent()) {
      lastError = JoiOnlineError.noConsent;
      return null;
    }
    if (prompt.contains(JoiService.notesMarker)) {
      // Defence in depth: note content must never go online.
      lastError = JoiOnlineError.failed;
      return null;
    }
    var q = prompt.trim();
    if (q.isEmpty) return null;
    if (q.length > maxQuestionChars) q = q.substring(0, maxQuestionChars);
    final id = ++_seq;
    if (onPartial != null) {
      try {
        _hookStream();
        _partials[id] = onPartial;
      } catch (_) {}
    }
    try {
      final r = await _ch.invokeMethod<String>('onlineGenerate', {
        ...config.toMap(),
        'system': JoiService.onlineSystemPrompt(lang),
        'question': q,
        'id': id,
      });
      final s = r?.trim();
      if (s == null || s.isEmpty) {
        lastError = JoiOnlineError.failed;
        return null;
      }
      return s;
    } on PlatformException catch (e) {
      lastError =
          JoiOnlineError.values
              .where((v) => v.name == e.code && v != JoiOnlineError.noConsent)
              .firstOrNull ??
          JoiOnlineError.failed;
      lastDetail = '${e.code}: ${e.message ?? ''}';
      return null;
    } catch (e) {
      lastError = JoiOnlineError.failed;
      lastDetail = e.runtimeType.toString();
      return null;
    } finally {
      _partials.remove(id);
    }
  }
}

/// Result of [JoiService.ask].
class JoiAnswer {
  const JoiAnswer(this.text, {required this.online, this.error, this.detail});
  final String? text;

  /// true = answered by the online (Gemini over the internet) backend.
  final bool online;
  final JoiOnlineError? error;

  /// Short debug detail (error class / model chain) for a grey line.
  final String? detail;
}

/// "Joi" — GizliAlan's assistant (0.6.2).
///
/// Backends in priority order: Gemini Nano on the device (if AVAILABLE or
/// DOWNLOADABLE), otherwise the opt-in online backend for general questions
/// only. Note features (ask my notes / summarize) are Nano-only: on other
/// devices they fall back to [JoiNoteSearch] (local keyword search).
class JoiService {
  JoiService({
    MethodChannel? channel,
    List<JoiBackend>? backends,
    bool Function()? hasOnlineConsent,
    JoiOnlineConfig onlineConfig = const JoiOnlineConfig(),
  }) : backends =
           backends ??
           [
             NanoBackend(channel: channel),
             JoiOnlineBackend(
               channel: channel,
               config: onlineConfig,
               hasConsent: hasOnlineConsent ?? () => false,
             ),
           ];

  final List<JoiBackend> backends;
  JoiBackend? _active;

  /// Exact name — the owner's signature.
  static const String name = 'Joi';

  static const int maxContextChars = 6000;

  /// Marks prompts that contain note content (never allowed online).
  static const String notesMarker = '\u2063[gizlialan-notes]';

  JoiBackend? get activeBackend => _active;

  /// The active backend sends questions over the internet.
  bool get isOnline => _active is JoiOnlineBackend;

  /// Ask-my-notes / summarize may run (Nano on the device only).
  bool get noteFeatures => _active != null && _active is! JoiOnlineBackend;

  /// Picks the backend. An on-device backend that is available, downloading
  /// or downloadable always wins over the online one (the UI offers the
  /// Nano download); the online backend is used only when no on-device
  /// backend is usable at all.
  Future<JoiStatus> status() async {
    JoiBackend? best;
    var bestS = JoiStatus.unavailable;
    JoiBackend? online;
    for (final b in backends) {
      final s = await b.status();
      if (b is JoiOnlineBackend) {
        if (s == JoiStatus.available) online ??= b;
        continue;
      }
      if (s == JoiStatus.available) {
        _active = b;
        return s;
      }
      if (s.index < bestS.index) {
        best = b;
        bestS = s;
      }
    }
    if (best != null) {
      _active = best;
      return bestS;
    }
    _active = online;
    return online != null ? JoiStatus.available : JoiStatus.unavailable;
  }

  Future<bool> download() async => await _active?.download() ?? false;

  /// Raw generate on the active ON-DEVICE backend (note prompts). Returns
  /// null on the online backend so note content can never go out.
  Future<String?> generate(String prompt) async {
    if (_active == null) await status();
    final a = _active;
    if (a == null || a is JoiOnlineBackend) return null;
    return a.generate(prompt);
  }

  /// Free question. On-device: full prompt (optionally with [notes]).
  /// Online: ONLY the question text is sent — [notes] are ignored.
  Future<JoiAnswer> ask(
    String question, {
    required String lang,
    List<Note> notes = const [],
    void Function(String partial)? onPartial,
  }) async {
    if (_active == null) await status();
    final a = _active;
    if (a is JoiOnlineBackend) {
      final r = await a.generate(question, lang: lang, onPartial: onPartial);
      return JoiAnswer(
        r,
        online: true,
        error: r == null ? a.lastError : null,
        detail: r == null ? a.lastDetail : null,
      );
    }
    if (a == null) return const JoiAnswer(null, online: false);
    return JoiAnswer(
      await a.generate(chatPrompt(question, lang: lang, notes: notes)),
      online: false,
    );
  }

  static String languageName(String lang) => switch (lang) {
    'en' => 'English',
    'ru' => 'Russian',
    _ => 'Turkish',
  };

  static String systemPrompt(String lang) =>
      'You are Joi, GizliAlan\'ın cihaz içi asistanı (GizliAlan\'s on-device '
      'assistant). You run fully offline on this phone. Be a helpful, '
      'accurate general assistant: answer general-knowledge questions '
      'clearly and briefly, and help with the user\'s private notes when '
      'they are provided. Answer in the same language as the user\'s '
      'message; if unclear, answer in ${languageName(lang)}. If you do not '
      'know something, say so instead of inventing it.';

  /// System prompt for the online backend (no on-device claim, no notes).
  static String onlineSystemPrompt(String lang) =>
      'Sen Joi\'sin, GizliAlan uygulamasının asistanı. Kullanıcının notlarına '
      'erişimin yok. Genel sorulara kısa ve doğru yanıt ver (en fazla birkaç '
      'cümle). Kullanıcının dilinde yanıtla; belirsizse ${languageName(lang)}. '
      'Bilmiyorsan uydurma.';

  /// Prompt for a free question. [notes] (optional) are added as context.
  static String chatPrompt(
    String question, {
    required String lang,
    List<Note> notes = const [],
  }) {
    final b = StringBuffer(systemPrompt(lang))..write('\n\n');
    if (notes.isNotEmpty) {
      b
        ..write(notesMarker)
        ..write('The user\'s private notes (use them only if relevant):\n')
        ..write(notesContext(notes))
        ..write('\n\n');
    }
    b
      ..write('User: ')
      ..write(question.trim())
      ..write('\nJoi:');
    return b.toString();
  }

  static String summarizePrompt(Note note, {required String lang}) =>
      '${systemPrompt(lang)}\n\n${notesMarker}Summarize the following note in '
      'a few short bullet points, in ${languageName(lang)} unless the note is '
      'clearly in another language.\n\n${notesContext([note])}\nJoi:';

  static String notesContext(List<Note> notes) {
    final b = StringBuffer();
    for (final n in notes) {
      final title = n.title.trim().isEmpty ? '(untitled)' : n.title.trim();
      final entry = '### $title\n${n.body.trim()}\n';
      if (b.length + entry.length > maxContextChars) {
        final room = maxContextChars - b.length;
        if (room > 80) b.write(entry.substring(0, room));
        break;
      }
      b.write(entry);
    }
    return b.toString();
  }
}

/// Local keyword search over notes (works on every device; no model).
class JoiNoteSearch {
  static const _stop = {
    // tr
    've', 'ile', 'bir', 'bu', 'şu', 'da', 'de', 'mi', 'mı', 'mu', 'mü',
    'ne', 'kim', 'nedir', 'için', 'gibi', 'ki', 'ya', 'veya', 'notlarım',
    'notlarımda', 'notlarda', 'not', 'nerede', 'hangi', 'var',
    // en
    'the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'is', 'what', 'who',
    'my', 'notes', 'note', 'where', 'which', 'about', 'for', 'on',
    // ru
    'и', 'в', 'на', 'что', 'кто', 'мои', 'заметки', 'где',
  };

  static String _fold(String s) =>
      s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

  static List<String> keywords(String query) => _fold(query)
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((w) => w.length >= 2 && !_stop.contains(w))
      .toSet()
      .toList();

  /// Notes ranked by keyword hits (title hits count triple). Empty when no
  /// keyword matches.
  static List<Note> search(List<Note> notes, String query, {int limit = 5}) {
    final kws = keywords(query);
    if (kws.isEmpty) return const [];
    final scored = <(Note, int)>[];
    for (final n in notes) {
      final title = _fold(n.title);
      final body = _fold(n.body);
      var score = 0;
      for (final k in kws) {
        if (title.contains(k)) score += 3;
        score += k.allMatches(body).length;
      }
      if (score > 0) scored.add((n, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(limit).map((e) => e.$1).toList();
  }

  /// Short one-line snippet around the first keyword hit.
  static String snippet(Note n, String query, {int width = 90}) {
    final body = n.body.replaceAll('\n', ' ');
    final folded = _fold(body);
    for (final k in keywords(query)) {
      final i = folded.indexOf(k);
      if (i >= 0) {
        final start = (i - width ~/ 3).clamp(0, body.length);
        final end = (start + width).clamp(0, body.length);
        return '${start > 0 ? '…' : ''}${body.substring(start, end)}'
            '${end < body.length ? '…' : ''}';
      }
    }
    return body.length > width ? '${body.substring(0, width)}…' : body;
  }
}
