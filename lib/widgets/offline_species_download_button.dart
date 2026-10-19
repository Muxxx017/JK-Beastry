import 'package:flutter/material.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/services/offline_species_service.dart';

class OfflineSpeciesDownloadButton extends StatefulWidget {
  final ZoologySpecies species;

  const OfflineSpeciesDownloadButton({super.key, required this.species});

  @override
  State<OfflineSpeciesDownloadButton> createState() =>
      _OfflineSpeciesDownloadButtonState();
}

class _OfflineSpeciesDownloadButtonState
    extends State<OfflineSpeciesDownloadButton> {
  late final InatService _inatService;
  late final OfflineSpeciesService _offlineService;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _inatService = InatService();
    _offlineService = OfflineSpeciesService(inatService: _inatService);
  }

  @override
  void dispose() {
    _inatService.close();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final taxon = await _offlineService.findByScientificName(
        widget.species.scientificName,
      );
      if (taxon == null) {
        throw Exception(
          'No exact iNaturalist taxon match was found for ${widget.species.scientificName}.',
        );
      }
      final result = await _offlineService.download(taxon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.photoSaved
                ? '${widget.species.commonName}: facts, taxonomy and credited photo saved offline.'
                : '${widget.species.commonName}: facts and taxonomy saved. No photo has a license allowing offline reuse.',
          ),
        ),
      );
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not download this field record: $error')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    key: Key('downloadOffline-${widget.species.id}'),
    onPressed: _downloading ? null : _download,
    icon: _downloading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.download_for_offline_outlined),
    label: Text(_downloading ? 'Saving field record…' : 'Download for offline'),
  );
}
