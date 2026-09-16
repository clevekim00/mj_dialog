import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/services/app_language_service.dart';
import 'package:speech_rehab/services/resources/app_strings.dart';
import 'package:speech_rehab/services/resources/resource_providers.dart';

class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appLanguageProvider);
    final runtimeValues = ref
        .watch(runtimeStringsProvider(state.languageTag))
        .asData
        ?.value;
    final strings = AppStrings(
      AppLocalizations.of(context)!,
      runtimeValues ?? const {},
    );
    final controller = ref.read(appLanguageProvider.notifier);
    final catalog = ref.watch(resourceCatalogProvider);
    final catalogLanguages = catalog.asData?.value.catalog.languages
        .where((item) => item.enabled)
        .toList(growable: false);
    final choices = <(AppLanguagePreference, String)>[
      (AppLanguagePreference.system, strings.systemDefault),
      for (final language in catalogLanguages ?? const [])
        if (language.locale == 'ko-KR')
          (AppLanguagePreference.korean, language.nativeName)
        else if (language.locale == 'en-US')
          (AppLanguagePreference.englishUs, language.nativeName),
      if (catalogLanguages == null) ...[
        (AppLanguagePreference.korean, strings.korean),
        (AppLanguagePreference.englishUs, strings.englishUs),
      ],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.language)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            strings.languageDescription,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            strings.languageChangeNotice,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 20),
          for (final choice in choices)
            Card(
              child: ListTile(
                title: Text(choice.$2),
                subtitle: choice.$1 == AppLanguagePreference.system
                    ? Text(
                        state.languageTag == 'ko-KR'
                            ? strings.korean
                            : strings.englishUs,
                      )
                    : null,
                trailing: state.preference == choice.$1
                    ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                    : const Icon(Icons.circle_outlined),
                onTap: () => controller.setPreference(choice.$1),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/resource_center'),
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(
              state.languageTag == 'ko-KR'
                  ? '다운로드 리소스 관리'
                  : 'Manage Downloaded Resources',
            ),
          ),
        ],
      ),
    );
  }
}
