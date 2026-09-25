import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../l10n/l10n.dart';
import '../models/note.dart';
import '../services/notes_repository.dart';
import '../theme.dart';
import 'note_edit_screen.dart';

/// Encrypted notes list with simple search.
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  NotesRepository? _repoRef;
  NotesRepository get _repo => _repoRef!;
  late Future<List<Note>> _future;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoRef == null) {
      _repoRef = GizliAlanApp.of(context).session!.notes;
      _future = _repo.list();
    }
  }

  void _reload() => setState(() => _future = _repo.list());

  Future<void> _open(Note? note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditScreen(repo: _repo, note: note),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final fmt = DateFormat.yMMMd(L10n.lang).add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(t('notes'))),
      floatingActionButton: FloatingActionButton(
        tooltip: t('newNote'),
        onPressed: () => _open(null),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final q = _query.toLowerCase();
          final notes = snap.data!
              .where(
                (n) =>
                    q.isEmpty ||
                    n.title.toLowerCase().contains(q) ||
                    n.body.toLowerCase().contains(q),
              )
              .toList();
          return Column(
            children: [
              if (snap.data!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t('search'),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            t('emptyNotes'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: GizliTheme.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: notes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final n = notes[i];
                          return ListTile(
                            title: Text(
                              n.title.isEmpty ? t('untitled') : n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${fmt.format(n.updatedAt)}  ·  ${n.body.replaceAll('\n', ' ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: GizliTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () => _open(n),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
