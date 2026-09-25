import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../theme.dart';
import 'note_edit_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  late Future<List<Note>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = GizliAlanApp.of(context).notes.list();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    final fmt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(t('notes'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await GizliAlanApp.of(context).notes.create();
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
          );
          _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snap.data!;
          if (notes.isEmpty) {
            return Center(
              child: Text(
                t('emptyNotes'),
                style: const TextStyle(color: GizliTheme.textSecondary),
              ),
            );
          }
          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final n = notes[i];
              return ListTile(
                title: Text(
                  n.title.isEmpty ? t('newNote') : n.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  fmt.format(n.updatedAt),
                  style: const TextStyle(
                    color: GizliTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NoteEditScreen(note: n)),
                  );
                  _reload();
                },
              );
            },
          );
        },
      ),
    );
  }
}
