import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../resources/resource_providers.dart';
import 'training_availability.dart';

/// Uses the verified catalog cache; remote checking uses the existing resource
/// update flow. Consumers must wait for loading instead of bypassing closures.
final trainingAvailabilityProvider = FutureProvider<TrainingAvailability>((
  ref,
) async {
  final snapshot = await ref.watch(resourceCatalogProvider.future);
  return snapshot.catalog.trainingAvailability;
});
