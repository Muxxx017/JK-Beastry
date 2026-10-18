import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/models/inat_taxon.dart';

class OfflineTaxaStore {
  static const _storageKey = 'offline_taxa_v1';

  Future<List<InatTaxon>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final content = preferences.getString(_storageKey);
    if (content == null) return [];

    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((item) => InatTaxon.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> save(InatTaxon taxon) async {
    final taxa = await load();
    final updated = [
      for (final saved in taxa)
        if (saved.id != taxon.id) saved,
      taxon,
    ];
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not save this species record on the device.');
    }
  }

  Future<void> remove(int taxonId) async {
    final taxa = await load();
    final updated = taxa.where((taxon) => taxon.id != taxonId);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not remove this species record from the device.');
    }
  }
}
