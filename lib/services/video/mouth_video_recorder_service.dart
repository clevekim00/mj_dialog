import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final mouthVideoRecorderServiceProvider = Provider(
  (ref) => MouthVideoRecorderService(),
);

class MouthVideoRecorderService {
  CameraController? _controller;
  bool _isInitializing = false;

  CameraController? get controller => _controller;
  bool get isReady => _controller?.value.isInitialized ?? false;
  bool get isRecording => _controller?.value.isRecordingVideo ?? false;

  Future<bool> initialize() async {
    if (kIsWeb) {
      return false;
    }
    if (isReady) {
      return true;
    }
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 80));
      }
      return isReady;
    }

    _isInitializing = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return false;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      _controller = controller;
      return true;
    } catch (error) {
      debugPrint('Mouth video camera initialization failed: $error');
      await _controller?.dispose();
      _controller = null;
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  Future<bool> startRecording(String fileName) async {
    final ready = await initialize();
    if (!ready || isRecording) {
      return false;
    }

    try {
      await _controller!.startVideoRecording();
      return true;
    } catch (error) {
      debugPrint('Mouth video start failed: $error');
      return false;
    }
  }

  Future<String?> stopRecording(String fileName) async {
    if (!isRecording) {
      return null;
    }

    try {
      final recordedFile = await _controller!.stopVideoRecording();
      final directory = await getApplicationDocumentsDirectory();
      final videoDirectory = Directory(p.join(directory.path, 'mouth_videos'));
      if (!await videoDirectory.exists()) {
        await videoDirectory.create(recursive: true);
      }

      final savedPath = p.join(videoDirectory.path, '$fileName.mp4');
      await File(recordedFile.path).copy(savedPath);
      return savedPath;
    } catch (error) {
      debugPrint('Mouth video stop failed: $error');
      return null;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
