import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:speech_rehab/services/video/mouth_video_recorder_service.dart';

/// Owns a preview-only camera. No video recording or storage calls exist here.
class PracticeMirror extends StatefulWidget {
  const PracticeMirror({
    super.key,
    required this.english,
    required this.locked,
  });
  final bool english, locked;
  @override
  State<PracticeMirror> createState() => _MirrorState();
}

class _MirrorState extends State<PracticeMirror> with WidgetsBindingObserver {
  final _camera = MouthVideoRecorderService();
  bool _busy = false, _visible = false, _failed = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_close());
  }

  Future<void> _close() async {
    _generation++;
    if (mounted) setState(() => _visible = false);
    await _camera.dispose();
  }

  Future<void> _open() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ready = await _camera.initialize();
    if (!mounted || generation != _generation) {
      await _camera.dispose();
      if (mounted) setState(() => _busy = false);
      return;
    }
    setState(() {
      _busy = false;
      _visible = ready;
      _failed = !ready;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    unawaited(_camera.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = widget.english;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _visible
              ? _close
              : widget.locked || _busy
              ? null
              : _open,
          icon: Icon(_visible ? Icons.videocam_off : Icons.face),
          label: Text(
            en
                ? (_visible ? 'Close mirror' : 'Mirror · no saving')
                : (_visible ? '거울 닫기' : '거울 보기 · 저장 안 함'),
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_failed)
          Text(
            en
                ? 'Camera unavailable. You can continue with audio.'
                : '카메라를 사용할 수 없어요. 음성으로 계속 연습할 수 있어요.',
          ),
        if (_visible && _camera.controller != null) ...[
          Center(
            child: SizedBox(
              height: 180,
              child: AspectRatio(
                aspectRatio: _camera.controller!.value.aspectRatio,
                child: CameraPreview(_camera.controller!),
              ),
            ),
          ),
          Text(
            en
                ? 'Preview only. No video is recorded or saved.'
                : '화면으로만 확인해요. 영상은 녹화하거나 저장하지 않아요.',
          ),
        ],
      ],
    );
  }
}
