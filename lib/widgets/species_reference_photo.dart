import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';
import 'package:zoology_app/widgets/local_species_photo.dart';

class SpeciesReferencePhoto extends StatefulWidget {
  final ZoologySpecies species;
  final InatService? service;
  final double height;

  const SpeciesReferencePhoto({
    super.key,
    required this.species,
    this.service,
    this.height = 230,
  });

  @override
  State<SpeciesReferencePhoto> createState() => _SpeciesReferencePhotoState();
}

class _SpeciesReferencePhotoState extends State<SpeciesReferencePhoto> {
  late final InatService _service;
  late final bool _ownsService;
  late Future<InatTaxon?> _taxon;

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? InatService();
    _taxon = _loadTaxon();
  }

  Future<InatTaxon?> _loadTaxon() async {
    final saved = await OfflineTaxaStore().findByScientificName(
      widget.species.scientificName,
    );
    if (saved?.offlinePhotoPath != null) return saved;
    final taxon = await _service.findTaxonByScientificName(
      widget.species.scientificName,
    );
    if (taxon == null || taxon.photoUrl != null) return taxon;
    final photo = await _service.findCommonsPhoto(taxon.name);
    if (photo == null) return taxon;
    return taxon.copyWith(
      photoUrl: photo.url,
      photoAttribution: photo.attribution,
      photoLicense: photo.license,
      photoSourceUrl: photo.sourceUrl,
    );
  }

  @override
  void dispose() {
    if (_ownsService) _service.close();
    super.dispose();
  }

  Future<void> _openPhotoSource(InatTaxon taxon) async {
    final url = taxon.offlinePhotoPath == null
        ? taxon.photoSourceUrl ?? taxon.taxonUrl
        : taxon.offlinePhotoSourceUrl ?? taxon.taxonUrl;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the photo source.')),
      );
    }
  }

  void _showPhoto(InatTaxon taxon) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(widget.species.commonName),
            actions: [
              IconButton(
                tooltip: 'Close photo',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.75,
                  maxScale: 5,
                  child: Center(
                    child: _PhotoImage(taxon: taxon, fit: BoxFit.contain),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _photoCredit(
                          taxon,
                          requestedName: widget.species.scientificName,
                        ),
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed: () => _openPhotoSource(taxon),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('View image source'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InatTaxon?>(
      future: _taxon,
      builder: (context, snapshot) {
        final taxon = snapshot.data;
        if (taxon == null ||
            (taxon.offlinePhotoPath == null && taxon.photoUrl == null)) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: ColoredBox(
              color: BestiaryPalette.sage,
              child: Center(
                child: snapshot.connectionState != ConnectionState.done
                    ? const Icon(
                        Icons.hourglass_top_rounded,
                        color: BestiaryPalette.forest,
                      )
                    : const Icon(
                        Icons.image_not_supported_outlined,
                        color: BestiaryPalette.forest,
                        size: 34,
                      ),
              ),
            ),
          );
        }
        return Semantics(
          label: 'Reference photo of ${widget.species.commonName}',
          button: true,
          child: GestureDetector(
            onTap: () => _showPhoto(taxon),
            child: SizedBox(
              height: widget.height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PhotoImage(taxon: taxon, fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .62),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        child: Text(
                          _photoCredit(
                            taxon,
                            requestedName: widget.species.scientificName,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final InatTaxon taxon;
  final BoxFit fit;

  const _PhotoImage({required this.taxon, required this.fit});

  @override
  Widget build(BuildContext context) {
    final localPath = taxon.offlinePhotoPath;
    if (localPath != null && !kIsWeb) {
      return LocalSpeciesPhoto(path: localPath, fit: fit);
    }
    final url = taxon.offlinePhotoUrl ?? taxon.photoUrl;
    if (url == null) return const ColoredBox(color: BestiaryPalette.sage);
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: BestiaryPalette.sage,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

String _photoCredit(InatTaxon taxon, {required String requestedName}) {
  final attribution = taxon.offlinePhotoPath == null
      ? taxon.photoAttribution
      : taxon.offlinePhotoAttribution;
  final license = taxon.offlinePhotoPath == null
      ? taxon.photoLicense
      : taxon.offlinePhotoLicense;
  final broaderMatch =
      _normalizeTaxonName(taxon.name) == _normalizeTaxonName(requestedName)
      ? null
      : 'Species-level image for ${taxon.name}; subspecies not confirmed';
  return [
    ?broaderMatch,
    attribution?.trim().isNotEmpty == true
        ? attribution!
        : 'Photo credit unavailable',
    license?.trim().isNotEmpty == true ? license! : 'License not specified',
  ].join(' · ');
}

String _normalizeTaxonName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
