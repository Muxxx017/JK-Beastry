import 'package:flutter/foundation.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/services/inat_service.dart';

class OfflineDownloadResult {
  final InatTaxon taxon;
  final bool photoSaved;

  const OfflineDownloadResult({required this.taxon, required this.photoSaved});
}

class OfflineSpeciesService {
  final InatService _inatService;
  final OfflineTaxaStore _store;

  OfflineSpeciesService({InatService? inatService, OfflineTaxaStore? store})
    : _inatService = inatService ?? InatService(),
      _store = store ?? OfflineTaxaStore();

  Future<InatTaxon?> findByScientificName(String scientificName) =>
      _inatService.findTaxonByScientificName(scientificName);

  Future<OfflineDownloadResult> download(InatTaxon taxon) async {
    final details = await _inatService.getTaxonDetails(taxon.id);
    final summaryFuture = details.wikipediaUrl == null
        ? Future<String?>.value()
        : _inatService.getWikipediaSummary(details.wikipediaUrl!);
    final taxonomyFuture = _inatService.getTaxonomicClassification(
      details.name,
    );

    final summary = await summaryFuture;
    final taxonomy = await taxonomyFuture;
    final previous = await _store.findByScientificName(details.name);
    final photo = kIsWeb
        ? null
        : details.reusableOfflinePhoto ??
              await _inatService.findCommonsPhoto(details.name);
    final photoBytes = photo == null
        ? null
        : await _inatService.downloadPhoto(photo);
    final record = details.copyWith(
      offlinePhotoUrl: photo?.url ?? previous?.offlinePhotoUrl,
      offlinePhotoAttribution:
          photo?.attribution ?? previous?.offlinePhotoAttribution,
      offlinePhotoLicense: photo?.license ?? previous?.offlinePhotoLicense,
      offlinePhotoSourceUrl:
          photo?.sourceUrl ??
          (photo == null ? previous?.offlinePhotoSourceUrl : details.taxonUrl),
      offlinePhotoPath: previous?.offlinePhotoPath,
      wikipediaSummary: summary,
      offlineTaxonomy: taxonomy?.offlineRanks ?? const {},
    );

    await _store.save(record, photoBytes: photoBytes);
    final savedRecord = (await _store.load()).firstWhere(
      (saved) => saved.id == record.id,
    );
    return OfflineDownloadResult(
      taxon: savedRecord,
      photoSaved: photoBytes != null || previous?.offlinePhotoPath != null,
    );
  }

  Future<void> remove(int taxonId) => _store.remove(taxonId);

  Future<List<InatTaxon>> loadSaved() => _store.load();
}
