import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/note.dart';
import '../services/notes_repository.dart';
import '../theme.dart';

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
  late final TextEditingController _title = TextEditingController(
    text: widget.note?.title ?? '',
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.note?.body ?? '',
  );
  bool _saving = false;

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
        await widget.repo.create(title: title, body: body);
      }
    } else {
      existing
        ..title = title
        ..body = body;
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
            style: TextButton.styleFrom(foregroundColor: GizliTheme.danger),
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
          IconButton(
            tooltip: t('delete'),
            icon: const Icon(Icons.delete_outline, color: GizliTheme.danger),
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
            const SizedBox(height: 12),
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
