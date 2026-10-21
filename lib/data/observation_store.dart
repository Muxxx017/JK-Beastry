import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/models/field_observation.dart';

class ObservationStore {
  static const _storageKey = 'field_observations_v1';
  static final List<FieldObservation> _memoryCache = [];

  Future<List<FieldObservation>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final jsonString = preferences.getString(_storageKey);
      if (jsonString == null) return List.unmodifiable(_memoryCache);

      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final list = decoded
          .map((item) => FieldObservation.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.observedAt.compareTo(a.observedAt));

      _memoryCache
        ..clear()
        ..addAll(list);
      return List.unmodifiable(list);
    } catch (error) {
      debugPrint('SharedPreferences fallback load: $error');
      return List.unmodifiable(_memoryCache);
    }
  }

  Future<void> save(List<FieldObservation> observations) async {
    _memoryCache
      ..clear()
      ..addAll(observations);

    try {
      final preferences = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        observations.map((observation) => observation.toJson()).toList(),
      );
      await preferences.setString(_storageKey, jsonString);
    } catch (error) {
      debugPrint('SharedPreferences fallback save: $error');
    }
  }
}
