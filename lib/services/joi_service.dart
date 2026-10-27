import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';

/// Availability of Gemini Nano (AICore) on this device.
enum JoiStatus { available, downloadable, downloading, unavailable }

/// "Joi" — GizliAlan's on-device assistant (0.6.2).
///
/// HARD RULE: nothing leaves the device. The model is Gemini Nano via the
/// ML Kit GenAI Prompt API running inside Android AICore
/// (android/.../JoiChannel.kt). There is NO network call and NO cloud
/// fallback here. On devices without Nano only [JoiNoteSearch] (plain local
/// keyword search over the decrypted notes in memory) is offered.
/// One model backend for Joi. Pluggable so a second backend can be added
/// later without touching the UI (see [JoiReservedBackend]).
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

/// RESERVED second backend slot (owner decision pending: Gemma 3 1B
/// on-device via MediaPipe/LiteRT with a one-time download, or an opt-in
/// online backend for general questions only). Intentionally a stub: no
/// network code, no model download. Always unavailable.
class JoiReservedBackend implements JoiBackend {
  const JoiReservedBackend();
  @override
  String get id => 'reserved';
  @override
  Future<JoiStatus> status() async => JoiStatus.unavailable;
  @override
  Future<bool> download() async => false;
  @override
  Future<String?> generate(String prompt) async => null;
}

/// "Joi" — GizliAlan's on-device assistant (0.6.2).
///
/// Tries [backends] in order and uses the first usable one. Today: Gemini
/// Nano, then the reserved stub. HARD RULE for the current backends: nothing
/// leaves the device, no cloud fallback. When no backend is usable only
/// [JoiNoteSearch] (local keyword search over decrypted notes) is offered.
class JoiService {
  JoiService({MethodChannel? channel, List<JoiBackend>? backends})
    : backends =
          backends ??
          [NanoBackend(channel: channel), const JoiReservedBackend()];

  final List<JoiBackend> backends;
  JoiBackend? _active;

  /// Exact name — the owner's signature.
  static const String name = 'Joi';

  static const int maxContextChars = 6000;

  JoiBackend? get activeBackend => _active;

  /// Best status over all backends (available > downloading > downloadable).
  Future<JoiStatus> status() async {
    JoiBackend? best;
    var bestS = JoiStatus.unavailable;
    for (final b in backends) {
      final s = await b.status();
      if (s == JoiStatus.available) {
        _active = b;
        return s;
      }
      if (s.index < bestS.index) {
        best = b;
        bestS = s;
      }
    }
    _active = best;
    return bestS;
  }

  Future<bool> download() async => await _active?.download() ?? false;

  Future<String?> generate(String prompt) async {
    if (_active == null) await status();
    return _active?.generate(prompt);
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

  /// Prompt for a free question. [notes] (optional) are added as context.
  static String chatPrompt(
    String question, {
    required String lang,
    List<Note> notes = const [],
  }) {
    final b = StringBuffer(systemPrompt(lang))..write('\n\n');
    if (notes.isNotEmpty) {
      b
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
      '${systemPrompt(lang)}\n\nSummarize the following note in a few short '
      'bullet points, in ${languageName(lang)} unless the note is clearly in '
      'another language.\n\n${notesContext([note])}\nJoi:';

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
