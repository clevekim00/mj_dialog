import 'package:flutter/material.dart';
import 'package:speech_rehab/features/training_video/model/training_video_spec.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';
import 'package:video_player/video_player.dart';

class TrainingVideoPlayer extends StatefulWidget {
  const TrainingVideoPlayer({super.key, required this.spec, this.fallback});

  final TrainingVideoSpec spec;
  final Widget? fallback;

  @override
  State<TrainingVideoPlayer> createState() => _TrainingVideoPlayerState();
}

class _TrainingVideoPlayerState extends State<TrainingVideoPlayer> {
  late final VideoPlayerController _controller;
  int _repeatCount = TrainingSettingsService.defaultRepeatCount;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.spec.assetPath)
      ..setLooping(true)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {});
            _controller.play();
          })
          .catchError((_) {
            if (mounted) setState(() => _failed = true);
          });
    TrainingSettingsService.loadRepeatCount(widget.spec.id).then((value) {
      if (mounted) setState(() => _repeatCount = value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback ?? const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    TrainingSettingsService.renderCaption(
                      widget.spec.captionTemplate,
                      _repeatCount,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
