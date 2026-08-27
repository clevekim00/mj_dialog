enum ResourcePackType { uiStrings, content, media, model }

ResourcePackType _parsePackType(String value) => switch (value) {
  'ui_strings' => ResourcePackType.uiStrings,
  'content' => ResourcePackType.content,
  'media' => ResourcePackType.media,
  'model' => ResourcePackType.model,
  _ => throw FormatException('지원하지 않는 리소스 팩 형식입니다: $value'),
};

class ResourcePackDescriptor {
  const ResourcePackDescriptor({
    required this.id,
    required this.type,
    required this.locale,
    required this.version,
    required this.url,
    required this.sha256,
    required this.sizeBytes,
    required this.required,
    this.bundledAsset,
  });

  factory ResourcePackDescriptor.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final version = json['version'] as String? ?? '';
    final sha256 = json['sha256'] as String? ?? '';
    if (id.isEmpty || version.isEmpty) {
      throw const FormatException('리소스 팩 ID와 버전은 필수입니다.');
    }
    if (sha256.isNotEmpty && sha256.length != 64) {
      throw const FormatException('리소스 팩 SHA-256 형식이 올바르지 않습니다.');
    }
    final url = json['url'] as String? ?? '';
    if (url.isNotEmpty && Uri.tryParse(url)?.scheme != 'https') {
      throw const FormatException('리소스 팩은 HTTPS 주소만 사용할 수 있습니다.');
    }
    return ResourcePackDescriptor(
      id: id,
      type: _parsePackType(json['type'] as String? ?? ''),
      locale: json['locale'] as String? ?? 'shared',
      version: version,
      url: url,
      sha256: sha256,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      required: json['required'] as bool? ?? false,
      bundledAsset: json['bundledAsset'] as String?,
    );
  }

  final String id;
  final ResourcePackType type;
  final String locale;
  final String version;
  final String url;
  final String sha256;
  final int sizeBytes;
  final bool required;
  final String? bundledAsset;

  bool get downloadable => url.trim().isNotEmpty && sha256.length == 64;
}

class ResourceLanguageCapabilities {
  const ResourceLanguageCapabilities({
    required this.ui,
    required this.content,
    required this.tts,
    required this.stt,
    required this.analysis,
  });

  factory ResourceLanguageCapabilities.fromJson(Map<String, dynamic> json) {
    return ResourceLanguageCapabilities(
      ui: json['ui'] as bool? ?? false,
      content: json['content'] as bool? ?? false,
      tts: json['tts'] as bool? ?? false,
      stt: json['stt'] as bool? ?? false,
      analysis: json['analysis'] as bool? ?? false,
    );
  }

  final bool ui;
  final bool content;
  final bool tts;
  final bool stt;
  final bool analysis;
}

class ResourceLanguage {
  const ResourceLanguage({
    required this.locale,
    required this.nativeName,
    required this.fallbackLocale,
    required this.enabled,
    required this.capabilities,
    required this.requiredPacks,
    required this.optionalPacks,
  });

  factory ResourceLanguage.fromJson(Map<String, dynamic> json) {
    final locale = json['locale'] as String? ?? '';
    final nativeName = json['nativeName'] as String? ?? '';
    if (locale.isEmpty || nativeName.isEmpty) {
      throw const FormatException('언어 locale과 표시 이름은 필수입니다.');
    }
    return ResourceLanguage(
      locale: locale,
      nativeName: nativeName,
      fallbackLocale: json['fallbackLocale'] as String? ?? 'en-US',
      enabled: json['enabled'] as bool? ?? true,
      capabilities: ResourceLanguageCapabilities.fromJson(
        Map<String, dynamic>.from(json['capabilities'] as Map? ?? const {}),
      ),
      requiredPacks: List<String>.from(
        json['requiredPacks'] as List? ?? const [],
      ),
      optionalPacks: List<String>.from(
        json['optionalPacks'] as List? ?? const [],
      ),
    );
  }

  final String locale;
  final String nativeName;
  final String fallbackLocale;
  final bool enabled;
  final ResourceLanguageCapabilities capabilities;
  final List<String> requiredPacks;
  final List<String> optionalPacks;
}

class ResourceCatalog {
  const ResourceCatalog({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.languages,
    required this.packs,
  });

  factory ResourceCatalog.fromJson(Map<String, dynamic> json) {
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    final catalogVersion = json['catalogVersion'] as String? ?? '';
    if (schemaVersion != 1 || catalogVersion.isEmpty) {
      throw const FormatException('지원하지 않는 리소스 catalog입니다.');
    }
    final languages = (json['languages'] as List? ?? const [])
        .map(
          (item) =>
              ResourceLanguage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final packs = (json['packs'] as List? ?? const [])
        .map(
          (item) => ResourcePackDescriptor.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
    if (languages.isEmpty) {
      throw const FormatException('지원 언어가 없는 catalog입니다.');
    }
    final ids = <String>{};
    for (final pack in packs) {
      if (!ids.add(pack.id)) {
        throw FormatException('중복된 리소스 팩 ID입니다: ${pack.id}');
      }
    }
    for (final language in languages) {
      for (final packId in [
        ...language.requiredPacks,
        ...language.optionalPacks,
      ]) {
        if (!ids.contains(packId)) {
          throw FormatException(
            '${language.locale}이 존재하지 않는 팩을 참조합니다: $packId',
          );
        }
      }
    }
    return ResourceCatalog(
      schemaVersion: schemaVersion,
      catalogVersion: catalogVersion,
      languages: languages,
      packs: packs,
    );
  }

  final int schemaVersion;
  final String catalogVersion;
  final List<ResourceLanguage> languages;
  final List<ResourcePackDescriptor> packs;

  ResourcePackDescriptor? packById(String id) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}

enum ResourceCatalogCheckStatus {
  disabled,
  skipped,
  noChanges,
  updated,
  offline,
  rejected,
}

class ResourceCatalogSnapshot {
  const ResourceCatalogSnapshot({required this.catalog, required this.source});

  final ResourceCatalog catalog;
  final String source;
}

class ResourceCatalogCheckResult {
  const ResourceCatalogCheckResult({
    required this.status,
    required this.snapshot,
    required this.checkedAt,
    this.message,
  });

  final ResourceCatalogCheckStatus status;
  final ResourceCatalogSnapshot snapshot;
  final DateTime checkedAt;
  final String? message;
}
