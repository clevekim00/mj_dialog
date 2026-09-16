import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/services/app_language_service.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_providers.dart';

class ResourceCenterScreen extends ConsumerWidget {
  const ResourceCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = AppLocalizations.of(context)!;
    final language = ref.watch(appLanguageProvider);
    final strings = ref.watch(runtimeStringsProvider(language.languageTag));
    final values = strings.asData?.value ?? const <String, String>{};
    final update = ref.watch(resourceUpdateProvider);
    final catalog = ref.watch(resourceCatalogProvider);
    String text(String key, String fallbackText) => values[key] ?? fallbackText;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text(
            'resourceCenter.title',
            language.languageTag == 'ko-KR'
                ? '다운로드 리소스'
                : 'Downloaded Resources',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            text(
              'resourceCenter.description',
              language.languageTag == 'ko-KR'
                  ? '언어와 훈련에 필요한 추가 데이터를 관리합니다.'
                  : 'Manage additional language and training data.',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: update.checking
                ? null
                : () => ref
                      .read(resourceUpdateProvider.notifier)
                      .check(locale: language.languageTag, force: true),
            icon: update.checking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              update.checking
                  ? text('resourceCenter.checking', 'Checking…')
                  : text('resourceCenter.check', 'Check for Updates'),
            ),
          ),
          if (update.lastResult != null) ...[
            const SizedBox(height: 12),
            _StatusCard(result: update.lastResult!, values: values),
          ],
          const SizedBox(height: 20),
          catalog.when(
            data: (snapshot) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Catalog ${snapshot.catalog.catalogVersion} · ${snapshot.source}',
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 8),
                for (final item in snapshot.catalog.languages.where(
                  (item) => item.enabled,
                ))
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(item.nativeName),
                      subtitle: Text(
                        '${item.locale} · ${item.requiredPacks.length} required packs',
                      ),
                      trailing: item.locale == language.languageTag
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              fallback.languageDescription,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.result, required this.values});

  final ResourceCatalogCheckResult result;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    final isOffline = result.status == ResourceCatalogCheckStatus.offline;
    final message = isOffline
        ? values['resourceCenter.offline'] ?? result.message
        : result.message;
    return Card(
      child: ListTile(
        leading: Icon(
          isOffline ? Icons.cloud_off : Icons.cloud_done,
          color: isOffline ? Colors.orangeAccent : Colors.greenAccent,
        ),
        title: Text(message ?? result.status.name),
        subtitle: Text(
          '${values['resourceCenter.lastChecked'] ?? 'Last checked'}: '
          '${DateFormat.yMd().add_Hm().format(result.checkedAt.toLocal())}',
        ),
      ),
    );
  }
}
