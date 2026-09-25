import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app.dart';
import '../l10n/l10n.dart';
import '../theme.dart';

/// File vault — imports via system file picker only (user-initiated).
/// No broad storage scrape. AES optional via settings.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late Future<List<FileSystemEntity>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = GizliAlanApp.of(context).vault.listFiles();
    setState(() {});
  }

  Future<void> _import() async {
    final app = GizliAlanApp.of(context);
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    await app.vault.importBytes(
      fileName: f.name,
      bytes: bytes,
      encrypt: app.settings.encryptionEnabled,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.current;
    final app = GizliAlanApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('files')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: t('importFile'),
            onPressed: _import,
          ),
        ],
      ),
      body: Column(
        children: [
          if (app.settings.encryptionEnabled)
            Container(
              width: double.infinity,
              color: GizliTheme.bgCard,
              padding: const EdgeInsets.all(10),
              child: Text(
                t('encryptionHint'),
                style: const TextStyle(
                  fontSize: 12,
                  color: GizliTheme.mint,
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<FileSystemEntity>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final files = snap.data!.whereType<File>().toList();
                if (files.isEmpty) {
                  return Center(
                    child: Text(
                      t('emptyFiles'),
                      style: const TextStyle(color: GizliTheme.textSecondary),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, i) {
                    final file = files[i];
                    return FutureBuilder<String?>(
                      future: app.vault.displayName(file),
                      builder: (context, nameSnap) {
                        final name =
                            nameSnap.data ?? p.basename(file.path);
                        return ListTile(
                          leading: Icon(
                            file.path.endsWith('.gaenc')
                                ? Icons.lock
                                : Icons.insert_drive_file_outlined,
                            color: GizliTheme.mint,
                          ),
                          title: Text(name),
                          subtitle: Text(
                            '${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                            style: const TextStyle(
                              color: GizliTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: GizliTheme.danger,
                            ),
                            onPressed: () async {
                              await app.vault.deleteFile(file);
                              _reload();
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.file_upload_outlined),
        label: Text(t('importFile')),
      ),
    );
  }
}
