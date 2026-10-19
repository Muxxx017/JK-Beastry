import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/services/offline_photo_files.dart';

typedef OfflinePhotoWriter = Future<String> Function(
  int taxonId,
  Uint8List bytes,
);
typedef OfflinePhotoDeleter = Future<void> Function(String? path);

class OfflineTaxaStore {
  static const _storageKey = 'offline_taxa_v1';
  final OfflinePhotoWriter _writePhoto;
  final OfflinePhotoDeleter _deletePhoto;

  OfflineTaxaStore({
    OfflinePhotoWriter? writePhoto,
    OfflinePhotoDeleter? deletePhoto,
  }) : _writePhoto = writePhoto ?? writeOfflineSpeciesPhoto,
       _deletePhoto = deletePhoto ?? deleteOfflineSpeciesPhoto;

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

  Future<void> save(InatTaxon taxon, {Uint8List? photoBytes}) async {
    final taxa = await load();
    final existing = taxa.where((saved) => saved.id == taxon.id);
    final prior = existing.isEmpty ? null : existing.first;
    final photoPath = photoBytes == null
        ? prior?.offlinePhotoPath ?? taxon.offlinePhotoPath
        : await _writePhoto(taxon.id, photoBytes);
    final savedTaxon = taxon.copyWith(offlinePhotoPath: photoPath);
    final updated = [
      for (final saved in taxa)
        if (saved.id != taxon.id) saved,
      savedTaxon,
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
    final removed = taxa.where((taxon) => taxon.id == taxonId);
    final updated = taxa.where((taxon) => taxon.id != taxonId);
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not remove this species record from the device.');
    }
    if (removed.isNotEmpty) {
      await _deletePhoto(removed.first.offlinePhotoPath);
    }
  }

  Future<InatTaxon?> findByScientificName(String scientificName) async {
    final requested = _normalizeScientificName(scientificName);
    final binomial = requested.split(' ').take(2).join(' ');
    for (final taxon in await load()) {
      final savedName = _normalizeScientificName(taxon.name);
      if (savedName == requested || savedName == binomial) return taxon;
    }
    return null;
  }
}

String _normalizeScientificName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
