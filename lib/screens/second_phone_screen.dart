import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/vault_event.dart';
import '../services/second_phone_service.dart';
import '../theme.dart';
import '../widgets/profile_app_tile.dart';

/// "Second phone": set up and manage the owner's own Android work profile
/// (managed profile, Shelter/Island model). Only reachable from the unlocked
/// real vault. Everything shown here is also described in the store listing.
class SecondPhoneScreen extends StatefulWidget {
  const SecondPhoneScreen({super.key});

  @override
  State<SecondPhoneScreen> createState() => _SecondPhoneScreenState();
}

class _SecondPhoneScreenState extends State<SecondPhoneScreen> {
  SecondPhoneStatus? _st;
  List<ProfileApp> _apps = const [];
  bool _busy = false;
  bool _init = false;

  GizliAlanAppState get _app => GizliAlanApp.of(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _refresh();
  }

  SecondPhoneService? get _sp => _app.secondPhoneIfUnlocked;

  Future<void> _log(VaultEventType type, [Map<String, String>? params]) async =>
      _app.session?.events.add(type, params ?? const {});

  Future<void> _refresh() async {
    final sp = _sp;
    if (sp == null) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    final st = await sp.status();
    final apps = st.availability == SecondPhoneAvailability.ready
        ? await sp.listApps()
        : const <ProfileApp>[];
    if (!mounted) return;
    setState(() {
      _st = st;
      _apps = apps;
    });
    _app.secondPhoneChanged.value++;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _failed(String status) =>
      L10n.current('spFailed').replaceAll('{s}', status);

  /// Runs an action that may show system/profile activities, without
  /// triggering the vault auto-lock.
  Future<T?> _run<T>(Future<T> Function(SecondPhoneService sp) action) async {
    final sp = _sp;
    if (sp == null || _busy) return null;
    setState(() => _busy = true);
    try {
      return await _app.withExternalUi(() => action(sp));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(
    String title,
    String body, {
    bool danger = false,
  }) async {
    final t = L10n.current;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger
                ? TextButton.styleFrom(foregroundColor: GizliTheme.danger)
                : null,
            child: Text(t('ok')),
          ),
        ],
      ),
    );
    return r == true;
  }

  // ------------------------------------------------------------ actions

  Future<void> _setUp() async {
    final t = L10n.current;
    if (!await _confirm(t('spSetUp'), t('spSetUpConfirm'))) return;
    final r = await _run((sp) => sp.provision());
    if (r == null) return;
    if (r == 'ok') {
      await _log(VaultEventType.secondPhoneCreated);
      // The profile finishes initialising asynchronously.
      await Future<void>.delayed(const Duration(seconds: 2));
      await _refresh();
      _toast(
        _st?.availability == SecondPhoneAvailability.ready
            ? t('spCreated')
            : t('spCreatedPending'),
      );
    } else if (_st?.isXiaomi ?? false) {
      _toast(t('spXiaomiBlocked'));
      await _refresh();
    } else if (r == 'canceled') {
      _toast(t('spCanceled'));
    } else {
      _toast(t('spUnsupported'));
    }
  }

  Future<void> _openStore() async {
    final r = await _run((sp) => sp.openStore());
    if (r != null && r != 'store_opened') _toast(_failed(r));
  }

  Future<void> _addApp() async {
    final sp = _sp;
    if (sp == null) return;
    final picked = await showModalBottomSheet<CloneCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClonePicker(loader: sp.cloneCandidates),
    );
    if (picked == null) return;
    final t = L10n.current;
    final r = await _run((sp) => sp.clone(picked));
    switch (r) {
      case null:
        return;
      case 'cloned':
        await _log(VaultEventType.secondPhoneAppAdded, {'app': picked.label});
        _toast(t('spCloneOk').replaceAll('{app}', picked.label));
      case 'store_opened':
        _toast(t('spCloneStore'));
      default:
        _toast(t('spCloneFailed'));
    }
    await _refresh();
  }

  bool get _closed =>
      (_st?.quietMode ?? false) || _app.settings.secondPhoneClosedBy != null;

  Future<void> _closeNow() async {
    final t = L10n.current;
    final wanted =
        _app.settings.secondPhoneCloseMode == SecondPhoneCloseMode.quiet
        ? SecondPhoneCloseMode.quiet
        : SecondPhoneCloseMode.freeze;
    final applied = await _run((sp) => sp.close(wanted));
    if (applied == null) {
      _toast(_failed('close'));
    } else {
      await _app.settings.setSecondPhoneClosedBy(applied);
      _toast(
        wanted == SecondPhoneCloseMode.quiet &&
                applied == SecondPhoneCloseMode.freeze
            ? t('spQuietFallback')
            : t('spClosed'),
      );
    }
    await _refresh();
  }

  Future<void> _openNow() async {
    final closedBy =
        _app.settings.secondPhoneClosedBy ??
        ((_st?.quietMode ?? false)
            ? SecondPhoneCloseMode.quiet
            : SecondPhoneCloseMode.freeze);
    final ok = await _run((sp) => sp.open(closedBy));
    if (ok == true) {
      await _app.settings.setSecondPhoneClosedBy(null);
      _toast(L10n.current('spOpened'));
    } else if (ok == false) {
      _toast(_failed('open'));
    }
    await _refresh();
  }

  Future<void> _remove() async {
    final t = L10n.current;
    if (!await _confirm(t('spRemove'), t('spRemoveConfirm'), danger: true)) {
      return;
    }
    final r = await _run((sp) => sp.remove());
    if (r == null) return;
    await _app.settings.setSecondPhoneClosedBy(null);
    await Future<void>.delayed(const Duration(seconds: 2));
    await _refresh();
    if (_st?.exists == false || r == 'removed') {
      await _log(VaultEventType.secondPhoneRemoved);
    }
    _toast(
      _st?.exists == false || r == 'removed' ? t('spRemoved') : _failed(r),
    );
  }

  Future<void> _launch(ProfileApp a) async {
    final sp = _sp;
    if (sp == null) return;
    final r = await sp.launch(a);
    if (r != 'ok') _toast(_failed(r));
  }

  // ------------------------------------------------------------------ UI

  Widget _card(String text, {Color color = GizliTheme.mint, IconData? icon}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GizliTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: color, fontSize: 13, height: 1.45),
              ),
            ),
          ],
        ),
      );

  List<Widget> _readyBody(L10n t) {
    final closed = _closed;
    final status = !closed
        ? t('spStatusOpen')
        : (_st?.quietMode ?? false)
        ? t('spStatusQuiet')
        : t('spStatusFrozen');
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          closed ? Icons.lock_outline : Icons.lock_open_outlined,
          color: closed ? GizliTheme.warning : GizliTheme.mint,
        ),
        title: Text(t('spStatus')),
        subtitle: Text(status),
        trailing: TextButton(
          onPressed: _busy ? null : (closed ? _openNow : _closeNow),
          child: Text(closed ? t('spOpenNow') : t('spCloseNow')),
        ),
      ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: _busy || closed ? null : _openStore,
        icon: const Icon(Icons.shop_outlined),
        label: Text(t('spOpenStore')),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _busy || closed ? null : _addApp,
        icon: const Icon(Icons.add_to_home_screen_outlined),
        label: Text(t('spAddApp')),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        child: Text(
          t('spAddAppHint'),
          style: const TextStyle(color: GizliTheme.textSecondary, fontSize: 12),
        ),
      ),
      Text(
        t('secondPhoneApps').toUpperCase(),
        style: const TextStyle(
          color: GizliTheme.mint,
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      if (_apps.isEmpty)
        Text(
          closed ? t('spStatusFrozen') : t('spNoApps'),
          style: const TextStyle(color: GizliTheme.textSecondary),
        )
      else
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: _apps
              .map((a) => ProfileAppTile(app: a, onTap: () => _launch(a)))
              .toList(),
        ),
      const SizedBox(height: 28),
      TextButton.icon(
        onPressed: _busy ? null : _remove,
        style: TextButton.styleFrom(foregroundColor: GizliTheme.danger),
        icon: const Icon(Icons.delete_forever_outlined),
        label: Text(t('spRemove')),
      ),
    ];
  }

  List<Widget> _body(L10n t, SecondPhoneStatus st) {
    final a = st.availability;
    final out = <Widget>[
      _card(t('spIntro'), icon: Icons.phone_android_outlined),
      _card(
        t('spDisclosure'),
        color: GizliTheme.textSecondary,
        icon: Icons.info_outline,
      ),
    ];
    switch (a) {
      case SecondPhoneAvailability.ready:
        out.addAll(_readyBody(t));
      case SecondPhoneAvailability.unlinked:
        out.add(
          _card(
            t('spUnlinked'),
            color: GizliTheme.warning,
            icon: Icons.link_off,
          ),
        );
      case SecondPhoneAvailability.canSetUp:
      case SecondPhoneAvailability.canSetUpXiaomiRisk:
        if (a == SecondPhoneAvailability.canSetUpXiaomiRisk) {
          out.add(
            _card(
              t('spXiaomiWarn'),
              color: GizliTheme.warning,
              icon: Icons.warning_amber_outlined,
            ),
          );
        }
        out.add(
          ElevatedButton.icon(
            key: const ValueKey('sp_setup'),
            onPressed: _busy ? null : _setUp,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(t('spSetUp')),
          ),
        );
      case SecondPhoneAvailability.blockedXiaomi:
        out.add(
          _card(
            t('spXiaomiBlocked'),
            color: GizliTheme.warning,
            icon: Icons.block,
          ),
        );
      case SecondPhoneAvailability.notAllowed:
        out.add(
          _card(
            t('spNotAllowed'),
            color: GizliTheme.warning,
            icon: Icons.block,
          ),
        );
      case SecondPhoneAvailability.unsupported:
        out.add(
          _card(
            t('spUnsupported'),
            color: GizliTheme.warning,
            icon: Icons.block,
          ),
        );
    }
    if (a != SecondPhoneAvailability.ready && st.privateSpaceAvailable) {
      out.add(const SizedBox(height: 12));
      out.add(_card(t('spPrivateSpaceHint'), icon: Icons.lightbulb_outline));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = _st;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('secondPhone')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _refresh,
          ),
        ],
        bottom: _busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: st == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: _body(t, st)),
    );
  }
}

class _ClonePicker extends StatelessWidget {
  const _ClonePicker({required this.loader});

  final Future<List<CloneCandidate>> Function() loader;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (ctx, scroll) => FutureBuilder<List<CloneCandidate>>(
        future: loader(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(child: Text(t('spNoCandidates')));
          }
          return ListView.builder(
            controller: scroll,
            itemCount: items.length + 1,
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return ListTile(
                  title: Text(
                    t('spAddApp'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(t('spAddAppHint')),
                );
              }
              final c = items[i - 1];
              return ListTile(
                leading: c.icon != null
                    ? Image.memory(c.icon!, width: 40, height: 40)
                    : const Icon(Icons.apps),
                title: Text(c.label),
                subtitle: Text(
                  c.packageName,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.pop(ctx, c),
              );
            },
          );
        },
      ),
    );
  }
}
