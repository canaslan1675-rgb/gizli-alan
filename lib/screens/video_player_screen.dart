import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
import '../services/video_temp.dart';
import '../services/vault_storage.dart';
import '../widgets/quick_lock.dart';

/// In-vault video playback (0.6.0 I) from a temporary decrypted file that is
/// deleted when this screen closes (and on lock / app start).
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.store, required this.item});

  final VaultStorage store;
  final VaultItem item;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _c;
  File? _tmp;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final bytes = await widget.store.read(widget.item);
      final f = await VideoTemp.write(bytes, widget.item.name);
      if (!mounted) {
        await VideoTemp.delete(f);
        return;
      }
      _tmp = f;
      final c = VideoPlayerController.file(f);
      _c = c;
      await c.initialize();
      c.addListener(_tick);
      await c.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    final c = _c;
    final f = _tmp;
    c?.removeListener(_tick);
    unawaited(() async {
      await c?.dispose();
      if (f != null) await VideoTemp.delete(f);
    }());
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = _c;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.item.name,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [QuickLockButton()],
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  t('videoFailed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    ),
                  ),
                ),
                VideoProgressIndicator(c, allowScrubbing: true),
                SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('video_play_pause'),
                        color: Colors.white,
                        icon: Icon(
                          c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        ),
                        onPressed: () =>
                            c.value.isPlaying ? c.pause() : c.play(),
                      ),
                      Text(
                        '${_fmt(c.value.position)} / ${_fmt(c.value.duration)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
