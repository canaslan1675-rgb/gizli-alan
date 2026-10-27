class Note {
  Note({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.remindAt,
  });

  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;

  /// Set while the note is in the recycle bin (0.6.0 G).
  DateTime? deletedAt;

  /// "Şu tarihte göster" (0.6.2): when the vault is unlocked at/after this
  /// time the note pops up inside the app. Stored only inside the encrypted
  /// notes file; no system notification or alarm is ever scheduled.
  DateTime? remindAt;

  bool isDue(DateTime now) => remindAt != null && !remindAt!.isAfter(now);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
    if (remindAt != null) 'remindAt': remindAt!.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    body: j['body'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    deletedAt: DateTime.tryParse(j['deletedAt'] as String? ?? ''),
    remindAt: DateTime.tryParse(j['remindAt'] as String? ?? ''),
  );
}
