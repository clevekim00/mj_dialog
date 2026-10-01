/// Administrative availability is independent of clinical guidance.
/// Missing entries are open, including catalogs created before this feature.
class TrainingAvailability {
  const TrainingAvailability({this.overrides = const {}});

  factory TrainingAvailability.fromJson(Object? value) {
    if (value == null) return const TrainingAvailability();
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['defaultEnabled'] != true ||
        value['overrides'] is! Map) {
      throw const FormatException('Invalid training availability policy');
    }
    final entries = <String, bool>{};
    for (final entry in (value['overrides'] as Map).entries) {
      if (entry.key is! String ||
          !RegExp(r'^[a-z][a-z0-9_.-]{0,127}$').hasMatch(entry.key as String) ||
          entry.value is! bool) {
        throw const FormatException('Invalid training availability entry');
      }
      entries[entry.key as String] = entry.value as bool;
    }
    return TrainingAvailability(overrides: Map.unmodifiable(entries));
  }

  final Map<String, bool> overrides;
  bool isEnabled(String exerciseId) => overrides[exerciseId] ?? true;
}
