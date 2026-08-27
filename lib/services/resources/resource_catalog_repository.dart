import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_signature_verifier.dart';

typedef ResourceTextLoader = Future<String> Function(String assetPath);
typedef ResourceSupportDirectoryLoader = Future<Directory> Function();
typedef ResourceClock = DateTime Function();

class ResourceCatalogRepository {
  ResourceCatalogRepository({
    Dio? dio,
    ResourceTextLoader? bundledTextLoader,
    ResourceSupportDirectoryLoader? supportDirectoryLoader,
    ResourceClock? clock,
    ResourceSignatureVerifier? signatureVerifier,
    this.catalogUrl = const String.fromEnvironment('RESOURCE_CATALOG_URL'),
    this.bundledCatalogAsset =
        'assets/resources/catalog/bootstrap_catalog.json',
    this.checkInterval = const Duration(hours: 6),
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 3),
               receiveTimeout: const Duration(seconds: 5),
               sendTimeout: const Duration(seconds: 3),
             ),
           ),
       _bundledTextLoader = bundledTextLoader ?? rootBundle.loadString,
       _supportDirectoryLoader =
           supportDirectoryLoader ?? getApplicationSupportDirectory,
       _clock = clock ?? DateTime.now,
       _signatureVerifier =
           signatureVerifier ?? Ed25519ResourceSignatureVerifier();

  final Dio _dio;
  final ResourceTextLoader _bundledTextLoader;
  final ResourceSupportDirectoryLoader _supportDirectoryLoader;
  final ResourceClock _clock;
  final ResourceSignatureVerifier _signatureVerifier;
  final String catalogUrl;
  final String bundledCatalogAsset;
  final Duration checkInterval;

  Future<ResourceCatalogSnapshot> loadAvailable() async {
    final directory = await _catalogDirectory();
    for (final candidate in const ['active.json', 'previous.json']) {
      final file = File(path.join(directory.path, candidate));
      if (!await file.exists()) continue;
      try {
        final raw = await file.readAsString();
        final decodedJson = jsonDecode(raw);
        if (decodedJson is! Map<String, dynamic> ||
            !await _signatureVerifier.verify(decodedJson)) {
          continue;
        }
        return ResourceCatalogSnapshot(
          catalog: ResourceCatalog.fromJson(decodedJson),
          source: candidate.startsWith('active') ? 'downloaded' : 'rollback',
        );
      } catch (_) {
        // 다음 검증된 후보 또는 앱 내장 catalog로 복구한다.
      }
    }
    return ResourceCatalogSnapshot(
      catalog: _decode(await _bundledTextLoader(bundledCatalogAsset)),
      source: 'bundled',
    );
  }

  Future<ResourceCatalogCheckResult> checkForUpdates({
    bool force = false,
  }) async {
    final now = _clock().toUtc();
    final current = await loadAvailable();
    if (catalogUrl.trim().isEmpty) {
      return ResourceCatalogCheckResult(
        status: ResourceCatalogCheckStatus.disabled,
        snapshot: current,
        checkedAt: now,
        message: '원격 리소스 catalog 주소가 설정되지 않았습니다.',
      );
    }

    final metadata = await _readMetadata();
    final lastCheckedAt = DateTime.tryParse(
      metadata['lastCheckedAt'] as String? ?? '',
    );
    if (!force &&
        lastCheckedAt != null &&
        now.difference(lastCheckedAt.toUtc()) < checkInterval) {
      return ResourceCatalogCheckResult(
        status: ResourceCatalogCheckStatus.skipped,
        snapshot: current,
        checkedAt: lastCheckedAt.toUtc(),
        message: '최근에 업데이트를 확인했습니다.',
      );
    }

    try {
      final etag = metadata['etag'] as String?;
      final response = await _dio.get<dynamic>(
        catalogUrl,
        options: Options(
          headers: {if (etag != null && etag.isNotEmpty) 'If-None-Match': etag},
          validateStatus: (status) => status == 200 || status == 304,
        ),
      );
      final responseEtag = response.headers.value('etag') ?? etag;
      if (response.statusCode == 304) {
        await _writeMetadata(lastCheckedAt: now, etag: responseEtag);
        return ResourceCatalogCheckResult(
          status: ResourceCatalogCheckStatus.noChanges,
          snapshot: current,
          checkedAt: now,
          message: '다운로드할 변경사항이 없습니다.',
        );
      }

      final raw = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      final remoteJson = jsonDecode(raw);
      if (remoteJson is! Map<String, dynamic> ||
          !await _signatureVerifier.verify(remoteJson)) {
        throw const FormatException('리소스 catalog 서명이 없거나 올바르지 않습니다.');
      }
      final remote = _decode(raw);
      if (_compareVersions(
            remote.catalogVersion,
            current.catalog.catalogVersion,
          ) <=
          0) {
        await _writeMetadata(lastCheckedAt: now, etag: responseEtag);
        return ResourceCatalogCheckResult(
          status: ResourceCatalogCheckStatus.noChanges,
          snapshot: current,
          checkedAt: now,
          message: '다운로드할 변경사항이 없습니다.',
        );
      }

      await _activate(raw);
      await _writeMetadata(lastCheckedAt: now, etag: responseEtag);
      return ResourceCatalogCheckResult(
        status: ResourceCatalogCheckStatus.updated,
        snapshot: ResourceCatalogSnapshot(
          catalog: remote,
          source: 'downloaded',
        ),
        checkedAt: now,
        message: '리소스 목록을 ${remote.catalogVersion} 버전으로 갱신했습니다.',
      );
    } on DioException catch (error) {
      return ResourceCatalogCheckResult(
        status: ResourceCatalogCheckStatus.offline,
        snapshot: current,
        checkedAt: now,
        message: '네트워크에 연결되지 않아 내장 리소스를 사용합니다: ${error.type.name}',
      );
    } on FormatException catch (error) {
      return ResourceCatalogCheckResult(
        status: ResourceCatalogCheckStatus.rejected,
        snapshot: current,
        checkedAt: now,
        message: error.message,
      );
    }
  }

  ResourceCatalog _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('리소스 catalog가 JSON 객체가 아닙니다.');
    }
    return ResourceCatalog.fromJson(decoded);
  }

  Future<Directory> _catalogDirectory() async {
    final support = await _supportDirectoryLoader();
    final directory = Directory(
      path.join(support.path, 'resource_packs', 'catalog'),
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Map<String, dynamic>> _readMetadata() async {
    final directory = await _catalogDirectory();
    final file = File(path.join(directory.path, 'metadata.json'));
    if (!await file.exists()) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(
        jsonDecode(await file.readAsString()) as Map,
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _writeMetadata({
    required DateTime lastCheckedAt,
    required String? etag,
  }) async {
    final directory = await _catalogDirectory();
    final next = File(path.join(directory.path, 'metadata.next.json'));
    final active = File(path.join(directory.path, 'metadata.json'));
    await next.writeAsString(
      jsonEncode({
        'lastCheckedAt': lastCheckedAt.toUtc().toIso8601String(),
        'etag': ?etag,
      }),
      flush: true,
    );
    if (await active.exists()) await active.delete();
    await next.rename(active.path);
  }

  Future<void> _activate(String raw) async {
    final directory = await _catalogDirectory();
    final next = File(path.join(directory.path, 'next.json'));
    final active = File(path.join(directory.path, 'active.json'));
    final previous = File(path.join(directory.path, 'previous.json'));
    await next.writeAsString(raw, flush: true);
    _decode(await next.readAsString());
    if (await previous.exists()) await previous.delete();
    if (await active.exists()) await active.rename(previous.path);
    try {
      await next.rename(active.path);
    } catch (_) {
      if (await previous.exists() && !await active.exists()) {
        await previous.rename(active.path);
      }
      rethrow;
    }
  }

  int _compareVersions(String left, String right) {
    final a = left.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final b = right.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final difference = (i < a.length ? a[i] : 0) - (i < b.length ? b[i] : 0);
      if (difference != 0) return difference;
    }
    return 0;
  }
}
