import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/guided_training/data/guided_training_catalog.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/training/training_availability.dart';

void main() {
  test(
    'bundled policy opens all 46 exercises, including every breathing exercise',
    () {
      final json =
          jsonDecode(
                File(
                  'assets/resources/catalog/bootstrap_catalog.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final policy = ResourceCatalog.fromJson(json).trainingAvailability;
      expect(allGuidedTrainingExercises.length, 46);
      expect(
        allGuidedTrainingExercises.every((e) => policy.isEnabled(e.id)),
        isTrue,
      );
      json.remove('trainingAvailability');
      expect(
        ResourceCatalog.fromJson(
          json,
        ).trainingAvailability.isEnabled('breathing_03_rapid_deep'),
        isTrue,
      );
    },
  );
  test('individual closures and reopenings leave other exercises open', () {
    final policy = TrainingAvailability.fromJson({
      'schemaVersion': 1,
      'defaultEnabled': true,
      'overrides': {
        'breathing_03_rapid_deep': false,
        'tongue_08_resistance': true,
      },
    });
    expect(policy.isEnabled('breathing_03_rapid_deep'), isFalse);
    expect(policy.isEnabled('tongue_08_resistance'), isTrue);
    expect(policy.isEnabled('breathing_02_pause_inhale'), isTrue);
    expect(() => policy.overrides['other'] = false, throwsUnsupportedError);
  });
  test(
    'malformed policies are rejected rather than silently opening exercises',
    () {
      for (final value in [
        false,
        {},
        {'schemaVersion': 2, 'defaultEnabled': true, 'overrides': {}},
        {'schemaVersion': 1, 'defaultEnabled': false, 'overrides': {}},
        {
          'schemaVersion': 1,
          'defaultEnabled': true,
          'overrides': {'test': 'false'},
        },
        {
          'schemaVersion': 1,
          'defaultEnabled': true,
          'overrides': {'': false},
        },
      ]) {
        expect(
          () => TrainingAvailability.fromJson(value),
          throwsFormatException,
        );
      }
    },
  );
}
