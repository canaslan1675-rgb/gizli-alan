import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../services/joi_memory.dart';
import '../services/pro_entitlement.dart';
import '../widgets/pro_gate.dart';

/// "Joi'nin hatırladıkları": list / edit / delete facts, forget all,
/// memory on/off. Pro only (free users see the upsell).
class JoiMemoryScreen extends StatefulWidget {
  const JoiMemoryScreen({super.key, this.store, this.isPro, this.enabled});

  /// Test hooks (defaults: vault session / settings / ProEntitlement).
  final JoiMemoryStore? store;
  final bool Function()? isPro;
  final bool Function()? enabled;

  @override
  State<JoiMemoryScreen> createState() => _JoiMemoryScreenState();
}

class _JoiMemoryScreenState extends State<JoiMemoryScreen> {
  JoiMemoryData? _data;
  bool? _enabledLocal;

  GizliAlanAppState? get _app =>
      context.findAncestorStateOfType<GizliAlanAppState>();
  JoiMemoryStore? get _store => widget.store ?? _app?.session?.joiMemory;

  bool get _pro {
    final f = widget.isPro;
    if (f != null) return f();
    final a = _app;
    return a != null && ProEntitlement.isActive(a.settings);
  }

  bool get _enabled =>
      _enabledLocal ??
      widget.enabled?.call() ??
      _app?.settings.joiMemory ??
      true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final st = _store;
    final d = (st == null || !_pro) ? JoiMemoryData() : await st.load();
    if (mounted) setState(() => _data = d);
  }

  Future<void> _save() async {
    final st = _store;
    if (st != null && _data != null) await st.save(_data!);
    if (mounted) setState(() {});
  }

  Future<void> _edit(MemoryFact f) async {
    final t = L10n.current;
    final c = TextEditingController(text: f.text);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('joiMemoryEdit')),
        content: TextField(
          key: const ValueKey('joi_memory_edit_field'),
          controller: c,
          maxLength: 160,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('joi_memory_edit_save'),
            onPressed: () => Navigator.pop(ctx, c.text),
            child: Text(t('save')),
          ),
        ],
      ),
    );
    if (v == null || v.trim().isEmpty) return;
    f
      ..text = v.trim()
      ..updated = DateTime.now();
    await _save();
  }

  Future<void> _forgetAll() async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('joi_memory_forget_confirm'),
        title: Text(t('joiMemoryForgetAll')),
        content: Text(t('joiMemoryForgetAllBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const ValueKey('joi_memory_forget_ok'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('joiMemoryForgetAllOk')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _data = JoiMemoryData());
    await _store?.forgetAll();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('joiMemoryTitle')),
        actions: [
          if (_pro &&
              d != null &&
              (d.facts.isNotEmpty || d.summaries.isNotEmpty))
            IconButton(
              key: const ValueKey('joi_memory_forget_all'),
              tooltip: t('joiMemoryForgetAll'),
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _forgetAll,
            ),
        ],
      ),
      body: !_pro
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(t('joiMemoryProBody'), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('joi_memory_upsell'),
                      onPressed: () => showProRequired(
                        context,
                        title: t('joiProTitle'),
                        body: t('joiMemoryProBody'),
                      ),
                      child: Text(t('proSeePlans')),
                    ),
                  ],
                ),
              ),
            )
          : d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  key: const ValueKey('joi_memory_toggle'),
                  secondary: const Icon(Icons.psychology_outlined),
                  title: Text(t('joiMemoryToggle')),
                  subtitle: Text(t('joiMemoryToggleHint')),
                  value: _enabled,
                  onChanged: (v) async {
                    await _app?.settings.setJoiMemory(v);
                    setState(() => _enabledLocal = v);
                  },
                ),
                const Divider(),
                if (d.facts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t('joiMemoryEmpty'),
                      key: const ValueKey('joi_memory_empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final f in d.facts.reversed)
                  ListTile(
                    key: ValueKey('joi_fact_${f.id}'),
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(f.text),
                    subtitle: Text(
                      '${t('joiMemoryCat_${f.category}')} · '
                      '${f.updated.day}.${f.updated.month}.${f.updated.year}',
                    ),
                    onTap: () => _edit(f),
                    trailing: IconButton(
                      key: ValueKey('joi_fact_delete_${f.id}'),
                      icon: const Icon(Icons.close),
                      tooltip: t('joiMemoryDelete'),
                      onPressed: () async {
                        setState(() => d.facts.remove(f));
                        await _save();
                      },
                    ),
                  ),
                if (d.summaries.isNotEmpty) ...[
                  const Divider(),
                  ListTile(
                    title: Text(
                      t('joiMemorySummaries'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  for (final s in d.summaries.reversed)
                    ListTile(
                      dense: true,
                      title: Text(s.text),
                      subtitle: Text(
                        '${s.created.day}.${s.created.month}.${s.created.year}',
                      ),
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    t('joiMemoryPrivacy'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}
