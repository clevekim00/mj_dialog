import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_rehab/services/resources/resource_catalog_repository.dart';
import 'package:speech_rehab/services/resources/resource_models.dart';
import 'package:speech_rehab/services/resources/resource_pack_manager.dart';
import 'package:speech_rehab/services/resources/runtime_localization_repository.dart';

final resourceCatalogRepositoryProvider = Provider<ResourceCatalogRepository>(
  (ref) => ResourceCatalogRepository(),
);

final resourcePackManagerProvider = Provider<ResourcePackManager>(
  (ref) => ResourcePackManager(),
);

final resourceCatalogProvider = FutureProvider<ResourceCatalogSnapshot>(
  (ref) => ref.watch(resourceCatalogRepositoryProvider).loadAvailable(),
);

final runtimeStringsProvider =
    FutureProvider.family<Map<String, String>, String>((ref, locale) async {
      final snapshot = await ref.watch(resourceCatalogProvider.future);
      final repository = RuntimeLocalizationRepository(
        packManager: ref.watch(resourcePackManagerProvider),
      );
      return repository.load(snapshot.catalog, locale);
    });

class ResourceUpdateState {
  const ResourceUpdateState({
    this.checking = false,
    this.lastResult,
    this.packResults = const [],
  });

  final bool checking;
  final ResourceCatalogCheckResult? lastResult;
  final List<ResourcePackInstallResult> packResults;
}

final resourceUpdateProvider =
    NotifierProvider<ResourceUpdateController, ResourceUpdateState>(
      ResourceUpdateController.new,
    );

class ResourceUpdateController extends Notifier<ResourceUpdateState> {
  Future<ResourceCatalogCheckResult>? _inFlight;

  @override
  ResourceUpdateState build() => const ResourceUpdateState();

  Future<ResourceCatalogCheckResult> check({
    required String locale,
    bool force = false,
  }) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _check(locale: locale, force: force);
    _inFlight = future;
    return future.whenComplete(() => _inFlight = null);
  }

  Future<ResourceCatalogCheckResult> _check({
    required String locale,
    required bool force,
  }) async {
    state = ResourceUpdateState(
      checking: true,
      lastResult: state.lastResult,
      packResults: state.packResults,
    );
    final repository = ref.read(resourceCatalogRepositoryProvider);
    final result = await repository.checkForUpdates(force: force);
    final packManager = ref.read(resourcePackManagerProvider);
    final packResults = <ResourcePackInstallResult>[];
    final language = result.snapshot.catalog.languages.where(
      (item) => item.locale == locale && item.enabled,
    );
    if (language.isNotEmpty) {
      for (final packId in language.first.requiredPacks) {
        final descriptor = result.snapshot.catalog.packById(packId);
        if (descriptor != null) {
          packResults.add(await packManager.install(descriptor));
        }
      }
    }
    state = ResourceUpdateState(lastResult: result, packResults: packResults);
    ref.invalidate(resourceCatalogProvider);
    ref.invalidate(runtimeStringsProvider(locale));
    return result;
  }
}
