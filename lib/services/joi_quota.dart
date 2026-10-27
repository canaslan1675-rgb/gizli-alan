/// Free Joi limit (owner decision 0.6.2, confirmed 27 Oct 2026): 10 online
/// messages per local calendar day, reset at local midnight. Pro: unlimited.
///
/// Only messages that actually go to the online model count (a failed
/// request does not). Storage is a tiny day + count pair (no message text).
class JoiDailyQuota {
  JoiDailyQuota({
    required this.readDay,
    required this.readCount,
    required this.write,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const int freeDailyLimit = 10;

  final String? Function() readDay;
  final int Function() readCount;
  final Future<void> Function(String day, int count) write;
  final DateTime Function() _now;

  static String dayKey(DateTime t) {
    final l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  /// Messages used today (0 after local midnight).
  int get used => readDay() == dayKey(_now()) ? readCount() : 0;

  int get left => (freeDailyLimit - used).clamp(0, freeDailyLimit);

  bool get exhausted => left == 0;

  /// "7/10"-style counter value (used today / limit).
  String get label => '$used/$freeDailyLimit';

  Future<void> consume() => write(dayKey(_now()), used + 1);

  /// In-memory quota (tests).
  factory JoiDailyQuota.memory({DateTime Function()? now}) {
    String? d;
    var c = 0;
    return JoiDailyQuota(
      readDay: () => d,
      readCount: () => c,
      write: (day, count) async {
        d = day;
        c = count;
      },
      now: now,
    );
  }
}
