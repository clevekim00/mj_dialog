import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_pack_manager.dart';

void main() {
  test('검증된 JSON 팩을 설치하고 새 catalog가 실패해도 기존 팩을 유지한다', () async {
    final directory = await Directory.systemTemp.createTemp('pack_install');
    addTearDown(() => directory.delete(recursive: true));
    final v1 = utf8.encode('{"title":"installed v1"}');
    final v2 = utf8.encode('{"title":"corrupt v2"}');
    final adapter = _BytesAdapter([v1, v2]);
    final manager = ResourcePackManager(
      dio: Dio()..httpClientAdapter = adapter,
      bundledTextLoader: (_) async => '{"title":"bundled"}',
      supportDirectoryLoader: () async => directory,
    );
    final first = _descriptor('1.0.0', v1);
    final invalidSecond = ResourcePackDescriptor(
      id: 'ui.ko-KR',
      type: ResourcePackType.uiStrings,
      locale: 'ko-KR',
      version: '2.0.0',
      url: 'https://example.test/v2.json',
      sha256: List.filled(64, '0').join(),
      sizeBytes: v2.length,
      required: true,
      bundledAsset: 'bundled.json',
    );

    expect(
      (await manager.install(first)).status,
      ResourcePackInstallStatus.installed,
    );
    expect(
      (await manager.install(invalidSecond)).status,
      ResourcePackInstallStatus.rejected,
    );
    expect(await manager.readText(invalidSecond), '{"title":"installed v1"}');
    expect(await manager.installedVersion(first.id), '1.0.0');
  });

  test('다운로드 주소가 없으면 앱 내장 팩을 사용한다', () async {
    final directory = await Directory.systemTemp.createTemp('pack_bundled');
    addTearDown(() => directory.delete(recursive: true));
    final manager = ResourcePackManager(
      bundledTextLoader: (_) async => '{"title":"bundled"}',
      supportDirectoryLoader: () async => directory,
    );
    const descriptor = ResourcePackDescriptor(
      id: 'ui.en-US',
      type: ResourcePackType.uiStrings,
      locale: 'en-US',
      version: '1.0.0',
      url: '',
      sha256: '',
      sizeBytes: 0,
      required: true,
      bundledAsset: 'bundled.json',
    );

    final result = await manager.install(descriptor);

    expect(result.status, ResourcePackInstallStatus.bundled);
    expect(await manager.readText(descriptor), '{"title":"bundled"}');
  });

  test('경로를 벗어날 수 있는 팩 ID를 거부한다', () async {
    final directory = await Directory.systemTemp.createTemp('pack_path');
    addTearDown(() => directory.delete(recursive: true));
    final manager = ResourcePackManager(
      supportDirectoryLoader: () async => directory,
    );
    const descriptor = ResourcePackDescriptor(
      id: '../unsafe',
      type: ResourcePackType.content,
      locale: 'ko-KR',
      version: '1.0.0',
      url: '',
      sha256: '',
      sizeBytes: 0,
      required: true,
    );

    await expectLater(manager.readBytes(descriptor), throwsFormatException);
  });
}

class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(this.responses);

  final List<List<int>> responses;
  var _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(responses[_index++], 200);
  }

  @override
  void close({bool force = false}) {}
}

ResourcePackDescriptor _descriptor(String version, List<int> bytes) {
  return ResourcePackDescriptor(
    id: 'ui.ko-KR',
    type: ResourcePackType.uiStrings,
    locale: 'ko-KR',
    version: version,
    url: 'https://example.test/$version.json',
    sha256: sha256.convert(bytes).toString(),
    sizeBytes: bytes.length,
    required: true,
    bundledAsset: 'bundled.json',
  );
}
