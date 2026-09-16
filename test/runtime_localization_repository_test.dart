import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_pack_manager.dart';
import 'package:speech_rehab/services/resources/runtime_localization_repository.dart';

void main() {
  test('다운로드 팩이 없으면 내장 UI 문자열을 읽는다', () async {
    final directory = await Directory.systemTemp.createTemp('runtime_strings');
    addTearDown(() => directory.delete(recursive: true));
    final manager = ResourcePackManager(
      bundledTextLoader: (_) async => '{"settings":"내장 설정"}',
      supportDirectoryLoader: () async => directory,
    );
    final repository = RuntimeLocalizationRepository(packManager: manager);
    final catalog = ResourceCatalog(
      schemaVersion: 1,
      catalogVersion: '1.0.0',
      languages: const [
        ResourceLanguage(
          locale: 'ko-KR',
          nativeName: '한국어',
          fallbackLocale: 'en-US',
          enabled: true,
          capabilities: ResourceLanguageCapabilities(
            ui: true,
            content: true,
            tts: true,
            stt: true,
            analysis: true,
          ),
          requiredPacks: ['ui.ko-KR'],
          optionalPacks: [],
        ),
      ],
      packs: const [
        ResourcePackDescriptor(
          id: 'ui.ko-KR',
          type: ResourcePackType.uiStrings,
          locale: 'ko-KR',
          version: '1.0.0',
          url: '',
          sha256: '',
          sizeBytes: 0,
          required: true,
          bundledAsset: 'ui.json',
        ),
      ],
    );

    final strings = await repository.load(catalog, 'ko-KR');

    expect(strings['settings'], '내장 설정');
  });
}
