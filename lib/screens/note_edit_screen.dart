import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/note.dart';
import '../services/notes_repository.dart';
import '../theme.dart';
import 'joi_screen.dart';

/// Create ([note] == null) or edit an encrypted note. Empty new notes are not
/// saved.
class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, required this.repo, this.note});

  final NotesRepository repo;
  final Note? note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  GizliColors get gc => GizliColors.of(context);

  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note?.body ?? '',
  );
  bool _saving = false;
  late DateTime? _remindAt = widget.note?.remindAt;

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final init = _remindAt ?? now.add(const Duration(hours: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: init.isBefore(now) ? now : init,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (d == null || !mounted) return;
    final tm = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (tm == null || !mounted) return;
    setState(
      () => _remindAt = DateTime(d.year, d.month, d.day, tm.hour, tm.minute),
    );
  }

  Widget _reminderRow(L10n t) {
    final r = _remindAt;
    return ListTile(
      key: const ValueKey('note_reminder'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        r == null ? Icons.alarm_add_outlined : Icons.alarm_on,
        color: r == null ? gc.textSecondary : null,
      ),
      title: Text(t('remindShowAt')),
      subtitle: Text(
        r == null
            ? t('remindNone')
            : DateFormat.yMMMd(L10n.lang).add_Hm().format(r),
      ),
      onTap: _pickReminder,
      trailing: r == null
          ? null
          : IconButton(
              key: const ValueKey('note_reminder_clear'),
              tooltip: t('remindClear'),
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _remindAt = null),
            ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final title = _title.text.trim();
    final body = _body.text;
    final existing = widget.note;
    if (existing == null) {
      if (title.isNotEmpty || body.trim().isNotEmpty) {
        await widget.repo.create(title: title, body: body, remindAt: _remindAt);
      }
    } else {
      existing
        ..title = title
        ..body = body
        ..remindAt = _remindAt;
      await widget.repo.update(existing);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = L10n.current;
    final existing = widget.note;
    if (existing == null) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete')),
        content: Text(t('deleteNoteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: gc.danger),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.repo.delete(existing.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? t('newNote') : t('editNote')),
        actions: [
          if (widget.note != null)
            IconButton(
              key: const ValueKey('note_joi_summarize'),
              tooltip: t('joiSummarize'),
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JoiScreen(
                    summarize: Note(
                      id: widget.note!.id,
                      title: _title.text,
                      body: _body.text,
                      createdAt: widget.note!.createdAt,
                      updatedAt: widget.note!.updatedAt,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: t('delete'),
            icon: Icon(Icons.delete_outline, color: gc.danger),
            onPressed: _delete,
          ),
          IconButton(
            tooltip: t('save'),
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: t('noteTitle')),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _body,
                decoration: InputDecoration(labelText: t('noteBody')),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            _reminderRow(t),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(t('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
