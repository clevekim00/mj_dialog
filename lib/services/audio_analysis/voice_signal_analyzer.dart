import 'dart:math' as math;
import 'dart:typed_data';

import 'package:speech_rehab/features/voice_analysis/model/voice_analysis_models.dart';

class VoiceSignalAnalyzer {
  const VoiceSignalAnalyzer({this.sampleRate = 16000});

  final int sampleRate;

  VoiceAnalysisFrame analyzePcm16(
    Uint8List bytes, {
    required Duration timestamp,
    double noiseFloorDbfs = -80,
  }) {
    final samples = decodePcm16(bytes);
    if (samples.isEmpty) {
      return VoiceAnalysisFrame(
        timestamp: timestamp,
        waveform: const [],
        spectrum: const [],
        dbfs: -80,
        peak: 0,
        noiseFloorDbfs: noiseFloorDbfs,
        clipping: false,
      );
    }

    final rms = math.sqrt(
      samples.map((sample) => sample * sample).reduce((a, b) => a + b) /
          samples.length,
    );
    final peak = samples.map((sample) => sample.abs()).reduce(math.max);
    final dbfs =
        (rms <= 0 ? -80.0 : (20 * math.log(rms) / math.ln10).clamp(-80, 0))
            .toDouble();
    final pitch = estimatePitch(samples);
    final waveform = downsample(samples, 128);
    final spectrum = magnitudeSpectrum(samples, 96);

    return VoiceAnalysisFrame(
      timestamp: timestamp,
      waveform: waveform,
      spectrum: spectrum,
      dbfs: dbfs,
      peak: peak,
      noiseFloorDbfs: noiseFloorDbfs,
      clipping: peak >= 0.98,
      pitchHz: pitch.$1,
      pitchConfidence: pitch.$2,
    );
  }

  List<double> decodePcm16(Uint8List bytes) {
    final length = bytes.length ~/ 2;
    final data = ByteData.sublistView(bytes);
    return List<double>.generate(length, (index) {
      return data.getInt16(index * 2, Endian.little) / 32768.0;
    }, growable: false);
  }

  (double?, double) estimatePitch(List<double> input) {
    if (input.length < 160) return (null, 0);
    final mean = input.reduce((a, b) => a + b) / input.length;
    final samples = input.map((value) => value - mean).toList(growable: false);
    final energy = samples
        .map((value) => value * value)
        .reduce((a, b) => a + b);
    if (energy / samples.length < 0.00001) return (null, 0);

    final minLag = sampleRate ~/ 500;
    final maxLag = math.min(sampleRate ~/ 60, samples.length ~/ 2);
    var bestLag = 0;
    var bestCorrelation = 0.0;

    for (var lag = minLag; lag <= maxLag; lag++) {
      var cross = 0.0;
      var leftEnergy = 0.0;
      var rightEnergy = 0.0;
      for (var index = 0; index < samples.length - lag; index++) {
        final left = samples[index];
        final right = samples[index + lag];
        cross += left * right;
        leftEnergy += left * left;
        rightEnergy += right * right;
      }
      final denominator = math.sqrt(leftEnergy * rightEnergy);
      final correlation = denominator == 0 ? 0.0 : cross / denominator;
      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestLag = lag;
      }
    }

    if (bestLag == 0 || bestCorrelation < 0.45) return (null, bestCorrelation);
    return (sampleRate / bestLag, bestCorrelation.clamp(0, 1));
  }

  List<double> downsample(List<double> samples, int targetLength) {
    if (samples.length <= targetLength) return List<double>.from(samples);
    final result = <double>[];
    final bucketSize = samples.length / targetLength;
    for (var bucket = 0; bucket < targetLength; bucket++) {
      final start = (bucket * bucketSize).floor();
      final end = math.min(((bucket + 1) * bucketSize).floor(), samples.length);
      var peak = 0.0;
      for (var index = start; index < end; index++) {
        if (samples[index].abs() > peak.abs()) peak = samples[index];
      }
      result.add(peak);
    }
    return result;
  }

  List<double> magnitudeSpectrum(List<double> input, int bins) {
    final size = math.min(512, input.length);
    if (size < 32) return const [];
    final samples = input.sublist(0, size);
    final usableBins = math.min(bins, size ~/ 2);
    final result = List<double>.filled(usableBins, 0);
    for (var k = 0; k < usableBins; k++) {
      var real = 0.0;
      var imaginary = 0.0;
      for (var n = 0; n < size; n++) {
        final window = 0.5 - 0.5 * math.cos(2 * math.pi * n / (size - 1));
        final angle = 2 * math.pi * k * n / size;
        real += samples[n] * window * math.cos(angle);
        imaginary -= samples[n] * window * math.sin(angle);
      }
      final magnitude = math.sqrt(real * real + imaginary * imaginary) / size;
      result[k] = (20 * math.log(math.max(magnitude, 1e-8)) / math.ln10).clamp(
        -100,
        0,
      );
    }
    return result;
  }
}
