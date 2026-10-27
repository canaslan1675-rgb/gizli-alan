import 'dart:convert';
import 'dart:io';

import 'joi_service.dart';
import 'joi_tools.dart';
import 'vault_session.dart';

/// Joi long-term memory v1 (0.6.2, Pro). mem0-style: short facts extracted
/// from chat turns, stored ONLY on the device, encrypted with the vault
/// key (`joi_memory.gae`), retrieved by Turkish-aware keyword scoring.
class MemoryFact {
  MemoryFact({
    required this.id,
    required this.text,
    this.category = 'other',
    this.importance = 3,
    required this.created,
    required this.updated,
    DateTime? sourceDate,
  }) : sourceDate = sourceDate ?? created;

  final String id;
  String text;
  String category;
  int importance;
  final DateTime created;
  DateTime updated;
  final DateTime sourceDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'c': category,
    'i': importance,
    'cr': created.toIso8601String(),
    'up': updated.toIso8601String(),
    'src': sourceDate.toIso8601String(),
  };

  static MemoryFact fromJson(Map<String, dynamic> j) => MemoryFact(
    id: j['id'] as String,
    text: j['text'] as String,
    category: (j['c'] as String?) ?? 'other',
    importance: (j['i'] as int?) ?? 3,
    created: DateTime.parse(j['cr'] as String),
    updated: DateTime.parse(j['up'] as String),
    sourceDate: DateTime.tryParse((j['src'] as String?) ?? ''),
  );
}

class MemorySummary {
  MemorySummary(this.text, this.created);
  final String text;
  final DateTime created;
  Map<String, dynamic> toJson() => {'t': text, 'cr': created.toIso8601String()};
  static MemorySummary fromJson(Map<String, dynamic> j) =>
      MemorySummary(j['t'] as String, DateTime.parse(j['cr'] as String));
}

/// One memory operation from the extractor.
class MemoryOp {
  const MemoryOp({
    required this.op,
    this.text = '',
    this.category = 'other',
    this.importance = 3,
    this.targetId,
  });
  final String op; // add | update | delete
  final String text;
  final String category;
  final int importance;
  final String? targetId;
}

/// Everything memory-related of one vault space.
class JoiMemoryData {
  JoiMemoryData({
    List<MemoryFact>? facts,
    List<MemorySummary>? summaries,
    this.extractedUpTo = 0,
    this.summarizedUpTo = 0,
  }) : facts = facts ?? [],
       summaries = summaries ?? [];
  final List<MemoryFact> facts;
  final List<MemorySummary> summaries;

  /// Index into the stored chat: messages before it were already
  /// processed by the fact extractor / the summarizer.
  int extractedUpTo;
  int summarizedUpTo;

  static const int maxFacts = 200;
  static const int maxSummaries = 10;

  Map<String, dynamic> toJson() => {
    'v': 1,
    'facts': facts.map((f) => f.toJson()).toList(),
    'sum': summaries.map((s) => s.toJson()).toList(),
    'ex': extractedUpTo,
    'su': summarizedUpTo,
  };

  static JoiMemoryData fromJson(Map<String, dynamic> j) => JoiMemoryData(
    facts: [
      for (final f in (j['facts'] as List? ?? const []))
        MemoryFact.fromJson((f as Map).cast<String, dynamic>()),
    ],
    summaries: [
      for (final s in (j['sum'] as List? ?? const []))
        MemorySummary.fromJson((s as Map).cast<String, dynamic>()),
    ],
    extractedUpTo: (j['ex'] as int?) ?? 0,
    summarizedUpTo: (j['su'] as int?) ?? 0,
  );

  /// Applies extractor ops; returns the facts that were added/updated.
  /// Sensitive facts are dropped here (in code, not just in the prompt).
  List<MemoryFact> apply(List<MemoryOp> ops, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final changed = <MemoryFact>[];
    for (final o in ops) {
      switch (o.op) {
        case 'delete':
          facts.removeWhere((f) => f.id == o.targetId);
        case 'update':
          final f = facts.where((f) => f.id == o.targetId).firstOrNull;
          if (f == null || o.text.trim().isEmpty) continue;
          if (joiMemorySensitive(o.category, o.text)) {
            facts.remove(f);
            continue;
          }
          f
            ..text = _clip(o.text)
            ..category = o.category
            ..importance = o.importance.clamp(1, 5)
            ..updated = t;
          changed.add(f);
        case 'add':
          final txt = _clip(o.text);
          if (txt.isEmpty || joiMemorySensitive(o.category, txt)) continue;
          final dup = facts
              .where((f) => f.text.toLowerCase() == txt.toLowerCase())
              .firstOrNull;
          if (dup != null) continue;
          final f = MemoryFact(
            id: 'f${t.microsecondsSinceEpoch}${facts.length}',
            text: txt,
            category: o.category,
            importance: o.importance.clamp(1, 5),
            created: t,
            updated: t,
          );
          facts.add(f);
          changed.add(f);
      }
    }
    if (facts.length > maxFacts) {
      facts.sort((a, b) => _keep(b, t).compareTo(_keep(a, t)));
      facts.removeRange(maxFacts, facts.length);
    }
    return changed;
  }

  static double _keep(MemoryFact f, DateTime now) =>
      f.importance - now.difference(f.updated).inDays / 60;

  static String _clip(String s) {
    final x = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    return x.length > 160 ? x.substring(0, 160) : x;
  }

  void addSummary(String text, {DateTime? now}) {
    final s = text.trim();
    if (s.isEmpty) return;
    final words = s.split(RegExp(r'\s+'));
    summaries.add(
      MemorySummary(
        words.length > 150 ? '${words.take(150).join(' ')}…' : s,
        now ?? DateTime.now(),
      ),
    );
    if (summaries.length > maxSummaries) summaries.removeAt(0);
  }
}

const joiMemoryCategories = [
  'identity', // name, age, job, city (not exact address)
  'people', // family, friends, partner
  'pets',
  'preference', // likes, dislikes, food, music
  'interest',
  'goal',
  'event',
  'other',
];

/// Never stored by default: health, finances, credentials, exact
/// addresses, ID numbers.
bool joiMemorySensitive(String category, String text) {
  const bad = {
    'health',
    'medical',
    'finance',
    'financial',
    'money',
    'credential',
    'credentials',
    'password',
    'address',
    'id',
    'identity_number',
  };
  if (bad.contains(category.toLowerCase())) return true;
  return RegExp(
    r"(şifre|sifre|parola|password|passcode|pin\b|pin kod|iban|kredi kart|banka kart|kart numara|cvv|hesap numara|maaş|maas|borç|borc|tc kimlik|t\.c\.|kimlik no|pasaport|ehliyet no|vergi no|adresim|adres(?:i|im)?\s*[:\d]|sokak|cadde|mahalle|apt\.?|daire no|posta kodu|hastal|teşhis|teshis|ilaç|ilac|depresyon|kanser|diyabet|hamile|ameliyat|tedavi|\b\d{11}\b|\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b|@\w+\.\w+|\+?\d[\d -]{9,}\d)",
    caseSensitive: false,
    unicode: true,
  ).hasMatch(text);
}

/// Chat messages that may feed memory: user turns and online model
/// answers only. Note-derived messages (search hits, summaries,
/// ask-my-notes), Joi-created notes, tool results and "write to my notes"
/// requests are filtered out IN CODE.
List<Map<String, String>> joiMemoryInput(List<JoiChatMsg> msgs) => [
  for (final m in msgs)
    if (!m.private &&
        m.noteId == null &&
        m.text.trim().isNotEmpty &&
        (m.fromUser
            ? JoiIntent.parse(m.text) is! JoiWriteNote
            : m.online == true))
      {
        'role': m.fromUser ? 'user' : 'model',
        'text': m.text.length > 500 ? m.text.substring(0, 500) : m.text,
      },
];

/// Strict JSON extraction prompt (mem0 pattern).
const String joiMemoryExtractPrompt =
    'You maintain a long-term memory of FACTS ABOUT THE USER for a personal '
    'assistant. From the conversation, extract at most 5 short, durable '
    'facts the user stated about themselves (name, people, pets, '
    'preferences, interests, goals, important events). Write each fact in '
    'the user\'s language, third person, max 15 words (e.g. "Kullanıcının '
    'adı Demirhan", "Kedisinin adı Pamuk"). Ignore questions, general '
    'knowledge, the assistant\'s statements and one-off chit-chat. NEVER '
    'extract health, finances, passwords/credentials, exact addresses, '
    'phone numbers or ID numbers. Compare with EXISTING facts: use "update" '
    '(with target_id) if a fact changed or can be merged, "delete" if the '
    'user said it is wrong, and do not repeat existing facts. Reply ONLY '
    'with JSON: {"facts":[{"op":"add|update|delete","text":"...",'
    '"category":"identity|people|pets|preference|interest|goal|event|other",'
    '"importance":1-5,"target_id":"id or null"}]}. If nothing, {"facts":[]}.';

const String joiMemorySummaryPrompt =
    'Summarize this older part of a chat between the user and their '
    'assistant Joi in the user\'s language, at most 120 words, focusing on '
    'what the user talked about, wanted or decided. No health, finance, '
    'passwords or addresses. Plain text, no lists.';

/// Builds the extractor input: existing similar facts + the new turns.
String joiMemoryExtractInput(
  List<Map<String, String>> turns,
  List<MemoryFact> existing,
) {
  final b = StringBuffer('EXISTING facts:\n');
  if (existing.isEmpty) b.writeln('(none)');
  for (final f in existing) {
    b.writeln('- id=${f.id} [${f.category}] ${f.text}');
  }
  b.writeln('\nCONVERSATION:');
  for (final t in turns) {
    b.writeln('${t['role'] == 'user' ? 'User' : 'Joi'}: ${t['text']}');
  }
  return b.toString();
}

List<MemoryOp>? parseMemoryOps(String? raw) {
  if (raw == null) return null;
  final a = raw.indexOf('{'), b = raw.lastIndexOf('}');
  if (a < 0 || b <= a) return null;
  try {
    final j = jsonDecode(raw.substring(a, b + 1));
    final list = (j is Map ? j['facts'] : null) as List?;
    if (list == null) return null;
    return [
      for (final e in list.take(5))
        if (e is Map && ['add', 'update', 'delete'].contains(e['op']))
          MemoryOp(
            op: e['op'] as String,
            text: (e['text'] ?? '').toString(),
            category: (e['category'] ?? 'other').toString().toLowerCase(),
            importance: int.tryParse('${e['importance']}') ?? 3,
            targetId: (e['target_id'] == null || e['target_id'] == 'null')
                ? null
                : e['target_id'].toString(),
          ),
    ];
  } catch (_) {
    return null;
  }
}

// ------------------------------------------------------------- retrieval

const _stop = {
  've',
  'ile',
  'bir',
  'bu',
  'şu',
  'o',
  'da',
  'de',
  'mi',
  'mı',
  'mu',
  'mü',
  'ne',
  'neydi',
  'nedir',
  'kim',
  'benim',
  'ben',
  'sen',
  'senin',
  'için',
  'gibi',
  'çok',
  'daha',
  'en',
  'ama',
  'the',
  'a',
  'an',
  'is',
  'my',
  'of',
  'kullanıcının',
  'kullanıcı',
  'adı',
  'adını',
  'var',
  'yok',
  'olan',
};

/// Turkish-aware stems: lowercase, apostrophe suffix dropped, common case
/// and possessive suffixes stripped, then a 5-letter prefix.
Set<String> joiStems(String s) {
  final out = <String>{};
  final words = s
      .toLowerCase()
      .replaceAll('İ'.toLowerCase(), 'i')
      .split(RegExp(r"[^\p{L}\p{N}'’]+", unicode: true));
  for (var w in words) {
    w = w.replaceAll(RegExp(r"['’].*$"), '');
    if (w.length < 2 || _stop.contains(w)) continue;
    w = w.replaceFirst(
      RegExp(
        r"(lerin|ların|leri|ları|imin|ımın|umun|ümün|inin|ının|unun|ünün|nin|nın|nun|nün|sinin|sının|im|ım|um|üm|in|ın|un|ün|si|sı|su|sü|yi|yı|yu|yü|de|da|te|ta|den|dan|ten|tan|e|a|i|ı|u|ü)$",
        unicode: true,
      ),
      '',
    );
    if (w.length < 2) continue;
    out.add(w.length > 5 ? w.substring(0, 5) : w);
  }
  return out;
}

/// Stems match when one is a prefix of the other (≥3 letters):
/// "kedi"(sinin) ~ "ked"(imin).
int _overlap(Set<String> a, Set<String> b) {
  var n = 0;
  for (final x in a) {
    if (b.any(
      (y) =>
          x == y ||
          (x.length >= 3 &&
              y.length >= 3 &&
              (x.startsWith(y) || y.startsWith(x))),
    )) {
      n++;
    }
  }
  return n;
}

/// Top [k] facts for [query] (keyword overlap + importance + recency).
List<MemoryFact> joiRetrieve(
  List<MemoryFact> facts,
  String query, {
  int k = 6,
  DateTime? now,
}) {
  final t = now ?? DateTime.now();
  final q = joiStems(query);
  final scored = <(double, MemoryFact)>[];
  for (final f in facts) {
    final overlap = _overlap(joiStems(f.text), q);
    final days = t.difference(f.updated).inDays;
    final score =
        overlap * 3.0 + f.importance * 0.4 + (days < 7 ? 0.5 : 0) - days / 365;
    if (overlap > 0 || f.importance >= 4) scored.add((score, f));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return scored.take(k).map((e) => e.$2).toList();
}

/// Always-included profile: identity/people/pets facts, most important
/// first, at most ~300 tokens (~1200 chars).
List<MemoryFact> joiProfile(List<MemoryFact> facts, {int maxChars = 1200}) {
  final p =
      facts
          .where(
            (f) => const {'identity', 'people', 'pets'}.contains(f.category),
          )
          .toList()
        ..sort((a, b) {
          final c = b.importance.compareTo(a.importance);
          return c != 0 ? c : b.updated.compareTo(a.updated);
        });
  final out = <MemoryFact>[];
  var n = 0;
  for (final f in p) {
    if (n + f.text.length > maxChars) break;
    n += f.text.length + 3;
    out.add(f);
  }
  return out;
}

/// The memory block for the system prompt (empty when nothing is known).
String joiMemoryBlock(JoiMemoryData d, String query, {DateTime? now}) {
  if (d.facts.isEmpty && d.summaries.isEmpty) return '';
  final profile = joiProfile(d.facts);
  final rel = joiRetrieve(d.facts, query, k: 8, now: now)
      .where((f) => !profile.contains(f))
      .take(8 - profile.length.clamp(0, 3))
      .toList();
  final b = StringBuffer(
    'HAFIZA (kullanıcı hakkında daha önceki sohbetlerden bildiklerin; '
    'yalnızca konuyla ilgiliyse doğal biçimde kullan, liste hâlinde '
    'okuma, "hafızama göre" deme. Kullanıcı bir bilginin yanlış olduğunu '
    'söylerse ona inan):\n',
  );
  for (final f in [...profile, ...rel]) {
    b.writeln('- ${f.text}');
  }
  final sums = d.summaries.length > 2
      ? d.summaries.sublist(d.summaries.length - 2)
      : d.summaries;
  if (sums.isNotEmpty) {
    b.writeln('Önceki sohbet özetleri:');
    for (final s in sums) {
      b.writeln('- ${s.text}');
    }
  }
  return b.toString().trim();
}

/// Encrypted store (`joi_memory.gae`), separate from the chat history:
/// clearing the chat keeps memories; "Tümünü unut" deletes this file.
class JoiMemoryStore {
  JoiMemoryStore(this._files, this._file);
  final EncryptedFiles _files;
  final File _file;
  JoiMemoryData? _cache;

  Future<JoiMemoryData> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await _files.read(_file);
      _cache = raw == null
          ? JoiMemoryData()
          : JoiMemoryData.fromJson(
              jsonDecode(utf8.decode(raw)) as Map<String, dynamic>,
            );
    } catch (_) {
      _cache = JoiMemoryData();
    }
    return _cache!;
  }

  Future<void> save(JoiMemoryData d) async {
    _cache = d;
    await _files.write(_file, utf8.encode(jsonEncode(d.toJson())));
  }

  /// Chat cleared: keep facts/summaries, reset the chat pointers.
  Future<void> chatCleared() async {
    final d = await load();
    d
      ..extractedUpTo = 0
      ..summarizedUpTo = 0;
    await save(d);
  }

  Future<void> forgetAll() async {
    _cache = JoiMemoryData();
    if (await _file.exists()) await _file.delete();
  }
}

/// Runs extraction / summaries and builds the prompt block.
class JoiMemoryEngine {
  JoiMemoryEngine(this.store, this.service);
  final JoiMemoryStore store;
  final JoiService service;
  bool _running = false;

  static const int everyMessages = 10;
  static const int window = 20;

  Future<String> block(String query) async =>
      joiMemoryBlock(await store.load(), query);

  /// Call after each exchange ([force] on pause/exit). Returns the facts
  /// added or updated (for the "Joi bunu hatırladı" chip).
  Future<List<MemoryFact>> process(
    List<JoiChatMsg> chat, {
    bool force = false,
  }) async {
    if (_running) return const [];
    _running = true;
    try {
      final d = await store.load();
      if (d.extractedUpTo > chat.length) d.extractedUpTo = 0;
      if (d.summarizedUpTo > chat.length) d.summarizedUpTo = 0;
      var changed = <MemoryFact>[];
      var dirty = false;
      final pending = chat.length - d.extractedUpTo;
      final turns = joiMemoryInput(chat.sublist(d.extractedUpTo));
      final userTurns = turns.where((t) => t['role'] == 'user').length;
      if (userTurns > 0 && (pending >= everyMessages || force)) {
        final convo = turns.map((t) => t['text']).join(' ');
        final existing = {
          ...joiProfile(d.facts),
          ...joiRetrieve(d.facts, convo, k: 15),
        }.toList();
        var input = joiMemoryExtractInput(turns, existing);
        if (input.length > 5800) {
          input = joiMemoryExtractInput(
            turns.sublist((turns.length - 12).clamp(0, turns.length)),
            existing,
          );
        }
        final ops = parseMemoryOps(
          await service.memoryCall(joiMemoryExtractPrompt, input),
        );
        if (ops != null) {
          changed = d.apply(ops);
          d.extractedUpTo = chat.length;
          dirty = true;
        }
      } else if (userTurns == 0 && pending > 0) {
        d.extractedUpTo = chat.length; // nothing usable (notes/tools only)
        dirty = true;
      }
      // Rolling summary of what fell out of the 20-message window.
      final end = chat.length - window;
      if (end - d.summarizedUpTo >= everyMessages) {
        final old = joiMemoryInput(chat.sublist(d.summarizedUpTo, end));
        if (old.isEmpty) {
          d.summarizedUpTo = end;
          dirty = true;
        } else {
          final s = await service.memoryCall(
            joiMemorySummaryPrompt,
            old
                .map(
                  (t) =>
                      '${t['role'] == 'user' ? 'User' : 'Joi'}: ${t['text']}',
                )
                .join('\n'),
          );
          if (s != null && s.trim().isNotEmpty) {
            d
              ..addSummary(s)
              ..summarizedUpTo = end;
            dirty = true;
          }
        }
      }
      if (dirty) await store.save(d);
      return changed;
    } catch (_) {
      return const [];
    } finally {
      _running = false;
    }
  }
}
