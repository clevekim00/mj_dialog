import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/resources/resource_catalog_repository.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_signature_verifier.dart';

void main() {
  test('ETag 304이면 변경사항 없이 현재 catalog를 유지한다', () async {
    final directory = await Directory.systemTemp.createTemp('catalog_etag');
    addTearDown(() => directory.delete(recursive: true));
    final adapter = _CatalogAdapter([
      _CatalogReply(200, _catalog('1.0.0'), etag: 'catalog-v1'),
      const _CatalogReply(304, ''),
    ]);
    final repository = ResourceCatalogRepository(
      dio: Dio()..httpClientAdapter = adapter,
      catalogUrl: 'https://example.test/catalog.json',
      bundledTextLoader: (_) async => _catalog('1.0.0'),
      supportDirectoryLoader: () async => directory,
      signatureVerifier: const _AlwaysValidSignatureVerifier(),
    );

    final first = await repository.checkForUpdates(force: true);
    final second = await repository.checkForUpdates(force: true);

    expect(first.status, ResourceCatalogCheckStatus.noChanges);
    expect(second.status, ResourceCatalogCheckStatus.noChanges);
    expect(second.message, '다운로드할 변경사항이 없습니다.');
    expect(adapter.requests.last.headers['If-None-Match'], 'catalog-v1');
  });

  test('확인 주기 안에는 네트워크 요청을 다시 보내지 않는다', () async {
    final directory = await Directory.systemTemp.createTemp('catalog_ttl');
    addTearDown(() => directory.delete(recursive: true));
    final adapter = _CatalogAdapter([_CatalogReply(200, _catalog('1.0.0'))]);
    var now = DateTime.utc(2026, 8, 27, 1);
    final repository = ResourceCatalogRepository(
      dio: Dio()..httpClientAdapter = adapter,
      catalogUrl: 'https://example.test/catalog.json',
      bundledTextLoader: (_) async => _catalog('1.0.0'),
      supportDirectoryLoader: () async => directory,
      clock: () => now,
      signatureVerifier: const _AlwaysValidSignatureVerifier(),
    );

    await repository.checkForUpdates(force: true);
    now = now.add(const Duration(minutes: 30));
    final result = await repository.checkForUpdates();

    expect(result.status, ResourceCatalogCheckStatus.skipped);
    expect(adapter.requests, hasLength(1));
  });

  test('오프라인이면 예외 없이 앱 내장 catalog를 반환한다', () async {
    final directory = await Directory.systemTemp.createTemp('catalog_offline');
    addTearDown(() => directory.delete(recursive: true));
    final dio = Dio()..httpClientAdapter = _OfflineAdapter();
    final repository = ResourceCatalogRepository(
      dio: dio,
      catalogUrl: 'https://offline.test/catalog.json',
      bundledTextLoader: (_) async => _catalog('1.0.0'),
      supportDirectoryLoader: () async => directory,
      signatureVerifier: const _AlwaysValidSignatureVerifier(),
    );

    final result = await repository.checkForUpdates(force: true);

    expect(result.status, ResourceCatalogCheckStatus.offline);
    expect(result.snapshot.source, 'bundled');
    expect(result.snapshot.catalog.languages.first.locale, 'ko-KR');
  });

  test('새 catalog만 원자적으로 활성화한다', () async {
    final directory = await Directory.systemTemp.createTemp('catalog_update');
    addTearDown(() => directory.delete(recursive: true));
    final repository = ResourceCatalogRepository(
      dio: Dio()
        ..httpClientAdapter = _CatalogAdapter([
          _CatalogReply(200, _catalog('2.0.0')),
        ]),
      catalogUrl: 'https://example.test/catalog.json',
      bundledTextLoader: (_) async => _catalog('1.0.0'),
      supportDirectoryLoader: () async => directory,
      signatureVerifier: const _AlwaysValidSignatureVerifier(),
    );

    final result = await repository.checkForUpdates(force: true);
    final loaded = await repository.loadAvailable();

    expect(result.status, ResourceCatalogCheckStatus.updated);
    expect(loaded.catalog.catalogVersion, '2.0.0');
    expect(loaded.source, 'downloaded');
  });

  test('서명이 유효하지 않은 원격 catalog를 활성화하지 않는다', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catalog_signature',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = ResourceCatalogRepository(
      dio: Dio()
        ..httpClientAdapter = _CatalogAdapter([
          _CatalogReply(200, _catalog('2.0.0')),
        ]),
      catalogUrl: 'https://example.test/catalog.json',
      bundledTextLoader: (_) async => _catalog('1.0.0'),
      supportDirectoryLoader: () async => directory,
    );

    final result = await repository.checkForUpdates(force: true);
    final loaded = await repository.loadAvailable();

    expect(result.status, ResourceCatalogCheckStatus.rejected);
    expect(loaded.catalog.catalogVersion, '1.0.0');
    expect(loaded.source, 'bundled');
  });
}

class _AlwaysValidSignatureVerifier implements ResourceSignatureVerifier {
  const _AlwaysValidSignatureVerifier();

  @override
  Future<bool> verify(Map<String, dynamic> document) async => true;
}

class _CatalogReply {
  const _CatalogReply(this.status, this.body, {this.etag});

  final int status;
  final String body;
  final String? etag;
}

class _CatalogAdapter implements HttpClientAdapter {
  _CatalogAdapter(this.replies);

  final List<_CatalogReply> replies;
  final List<RequestOptions> requests = [];
  var _index = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final reply = replies[_index++];
    return ResponseBody.fromString(
      reply.body,
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (reply.etag != null) 'etag': [reply.etag!],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

String _catalog(String version) => jsonEncode({
  'schemaVersion': 1,
  'catalogVersion': version,
  'languages': [
    {
      'locale': 'ko-KR',
      'nativeName': '한국어',
      'fallbackLocale': 'en-US',
      'enabled': true,
      'capabilities': {
        'ui': true,
        'content': true,
        'tts': true,
        'stt': true,
        'analysis': true,
      },
      'requiredPacks': <String>[],
      'optionalPacks': <String>[],
    },
  ],
  'packs': <Object>[],
});
