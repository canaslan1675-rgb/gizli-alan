import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Google Play In-App Updates (flexible) + "what's new" (0.6.2).
///
/// Shown only after the vault is opened (never on the calculator disguise).
/// Sideloaded / test APKs: the native side reports no update → silent.
class UpdateService {
  UpdateService({MethodChannel? channel, DateTime Function()? now})
    : _ch = channel ?? const MethodChannel('gizlialan/update'),
      _now = now ?? DateTime.now;

  final MethodChannel _ch;
  final DateTime Function() _now;

  static const snooze = Duration(days: 1);
  static const _kLastSeen = 'upd_last_seen_vc';
  static String _kSnooze(int vc) => 'upd_snooze_$vc';

  static bool _checkedThisRun = false;

  /// Pure: may we prompt for [vc] now?
  static bool snoozeOver(int? snoozedAtMs, DateTime now) =>
      snoozedAtMs == null ||
      now.difference(DateTime.fromMillisecondsSinceEpoch(snoozedAtMs)) >=
          snooze;

  /// Pure: show "what's new" after an update (not on a fresh install).
  static bool showWhatsNew({required int current, required int? lastSeen}) =>
      lastSeen != null && current > lastSeen;

  /// Pure: changelog lines for [vc] in [lang] (tr fallback).
  static List<String> notesFor(String json, int vc, String lang) {
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      final e = m['$vc'] as Map<String, dynamic>?;
      if (e == null) return const [];
      final l = (e[lang] ?? e['en'] ?? e['tr']) as List?;
      return l?.map((x) => x.toString()).toList() ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<int> _currentVc() async {
    try {
      return (await _ch.invokeMethod<int>('currentVersionCode')) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Call once the vault home is visible. Never throws.
  Future<void> onVaultOpened(BuildContext context) async {
    if (_checkedThisRun) return;
    _checkedThisRun = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final vc = await _currentVc();
      if (vc > 0) {
        final last = prefs.getInt(_kLastSeen);
        if (showWhatsNew(current: vc, lastSeen: last) && context.mounted) {
          await _whatsNew(context, vc);
        }
        await prefs.setInt(_kLastSeen, vc);
      }
      _ch.setMethodCallHandler((c) async {
        if (c.method == 'downloaded' && context.mounted) _downloaded(context);
      });
      final r = await _ch.invokeMapMethod<String, dynamic>('check');
      if (r == null || r['available'] != true || !context.mounted) {
        if (r?['downloaded'] == true && context.mounted) _downloaded(context);
        return;
      }
      final newVc = (r['versionCode'] as num?)?.toInt() ?? 0;
      if (!snoozeOver(prefs.getInt(_kSnooze(newVc)), _now())) return;
      final go = await _prompt(context, newVc);
      if (go == true) {
        await _ch.invokeMethod('start');
      } else {
        await prefs.setInt(_kSnooze(newVc), _now().millisecondsSinceEpoch);
      }
    } catch (_) {
      // Silent: no Play, no network, test build.
    }
  }

  Future<bool?> _prompt(BuildContext context, int newVc) {
    final t = L10n.current;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('update_dialog'),
        title: Text(t('updTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('updBody').replaceAll('{v}', '#$newVc')),
            TextButton(
              onPressed: () => _ch.invokeMethod('openPlay'),
              child: Text(t('updSeeNotes')),
            ),
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('update_later'),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('updLater')),
          ),
          FilledButton(
            key: const ValueKey('update_go'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('updUpdate')),
          ),
        ],
      ),
    );
  }

  void _downloaded(BuildContext context) {
    final t = L10n.current;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 30),
        content: Text(t('updReady')),
        action: SnackBarAction(
          label: t('updRestart'),
          onPressed: () => _ch.invokeMethod('complete'),
        ),
      ),
    );
  }

  Future<void> _whatsNew(BuildContext context, int vc) async {
    final t = L10n.current;
    String raw;
    try {
      raw = await rootBundle.loadString('assets/changelog.json');
    } catch (_) {
      return;
    }
    final lines = notesFor(raw, vc, L10n.lang);
    if (lines.isEmpty || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('whats_new_dialog'),
        title: Text(t('updWhatsNew')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final l in lines) Text('• $l')],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('updOk')),
          ),
        ],
      ),
    );
  }
}
