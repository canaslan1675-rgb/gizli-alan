/// One entry of the vault-only notification list (see [VaultEventLog]).
///
/// These are the app's OWN events (imports, exports, deletions, second-phone
/// changes, failed unlock attempts). GizliAlan never posts system
/// notifications and never reads other apps' notifications.
class VaultEvent {
  VaultEvent({
    required this.id,
    required this.type,
    required this.at,
    this.params = const {},
    this.read = false,
  });

  final String id;
  final VaultEventType type;
  final DateTime at;

  /// Small string parameters for the localized message (e.g. `n`, `name`).
  final Map<String, String> params;
  bool read;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'at': at.toIso8601String(),
    'params': params,
    'read': read,
  };

  /// Returns null for unknown types (e.g. written by a newer app version).
  static VaultEvent? fromJson(Map<String, dynamic> j) {
    final type = VaultEventType.values.asNameMap()[j['type']];
    if (type == null) return null;
    return VaultEvent(
      id: j['id'] as String? ?? '',
      type: type,
      at:
          DateTime.tryParse(j['at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      params: ((j['params'] as Map?) ?? const {}).map(
        (k, v) => MapEntry('$k', '$v'),
      ),
      read: j['read'] == true,
    );
  }
}

enum VaultEventType {
  /// params: n
  galleryImported,

  /// params: n
  filesImported,

  /// params: name
  itemExported,

  /// params: name
  itemDeleted,

  /// params: n — wrong PIN attempts on the PIN pad since the last real unlock.
  failedUnlocks,
  secondPhoneCreated,

  /// params: app
  secondPhoneAppAdded,
  secondPhoneRemoved,
}
