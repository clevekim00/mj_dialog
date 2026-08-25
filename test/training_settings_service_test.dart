import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_rehab/services/training/training_settings_service.dart';

void main() {
  test('stores repeat count and renders it in a caption template', () async {
    SharedPreferences.setMockInitialValues({});

    await TrainingSettingsService.saveRepeatCount('tongue_out', 5);

    expect(await TrainingSettingsService.loadRepeatCount('tongue_out'), 5);
    expect(
      TrainingSettingsService.renderCaption('{repeatCount}회 반복하세요.', 5),
      '5회 반복하세요.',
    );
  });
}
