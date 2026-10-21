import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  static final Map<int, InatTaxon> _memoryTaxa = {};
  final OfflinePhotoWriter _writePhoto;
  final OfflinePhotoDeleter _deletePhoto;

  OfflineTaxaStore({
    OfflinePhotoWriter? writePhoto,
    OfflinePhotoDeleter? deletePhoto,
  }) : _writePhoto = writePhoto ?? writeOfflineSpeciesPhoto,
       _deletePhoto = deletePhoto ?? deleteOfflineSpeciesPhoto;

  Future<List<InatTaxon>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final content = preferences.getString(_storageKey);
      if (content == null) return _memoryTaxa.values.toList();

      final decoded = jsonDecode(content) as List<dynamic>;
      final list = decoded
          .map((item) => InatTaxon.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      for (final t in list) {
        _memoryTaxa[t.id] = t;
      }
      return list;
    } catch (e) {
      debugPrint('OfflineTaxaStore load fallback: $e');
      return _memoryTaxa.values.toList();
    }
  }

  Future<void> save(InatTaxon taxon, {Uint8List? photoBytes}) async {
    final taxa = await load();
    final existing = taxa.where((saved) => saved.id == taxon.id);
    final prior = existing.isEmpty ? null : existing.first;
    final photoPath = photoBytes == null
        ? prior?.offlinePhotoPath ?? taxon.offlinePhotoPath
        : await _writePhoto(taxon.id, photoBytes);
    final savedTaxon = taxon.copyWith(offlinePhotoPath: photoPath);
    _memoryTaxa[savedTaxon.id] = savedTaxon;

    final updated = [
      for (final saved in taxa)
        if (saved.id != taxon.id) saved,
      savedTaxon,
    ];
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('OfflineTaxaStore save fallback: $e');
    }
  }

  Future<void> remove(int taxonId) async {
    final taxa = await load();
    final match = taxa.where((saved) => saved.id == taxonId);
    if (match.isEmpty) return;
    _memoryTaxa.remove(taxonId);

    try {
      await _deletePhoto(match.first.offlinePhotoPath);
    } catch (e) {
      debugPrint('Could not delete offline photo: $e');
    }

    final updated = taxa.where((saved) => saved.id != taxonId).toList();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _storageKey,
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('OfflineTaxaStore remove fallback: $e');
    }
  }

  Future<InatTaxon?> findByScientificName(String scientificName) async {
    final taxa = await load();
    final target = scientificName.trim().toLowerCase();
    for (final taxon in taxa) {
      if (taxon.name.trim().toLowerCase() == target) {
        return taxon;
      }
    }
    return null;
  }
}
