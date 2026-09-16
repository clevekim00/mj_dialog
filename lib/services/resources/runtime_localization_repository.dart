import 'dart:convert';

import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_pack_manager.dart';

class RuntimeLocalizationRepository {
  RuntimeLocalizationRepository({required ResourcePackManager packManager})
    : _packManager = packManager;

  final ResourcePackManager _packManager;

  Future<Map<String, String>> load(
    ResourceCatalog catalog,
    String locale,
  ) async {
    final candidates = <String>[locale];
    final language = catalog.languages.where((item) => item.locale == locale);
    if (language.isNotEmpty) candidates.add(language.first.fallbackLocale);
    candidates.add('en-US');

    for (final candidate in candidates.toSet()) {
      ResourcePackDescriptor? descriptor;
      for (final pack in catalog.packs) {
        if (pack.type == ResourcePackType.uiStrings &&
            pack.locale == candidate) {
          descriptor = pack;
          break;
        }
      }
      if (descriptor == null) continue;
      try {
        final json = jsonDecode(await _packManager.readText(descriptor));
        if (json is Map<String, dynamic>) {
          return json.map((key, value) => MapEntry(key, value.toString()));
        }
      } catch (_) {
        // 다음 locale 또는 compile-time AppLocalizations가 fallback한다.
      }
    }
    return const <String, String>{};
  }
}
