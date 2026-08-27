import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/features/consonant_training/data/consonant_content_repository.dart';

void main() {
  test('체크섬과 버전을 확인한 CDN 콘텐츠만 원자적으로 설치한다', () async {
    final directory = await Directory.systemTemp.createTemp('content_update');
    addTearDown(() => directory.delete(recursive: true));
    final nextPack = _pack('2.0.0');
    final bytes = utf8.encode(nextPack);
    final dio = Dio()..httpClientAdapter = _FakeAdapter(bytes);
    final repository = ConsonantContentRepository(
      dio: dio,
      manifestUrl: 'https://example.test/manifest.json',
      bundledTextLoader: (_) async => _pack('1.0.0'),
      supportDirectoryLoader: () async => directory,
    );

    final result = await repository.updateIfAvailable();
    final installed = await repository.load();

    expect(result.updated, isTrue);
    expect(installed.version, '2.0.0');
    expect(installed.source, 'downloaded');
  });

  test('체크섬이 다르면 기존 내장 콘텐츠를 유지한다', () async {
    final directory = await Directory.systemTemp.createTemp('content_reject');
    addTearDown(() => directory.delete(recursive: true));
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(
        utf8.encode(_pack('2.0.0')),
        checksum: List.filled(64, '0').join(),
      );
    final repository = ConsonantContentRepository(
      dio: dio,
      manifestUrl: 'https://example.test/manifest.json',
      bundledTextLoader: (_) async => _pack('1.0.0'),
      supportDirectoryLoader: () async => directory,
    );

    await expectLater(repository.updateIfAvailable(), throwsFormatException);
    expect((await repository.load()).version, '1.0.0');
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.packBytes, {String? checksum})
    : checksum = checksum ?? sha256.convert(packBytes).toString();

  final List<int> packBytes;
  final String checksum;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('manifest.json')) {
      return ResponseBody.fromString(
        jsonEncode({
          'version': '2.0.0',
          'url': 'https://example.test/pack.json',
          'sha256': checksum,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return ResponseBody.fromBytes(packBytes, 200);
  }

  @override
  void close({bool force = false}) {}
}

String _pack(String version) =>
    '''
{
  "id":"test", "schemaVersion":1, "version":"$version",
  "targets":[{"id":"onset_g","grapheme":"ㄱ","phone":"k","position":"onset","description":""}],
  "items":[{"id":"a","targetId":"onset_g","level":"syllable","text":"가","pronunciation":["k"],"difficulty":1,"category":"test","targetOccurrenceCount":1}]
}
''';
