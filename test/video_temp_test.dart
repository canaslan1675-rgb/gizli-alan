import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gizlialan/services/video_temp.dart';
import 'package:gizlialan/services/vault_storage.dart';

void main() {
  late Directory tmp;
  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('gizlialan_vt');
    VideoTemp.baseDir = () async => tmp;
  });
  tearDown(() => tmp.delete(recursive: true));

  test('temp video is private-cache only and deleted (0.6.0 I)', () async {
    final f = await VideoTemp.write(Uint8List.fromList([1, 2, 3]), 'a.MP4');
    expect(f.path.startsWith('${tmp.path}/vplay/'), isTrue);
    expect(f.path.endsWith('.mp4'), isTrue);
    expect(f.uri.pathSegments.last == 'a.mp4', isFalse, reason: 'random name');
    await VideoTemp.delete(f);
    expect(f.existsSync(), isFalse);
    final g = await VideoTemp.write(Uint8List(1), 'b.webm');
    await VideoTemp.wipe();
    expect(g.existsSync(), isFalse);
    expect(Directory('${tmp.path}/vplay').existsSync(), isFalse);
  });

  test('video mime detection', () {
    expect(VaultStorage.guessMime('x.mp4'), 'video/mp4');
    expect(VaultStorage.guessMime('x.webm'), 'video/webm');
    expect(VaultStorage.guessMime('x.3gp'), 'video/3gpp');
  });

  test('pubspec: video_player, no new permission plugins', () {
    final p = File('pubspec.yaml').readAsStringSync();
    expect(p.contains('video_player:'), isTrue);
    expect(p.contains('permission_handler'), isFalse);
  });
}
