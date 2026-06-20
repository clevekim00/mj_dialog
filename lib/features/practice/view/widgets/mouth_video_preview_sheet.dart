import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MouthVideoPreviewSheet extends StatefulWidget {
  const MouthVideoPreviewSheet({super.key, required this.path});

  final String path;

  static void show(BuildContext context, String path) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      showDragHandle: true,
      builder: (_) => MouthVideoPreviewSheet(path: path),
    );
  }

  @override
  State<MouthVideoPreviewSheet> createState() => _MouthVideoPreviewSheetState();
}

class _MouthVideoPreviewSheetState extends State<MouthVideoPreviewSheet> {
  late final VideoPlayerController _controller;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _controller
            ..setLooping(true)
            ..play();
        })
        .catchError((_) {
          if (mounted) {
            setState(() => _hasError = true);
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.video_library_outlined, color: Colors.greenAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '입모양 영상',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasError)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  '영상을 불러올 수 없습니다.',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else if (!_controller.value.isInitialized)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: CircularProgressIndicator(color: Colors.greenAccent),
              )
            else
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: VideoPlayer(_controller),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _controller.value.isInitialized
                    ? () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      }
                    : null,
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(_controller.value.isPlaying ? '일시정지' : '재생'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
