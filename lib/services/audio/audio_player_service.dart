import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  return AudioPlayerService();
});

class AudioPlayerService {
  static const MethodChannel _channel = MethodChannel(
    'speech_rehab/audio_player',
  );
  static const EventChannel _events = EventChannel(
    'speech_rehab/audio_player/events',
  );

  // The native channel has one event sink. Share it across player instances
  // so reference playback cannot replace a waveform player's subscription.
  static Stream<dynamic>? _completionEvents;

  Stream<dynamic> get playbackEvents =>
      _completionEvents ??= _events.receiveBroadcastStream();

  void onPlaybackComplete(VoidCallback callback) {
    _completionEvents ??= _events.receiveBroadcastStream();
    _completionEvents?.listen((event) {
      if (event == 'complete') {
        callback();
      }
    });
  }

  Future<void> playFile(String filePath) async {
    await _channel.invokeMethod<void>('playFile', {'path': filePath});
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }

  Future<void> pause() async {
    await _channel.invokeMethod<void>('pause');
  }

  Future<void> resume() async {
    await _channel.invokeMethod<void>('resume');
  }

  void dispose() {}
}
