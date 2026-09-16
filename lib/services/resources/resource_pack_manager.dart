import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:speech_rehab/services/resources/resource_catalog_repository.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';

enum ResourcePackInstallStatus {
  bundled,
  alreadyCurrent,
  installed,
  unavailable,
  rejected,
}

class ResourcePackInstallResult {
  const ResourcePackInstallResult({
    required this.status,
    required this.packId,
    required this.version,
    required this.message,
  });

  final ResourcePackInstallStatus status;
  final String packId;
  final String version;
  final String message;
}

class ResourcePackManager {
  ResourcePackManager({
    Dio? dio,
    ResourceTextLoader? bundledTextLoader,
    ResourceSupportDirectoryLoader? supportDirectoryLoader,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 3),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 3),
             ),
           ),
       _bundledTextLoader = bundledTextLoader ?? rootBundle.loadString,
       _supportDirectoryLoader =
           supportDirectoryLoader ?? getApplicationSupportDirectory;

  final Dio _dio;
  final ResourceTextLoader _bundledTextLoader;
  final ResourceSupportDirectoryLoader _supportDirectoryLoader;

  Future<ResourcePackInstallResult> install(
    ResourcePackDescriptor descriptor,
  ) async {
    final currentVersion = await installedVersion(descriptor.id);
    if (currentVersion == descriptor.version) {
      return ResourcePackInstallResult(
        status: ResourcePackInstallStatus.alreadyCurrent,
        packId: descriptor.id,
        version: descriptor.version,
        message: '이미 최신 리소스입니다.',
      );
    }
    if (!descriptor.downloadable) {
      return ResourcePackInstallResult(
        status: descriptor.bundledAsset != null
            ? ResourcePackInstallStatus.bundled
            : ResourcePackInstallStatus.unavailable,
        packId: descriptor.id,
        version: descriptor.version,
        message: descriptor.bundledAsset != null
            ? '앱 내장 리소스를 사용합니다.'
            : '다운로드 주소가 없는 리소스입니다.',
      );
    }
    if (Uri.tryParse(descriptor.url)?.scheme != 'https') {
      return ResourcePackInstallResult(
        status: ResourcePackInstallStatus.rejected,
        packId: descriptor.id,
        version: descriptor.version,
        message: '리소스 팩은 HTTPS 주소만 사용할 수 있습니다.',
      );
    }

    try {
      final response = await _dio.get<List<int>>(
        descriptor.url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data ?? const <int>[];
      if (descriptor.sizeBytes > 0 && bytes.length != descriptor.sizeBytes) {
        throw const FormatException('리소스 파일 크기가 manifest와 다릅니다.');
      }
      if (sha256.convert(bytes).toString().toLowerCase() !=
          descriptor.sha256.toLowerCase()) {
        throw const FormatException('리소스 무결성 검사에 실패했습니다.');
      }
      _validatePayload(descriptor, bytes);
      await _activate(descriptor, bytes);
      return ResourcePackInstallResult(
        status: ResourcePackInstallStatus.installed,
        packId: descriptor.id,
        version: descriptor.version,
        message: '${descriptor.id} ${descriptor.version} 설치 완료',
      );
    } on DioException catch (error) {
      return ResourcePackInstallResult(
        status: ResourcePackInstallStatus.unavailable,
        packId: descriptor.id,
        version: descriptor.version,
        message: '다운로드할 수 없어 기존 또는 내장 리소스를 사용합니다: ${error.type.name}',
      );
    } on FormatException catch (error) {
      return ResourcePackInstallResult(
        status: ResourcePackInstallStatus.rejected,
        packId: descriptor.id,
        version: descriptor.version,
        message: error.message,
      );
    }
  }

  Future<String?> installedVersion(String packId) async {
    final directory = await _packDirectory(packId);
    final metadata = File(path.join(directory.path, 'active.meta.json'));
    if (!await metadata.exists()) return null;
    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(await metadata.readAsString()) as Map,
      );
      return decoded['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<int>> readBytes(ResourcePackDescriptor descriptor) async {
    final directory = await _packDirectory(descriptor.id);
    final active = File(path.join(directory.path, 'active.data'));
    final activeMeta = File(path.join(directory.path, 'active.meta.json'));
    final activeBytes = await _readInstalledCandidate(
      descriptor,
      active,
      activeMeta,
    );
    if (activeBytes != null) return activeBytes;
    final previous = File(path.join(directory.path, 'previous.data'));
    final previousMeta = File(path.join(directory.path, 'previous.meta.json'));
    final previousBytes = await _readInstalledCandidate(
      descriptor,
      previous,
      previousMeta,
    );
    if (previousBytes != null) return previousBytes;
    final asset = descriptor.bundledAsset;
    if (asset == null || asset.isEmpty) {
      throw StateError('사용 가능한 ${descriptor.id} 리소스가 없습니다.');
    }
    return utf8.encode(await _bundledTextLoader(asset));
  }

  Future<String> readText(ResourcePackDescriptor descriptor) async {
    return utf8.decode(await readBytes(descriptor));
  }

  Future<List<int>?> _readInstalledCandidate(
    ResourcePackDescriptor descriptor,
    File data,
    File metadata,
  ) async {
    if (!await data.exists() || !await metadata.exists()) return null;
    try {
      final meta = Map<String, dynamic>.from(
        jsonDecode(await metadata.readAsString()) as Map,
      );
      final expectedSha = meta['sha256'] as String? ?? '';
      if (expectedSha.length != 64) return null;
      final bytes = await data.readAsBytes();
      if (sha256.convert(bytes).toString().toLowerCase() !=
          expectedSha.toLowerCase()) {
        return null;
      }
      _validatePayload(descriptor, bytes, verifyCurrentHash: false);
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _validatePayload(
    ResourcePackDescriptor descriptor,
    List<int> bytes, {
    bool verifyCurrentHash = true,
  }) {
    if (bytes.isEmpty) throw const FormatException('리소스 파일이 비어 있습니다.');
    if (verifyCurrentHash && descriptor.sha256.isNotEmpty) {
      final actual = sha256.convert(bytes).toString().toLowerCase();
      if (actual != descriptor.sha256.toLowerCase()) {
        throw const FormatException('리소스 무결성 검사에 실패했습니다.');
      }
    }
    if (descriptor.type == ResourcePackType.uiStrings ||
        descriptor.type == ResourcePackType.content) {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON 리소스가 객체 형식이 아닙니다.');
      }
    }
  }

  Future<void> _activate(
    ResourcePackDescriptor descriptor,
    List<int> bytes,
  ) async {
    final directory = await _packDirectory(descriptor.id);
    final nextData = File(path.join(directory.path, 'next.data'));
    final nextMeta = File(path.join(directory.path, 'next.meta.json'));
    final activeData = File(path.join(directory.path, 'active.data'));
    final activeMeta = File(path.join(directory.path, 'active.meta.json'));
    final previousData = File(path.join(directory.path, 'previous.data'));
    final previousMeta = File(path.join(directory.path, 'previous.meta.json'));

    await nextData.writeAsBytes(bytes, flush: true);
    await nextMeta.writeAsString(
      jsonEncode({
        'id': descriptor.id,
        'version': descriptor.version,
        'sha256': descriptor.sha256,
      }),
      flush: true,
    );
    if (await previousData.exists()) await previousData.delete();
    if (await previousMeta.exists()) await previousMeta.delete();
    if (await activeData.exists()) await activeData.rename(previousData.path);
    if (await activeMeta.exists()) await activeMeta.rename(previousMeta.path);
    try {
      await nextData.rename(activeData.path);
      await nextMeta.rename(activeMeta.path);
    } catch (_) {
      if (await activeData.exists()) await activeData.delete();
      if (await activeMeta.exists()) await activeMeta.delete();
      if (await previousData.exists()) {
        await previousData.rename(activeData.path);
      }
      if (await previousMeta.exists()) {
        await previousMeta.rename(activeMeta.path);
      }
      rethrow;
    }
  }

  Future<Directory> _packDirectory(String packId) async {
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(packId)) {
      throw const FormatException('안전하지 않은 리소스 팩 ID입니다.');
    }
    final support = await _supportDirectoryLoader();
    final directory = Directory(
      path.join(support.path, 'resource_packs', 'packs', packId),
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }
}
