import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Temporary decrypted copies for in-vault video playback (0.6.0 I).
///
/// The platform player needs a file, so a video is decrypted into the app's
/// private cache (`cache/vplay/`, not reachable by other apps, no storage
/// permission) and deleted when playback ends, on lock and on app start.
class VideoTemp {
  VideoTemp._();

  /// Overridable in tests (path_provider has no plugin there).
  static Future<Directory> Function() baseDir = getTemporaryDirectory;

  static Future<Directory> _dir() async =>
      Directory(p.join((await baseDir()).path, 'vplay'));

  static Future<File> write(Uint8List bytes, String name) async {
    final d = await _dir();
    await d.create(recursive: true);
    var ext = p.extension(name).toLowerCase();
    if (ext.isEmpty || ext.length > 6) ext = '.mp4';
    final f = File(p.join(d.path, '${const Uuid().v4()}$ext'));
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static Future<void> delete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Removes every temp video (lock, app start).
  static Future<void> wipe() async {
    try {
      final d = await _dir();
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {}
  }
}
