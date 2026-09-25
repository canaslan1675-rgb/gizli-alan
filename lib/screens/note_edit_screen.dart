import 'package:flutter/material.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../theme.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, required this.note});

  final Note note;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note.title);
    _body = TextEditingController(text: widget.note.body);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    widget.note.title = _title.text.trim();
    widget.note.body = _body.text;
    await GizliAlanApp.of(context).notes.update(widget.note);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final t = L10n.current;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await GizliAlanApp.of(context).notes.delete(widget.note.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('editNote')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: GizliTheme.danger),
            onPressed: _delete,
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
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
                onPressed: _save,
                child: Text(t('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
