import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:speech_rehab/features/consonant_training/model/consonant_training_models.dart';

typedef BundledTextLoader = Future<String> Function(String assetPath);
typedef SupportDirectoryLoader = Future<Directory> Function();

class ContentUpdateResult {
  const ContentUpdateResult({required this.updated, required this.message});

  final bool updated;
  final String message;
}

class ConsonantContentRepository {
  ConsonantContentRepository({
    Dio? dio,
    BundledTextLoader? bundledTextLoader,
    SupportDirectoryLoader? supportDirectoryLoader,
    this.manifestUrl = const String.fromEnvironment(
      'PRONUNCIATION_CONTENT_MANIFEST_URL',
    ),
  }) : _dio = dio ?? Dio(),
       _bundledTextLoader = bundledTextLoader ?? rootBundle.loadString,
       _supportDirectoryLoader =
           supportDirectoryLoader ?? getApplicationSupportDirectory;

  static const bundledAsset =
      'assets/pronunciation/content/ko_consonant_core.json';

  final Dio _dio;
  final BundledTextLoader _bundledTextLoader;
  final SupportDirectoryLoader _supportDirectoryLoader;
  final String manifestUrl;

  Future<PronunciationContentPack> load() async {
    final directory = await _packDirectory();
    final downloaded = File(path.join(directory.path, 'current.json'));
    if (await downloaded.exists()) {
      try {
        return _decode(await downloaded.readAsString(), source: 'downloaded');
      } catch (_) {
        // 손상된 업데이트는 무시하고 항상 앱 내장본으로 복구합니다.
      }
    }
    return _decode(await _bundledTextLoader(bundledAsset), source: 'bundled');
  }

  Future<ContentUpdateResult> updateIfAvailable() async {
    if (manifestUrl.trim().isEmpty) {
      return const ContentUpdateResult(
        updated: false,
        message: '콘텐츠 업데이트 주소가 설정되지 않았습니다.',
      );
    }

    final current = await load();
    final response = await _dio.get<dynamic>(manifestUrl);
    final manifest = Map<String, dynamic>.from(response.data as Map);
    final version = manifest['version'] as String? ?? '';
    final downloadUrl = manifest['url'] as String? ?? '';
    final expectedSha = manifest['sha256'] as String? ?? '';
    if (version.isEmpty || downloadUrl.isEmpty || expectedSha.length != 64) {
      throw const FormatException('콘텐츠 manifest 형식이 올바르지 않습니다.');
    }
    if (_compareVersions(version, current.version) <= 0) {
      return const ContentUpdateResult(
        updated: false,
        message: '이미 최신 콘텐츠입니다.',
      );
    }

    final packResponse = await _dio.get<List<int>>(
      downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = packResponse.data ?? const <int>[];
    if (sha256.convert(bytes).toString().toLowerCase() !=
        expectedSha.toLowerCase()) {
      throw const FormatException('콘텐츠 무결성 검사에 실패했습니다.');
    }
    final decoded = _decode(utf8.decode(bytes), source: 'downloaded');
    if (decoded.version != version) {
      throw const FormatException('manifest와 콘텐츠 버전이 다릅니다.');
    }

    final directory = await _packDirectory();
    final temporary = File(path.join(directory.path, 'next.json'));
    final currentFile = File(path.join(directory.path, 'current.json'));
    await temporary.writeAsBytes(bytes, flush: true);
    if (await currentFile.exists()) {
      await currentFile.delete();
    }
    await temporary.rename(currentFile.path);
    return ContentUpdateResult(
      updated: true,
      message: '콘텐츠를 $version 버전으로 업데이트했습니다.',
    );
  }

  PronunciationContentPack _decode(String raw, {required String source}) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('콘텐츠가 JSON 객체가 아닙니다.');
    }
    final pack = PronunciationContentPack.fromJson(json, source: source);
    if (pack.schemaVersion != 1 || pack.targets.isEmpty || pack.items.isEmpty) {
      throw const FormatException('지원하지 않거나 비어 있는 콘텐츠입니다.');
    }
    return pack;
  }

  Future<Directory> _packDirectory() async {
    final support = await _supportDirectoryLoader();
    final directory = Directory(
      path.join(support.path, 'pronunciation_content'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  int _compareVersions(String left, String right) {
    final a = left.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final b = right.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    for (
      var index = 0;
      index < (a.length > b.length ? a.length : b.length);
      index++
    ) {
      final difference =
          (index < a.length ? a[index] : 0) - (index < b.length ? b[index] : 0);
      if (difference != 0) return difference;
    }
    return 0;
  }
}
