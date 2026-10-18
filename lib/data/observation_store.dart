import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/models/field_observation.dart';

class ObservationStore {
  static const _storageKey = 'field_observations_v1';

  Future<List<FieldObservation>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = preferences.getString(_storageKey);
    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => FieldObservation.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
  }

  Future<void> save(List<FieldObservation> observations) async {
    final preferences = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      observations.map((observation) => observation.toJson()).toList(),
    );
    final saved = await preferences.setString(_storageKey, jsonString);
    if (!saved) {
      throw StateError('Could not save the field notebook on this device.');
    }
  }
}
