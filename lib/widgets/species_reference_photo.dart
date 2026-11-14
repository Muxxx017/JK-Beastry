import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/widgets/local_species_photo.dart';

const _speciesAssetFileNames = <String, String>{
  'asian-giant-hornet': 'asian-giant-hornet',
  'asian-palm-civet': 'asian-palm-civet',
  'bar-headed-goose': 'bar-headed-goose',
  'barking-deer': 'barking-deer',
  'bharal': 'bharal',
  'black-necked-crane': 'black-necked-crane',
  'blue-emperor-dragonfly': 'blue-emperor-dragonfly',
  'blue-whistling-thrush': 'blue-whistling-thrush',
  'blunt-snout-snow-trout': 'blunt-snout-snow-trout',
  'brown-trout': 'brown-trout',
  'burrowing-frog': 'burrowing-frog',
  'checkered-keelback': 'checkered-keelback',
  'cheer-pheasant': 'cheer-pheasant',
  'chukar-partridge': 'chukar-partridge',
  'cliff-racer': 'cliff-racer',
  'common-asian-toad': 'common-asian-toad',
  'common-kestrel': 'common-kestrel',
  'common-kingfisher': 'common-kingfisher',
  'common-krait': 'common-krait',
  'common-leopard': 'common-leopard',
  'common-moorhen': 'common-moorhen',
  'common-peacock-butterfly': 'common-peacock-butterfly',
  'common-rat-snake': 'common-rat-snake',
  'common-wolf-snake': 'common-wolf-snake',
  'dhole': 'dhole',
  'eurasian-collared-dove': 'eurasian-collared-dove',
  'eurasian-coot': 'eurasian-coot',
  'eurasian-eagle-owl': 'eurasian-eagle-owl',
  'eurasian-lynx': 'eurasian-lynx',
  'eurasian-otter': 'eurasian-otter',
  'european-turtle-dove': 'european-turtle-dove',
  'five-striped-palm-squirrel': 'five-striped-palm-squirrel',
  'four-spotted-chaser': 'four-spotted-chaser',
  'golden-eagle': 'golden-eagle',
  'golden-jackal': 'golden-jackal',
  'golden-mahseer': 'golden-mahseer',
  'great-barbet': 'great-barbet',
  'greater-horseshoe-bat': 'greater-horseshoe-bat',
  'grey-heron': 'grey-heron',
  'hangul': 'hangul',
  'hill-pigeon': 'hill-pigeon',
  'himalayan-black-bear': 'himalayan-black-bear',
  'himalayan-brown-bear': 'himalayan-brown-bear',
  'himalayan-bumblebee': 'himalayan-bumblebee',
  'himalayan-goral': 'himalayan-goral',
  'himalayan-griffon': 'himalayan-griffon',
  'himalayan-ground-skink': 'himalayan-ground-skink',
  'himalayan-ibex': 'himalayan-ibex',
  'himalayan-keelback': 'himalayan-keelback',
  'himalayan-marmot': 'himalayan-marmot',
  'himalayan-pit-viper': 'himalayan-pit-viper',
  'himalayan-rock-scorpion': 'himalayan-rock-scorpion',
  'himalayan-serow': 'himalayan-serow',
  'himalayan-snowcock': 'himalayan-snowcock',
  'himalayan-tahr': 'himalayan-tahr',
  'himalayan-toad': 'himalayan-toad',
  'himalayan-weasel': 'himalayan-weasel',
  'himalayan-wolf': 'himalayan-wolf',
  'himalayan-woodpecker': 'himalayan-woodpecker',
  'indian-bullfrog': 'indian-bullfrog',
  'indian-cobra': 'indian-cobra',
  'indian-crested-porcupine': 'indian-crested-porcupine',
  'indian-flapshell-turtle': 'indian-flapshell-turtle',
  'indian-pangolin': 'indian-pangolin',
  'indian-tortoiseshell': 'indian-tortoiseshell',
  'jungle-cat': 'jungle-cat',
  'kalij-pheasant': 'kalij-pheasant',
  'kashmir-apollo': 'kashmir-apollo',
  'kashmir-cave-bat': 'kashmir-cave-bat',
  'kashmir-cricket-frog': 'kashmir-cricket-frog',
  'kashmir-flycatcher': 'kashmir-flycatcher',
  'kashmir-flying-squirrel': 'kashmir-flying-squirrel',
  'kashmir-musk-deer': 'kashmir-musk-deer',
  'kashmir-nuthatch': 'kashmir-nuthatch',
  'kashmir-paa-frog': 'kashmir-paa-frog',
  'kashmir-rock-agama': 'kashmir-rock-agama',
  'kashmir-snow-trout': 'kashmir-snow-trout',
  'kashmir-stag-beetle': 'kashmir-stag-beetle',
  'kashmir-stone-loach': 'kashmir-stone-loach',
  'kashmir-swallowtail': 'kashmir-swallowtail',
  'kashmir-torrent-catfish': 'kashmir-torrent-catfish',
  'kashmiri-rock-agama': 'kashmir-rock-agama',
  'koklass-pheasant': 'koklass-pheasant',
  'ladakh-pika': 'ladakh-pika',
  'ladakh-toad': 'ladakh-toad',
  'ladakh-toad-headed-agama': 'ladakh-toad-headed-agama',
  'ladakh-urial': 'ladakh-urial',
  'ladybird': 'ladybird',
  'lammergeier': 'lammergeier',
  'langur': 'langur',
  'large-cabbage-white': 'large-cabbage-white',
  'laughing-dove': 'laughing-dove',
  'leopard-cat': 'leopard-cat',
  'levantine-viper': 'levantine-viper',
  'long-tailed-marmot': 'long-tailed-marmot',
  'mallard': 'mallard',
  'markhor': 'markhor',
  'monal': 'monal',
  'mountain-weasel': 'mountain-weasel',
  'murree-hills-frog': 'murree-hills-frog',
  'musk-deer': 'kashmir-musk-deer',
  'noble-apollo': 'noble-apollo',
  'northern-pintail': 'northern-pintail',
  'oriental-turtle-dove': 'oriental-turtle-dove',
  'pallas-cat': 'pallas-cat',
  'peregrine-falcon': 'peregrine-falcon',
  'pied-kingfisher': 'pied-kingfisher',
  'rainbow-trout': 'rainbow-trout',
  'red-billed-chough': 'red-billed-chough',
  'red-collared-dove': 'red-collared-dove',
  'red-fox': 'red-fox',
  'rhesus-macaque': 'rhesus-macaque',
  'rock-pigeon': 'rock-pigeon',
  'royle-pika': 'royle-pika',
  'ruddy-shelduck': 'ruddy-shelduck',
  'russell-viper': 'russell-viper',
  'sambar': 'sambar',
  'sattar-snow-trout': 'sattar-snow-trout',
  'skardu-toad': 'skardu-toad',
  'skittering-frog': 'skittering-frog',
  'slaty-headed-parakeet': 'slaty-headed-parakeet',
  'small-indian-mongoose': 'small-indian-mongoose',
  'smooth-coated-otter': 'smooth-coated-otter',
  'snow-leopard': 'snow-leopard',
  'snow-pigeon': 'snow-pigeon',
  'speckled-wood-pigeon': 'speckled-wood-pigeon',
  'spotted-dove': 'spotted-dove',
  'steppe-eagle': 'steppe-eagle',
  'stoat': 'stoat',
  'stoliczka-gecko': 'stoliczka-gecko',
  'stone-marten': 'stone-marten',
  'striped-hyena': 'striped-hyena',
  'tibetan-antelope': 'tibetan-antelope',
  'tibetan-argali': 'tibetan-argali',
  'tibetan-gazelle': 'tibetan-gazelle',
  'tibetan-sand-fox': 'tibetan-sand-fox',
  'tibetan-wild-ass': 'tibetan-wild-ass',
  'wallcreeper': 'wallcreeper',
  'wedge-tailed-green-pigeon': 'wedge-tailed-green-pigeon',
  'western-tragopan': 'western-tragopan',
  'white-capped-redstart': 'white-capped-redstart',
  'white-throated-kingfisher': 'white-throated-kingfisher',
  'wild-boar': 'wild-boar',
  'woolly-hare': 'woolly-hare',
  'yellow-billed-chough': 'yellow-billed-chough',
  'yellow-throated-marten': 'yellow-throated-marten',
};

const _bundledSpeciesAssets = <String>{
  'asian-giant-hornet',
  'asian-palm-civet',
  'bar-headed-goose',
  'barking-deer',
  'bharal',
  'black-necked-crane',
  'blue-emperor-dragonfly',
  'blue-whistling-thrush',
  'blunt-snout-snow-trout',
  'brown-trout',
  'burrowing-frog',
  'checkered-keelback',
  'cheer-pheasant',
  'chukar-partridge',
  'cliff-racer',
  'common-asian-toad',
  'common-kestrel',
  'common-kingfisher',
  'common-krait',
  'common-leopard',
  'common-moorhen',
  'common-peacock-butterfly',
  'common-rat-snake',
  'common-wolf-snake',
  'dhole',
  'eurasian-collared-dove',
  'eurasian-coot',
  'eurasian-eagle-owl',
  'eurasian-lynx',
  'eurasian-otter',
  'european-turtle-dove',
  'five-striped-palm-squirrel',
  'four-spotted-chaser',
  'golden-eagle',
  'golden-jackal',
  'golden-mahseer',
  'great-barbet',
  'greater-horseshoe-bat',
  'grey-heron',
  'hangul',
  'hill-pigeon',
  'himalayan-black-bear',
  'himalayan-brown-bear',
  'himalayan-bumblebee',
  'himalayan-goral',
  'himalayan-griffon',
  'himalayan-ground-skink',
  'himalayan-ibex',
  'himalayan-keelback',
  'himalayan-marmot',
  'himalayan-pit-viper',
  'himalayan-rock-scorpion',
  'himalayan-serow',
  'himalayan-snowcock',
  'himalayan-tahr',
  'himalayan-toad',
  'himalayan-weasel',
  'himalayan-wolf',
  'himalayan-woodpecker',
  'indian-bullfrog',
  'indian-cobra',
  'indian-crested-porcupine',
  'indian-flapshell-turtle',
  'indian-pangolin',
  'indian-tortoiseshell',
  'jungle-cat',
  'kalij-pheasant',
  'kashmir-apollo',
  'kashmir-cave-bat',
  'kashmir-cricket-frog',
  'kashmir-flycatcher',
  'kashmir-flying-squirrel',
  'kashmir-musk-deer',
  'kashmir-nuthatch',
  'kashmir-paa-frog',
  'kashmir-rock-agama',
  'kashmir-snow-trout',
  'kashmir-stag-beetle',
  'kashmir-stone-loach',
  'kashmir-swallowtail',
  'kashmir-torrent-catfish',
  'kashmiri-rock-agama',
  'koklass-pheasant',
  'ladakh-pika',
  'ladakh-toad',
  'ladakh-toad-headed-agama',
  'ladakh-urial',
  'ladybird',
  'lammergeier',
  'langur',
  'large-cabbage-white',
  'laughing-dove',
  'leopard-cat',
  'levantine-viper',
  'long-tailed-marmot',
  'mallard',
  'markhor',
  'monal',
  'mountain-weasel',
  'murree-hills-frog',
  'musk-deer',
  'noble-apollo',
  'northern-pintail',
  'oriental-turtle-dove',
  'pallas-cat',
  'peregrine-falcon',
  'pied-kingfisher',
  'rainbow-trout',
  'red-billed-chough',
  'red-collared-dove',
  'red-fox',
  'rhesus-macaque',
  'rock-pigeon',
  'royle-pika',
  'ruddy-shelduck',
  'russell-viper',
  'sambar',
  'sattar-snow-trout',
  'skardu-toad',
  'skittering-frog',
  'slaty-headed-parakeet',
  'small-indian-mongoose',
  'smooth-coated-otter',
  'snow-leopard',
  'snow-pigeon',
  'speckled-wood-pigeon',
  'spotted-dove',
  'steppe-eagle',
  'stoat',
  'stoliczka-gecko',
  'stone-marten',
  'striped-hyena',
  'tibetan-antelope',
  'tibetan-argali',
  'tibetan-gazelle',
  'tibetan-sand-fox',
  'tibetan-wild-ass',
  'wallcreeper',
  'wedge-tailed-green-pigeon',
  'western-tragopan',
  'white-capped-redstart',
  'white-throated-kingfisher',
  'wild-boar',
  'woolly-hare',
  'yellow-billed-chough',
  'yellow-throated-marten',
};

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
    // 1. Check if an offline saved photo exists on device
    try {
      final saved = await OfflineTaxaStore().findByScientificName(
        widget.species.scientificName,
      );
      if (saved?.offlinePhotoPath != null) return saved;
    } catch (_) {}

    // 2. If species has a direct curated imageUrl, return it
    if (widget.species.imageUrl.trim().isNotEmpty) {
      return InatTaxon(
        id: widget.species.id.hashCode.abs(),
        name: widget.species.scientificName,
        commonName: widget.species.commonName,
        rank: 'species',
        regionalObservations: null,
        totalObservations: 1,
        conservationStatus: widget.species.conservation,
        photoUrl: widget.species.imageUrl,
        photoAttribution: widget.species.imageAttribution.trim().isNotEmpty
            ? widget.species.imageAttribution
            : 'Reference photo',
        photoLicense: widget.species.imageLicense.trim().isNotEmpty
            ? widget.species.imageLicense
            : 'CC BY-SA',
        photoSourceUrl: widget.species.imageUrl,
        wikipediaUrl:
            'https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.species.scientificName)}',
      );
    }

    // 3. Otherwise try online lookup
    try {
      final taxon = await _service.findTaxonByScientificName(
        widget.species.scientificName,
      );
      if (taxon != null && taxon.photoUrl != null) return taxon;
      final photo = await _service.findCommonsPhoto(
        taxon?.name ?? widget.species.scientificName,
      );
      if (photo == null) return taxon;
      if (taxon != null) {
        return taxon.copyWith(
          photoUrl: photo.url,
          photoAttribution: photo.attribution,
          photoLicense: photo.license,
          photoSourceUrl: photo.sourceUrl,
        );
      }
      return InatTaxon(
        id: widget.species.id.hashCode.abs(),
        name: widget.species.scientificName,
        commonName: widget.species.commonName,
        rank: 'species',
        regionalObservations: null,
        totalObservations: 1,
        conservationStatus: widget.species.conservation,
        photoUrl: photo.url,
        photoAttribution: photo.attribution,
        photoLicense: photo.license,
        photoSourceUrl: photo.sourceUrl,
        wikipediaUrl:
            'https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.species.scientificName)}',
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    if (_ownsService) _service.close();
    super.dispose();
  }

  Future<void> _openPhotoSource(InatTaxon taxon) async {
    final rawUrl = taxon.photoSourceUrl ?? taxon.photoUrl;
    if (rawUrl == null) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showPhoto(InatTaxon taxon) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: _bundledSpeciesAssets.contains(widget.species.id)
                      ? Image.asset(
                          'assets/species/${_speciesAssetFileNames[widget.species.id] ?? widget.species.id}.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _ZoologicalArtPlate(
                            species: widget.species,
                            fit: BoxFit.contain,
                          ),
                        )
                      : (taxon.offlinePhotoPath != null && !kIsWeb)
                          ? LocalSpeciesPhoto(
                              path: taxon.offlinePhotoPath!,
                              fit: BoxFit.contain,
                            )
                          : Image.network(
                              taxon.offlinePhotoUrl ?? taxon.photoUrl ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => _ZoologicalArtPlate(
                                species: widget.species,
                                fit: BoxFit.contain,
                              ),
                            ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                tooltip: 'Close photo',
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _photoCredit(taxon, requestedName: widget.species.scientificName),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    if (taxon.photoSourceUrl != null)
                      TextButton.icon(
                        onPressed: () => _openPhotoSource(taxon),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('View image source', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we have a local bundled asset, load it immediately without waiting for FutureBuilder
    final bundledAsset = _speciesAssetFileNames[widget.species.id];
    if (bundledAsset != null) {
      final taxon = InatTaxon(
        id: widget.species.id.hashCode.abs(),
        name: widget.species.scientificName,
        commonName: widget.species.commonName,
        rank: 'species',
        regionalObservations: null,
        totalObservations: 1,
        conservationStatus: widget.species.conservation,
        photoUrl: widget.species.imageUrl,
        photoAttribution: widget.species.imageAttribution.trim().isNotEmpty
            ? widget.species.imageAttribution
            : 'Reference photo',
        photoLicense: widget.species.imageLicense.trim().isNotEmpty
            ? widget.species.imageLicense
            : 'CC BY-SA',
        photoSourceUrl: widget.species.imageUrl,
        wikipediaUrl:
            'https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.species.scientificName)}',
      );

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
                Image.asset(
                  'assets/species/$bundledAsset.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _ZoologicalArtPlate(species: widget.species),
                ),
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
                        maxLines: 1,
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
    }

    return FutureBuilder<InatTaxon?>(
      future: _taxon,
      builder: (context, snapshot) {
        final taxon = snapshot.data;
        if (taxon == null || (taxon.offlinePhotoPath == null && taxon.photoUrl == null)) {
          return SizedBox(
            height: widget.height,
            width: double.infinity,
            child: _ZoologicalArtPlate(species: widget.species),
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
                  _PhotoImage(taxon: taxon, species: widget.species, fit: BoxFit.cover),
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
                          maxLines: 1,
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
  final ZoologySpecies species;
  final BoxFit fit;

  const _PhotoImage({
    required this.taxon,
    required this.species,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final localPath = taxon.offlinePhotoPath;
    if (localPath != null && !kIsWeb) {
      return LocalSpeciesPhoto(path: localPath, fit: fit);
    }

    final url = taxon.offlinePhotoUrl ?? taxon.photoUrl;
    if (url == null || url.isEmpty) {
      return _ZoologicalArtPlate(species: species, fit: fit);
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          _ZoologicalArtPlate(species: species, fit: fit),
    );
  }
}

class _ZoologicalArtPlate extends StatelessWidget {
  final ZoologySpecies species;
  final BoxFit fit;

  const _ZoologicalArtPlate({required this.species, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final gradient = _categoryGradient(species.category);
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Opacity(
              opacity: 0.16,
              child: Icon(
                _categoryIcon(species.category),
                size: 110,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    species.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  species.commonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [Shadow(blurRadius: 3, color: Colors.black45)],
                  ),
                ),
                Text(
                  species.scientificName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _categoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'mammal':
        return const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF4A6572)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'bird':
        return const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'reptile':
        return const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF8D6E63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'amphibian':
        return const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'fish':
        return const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'insect':
        return const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFFA726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF37474F), Color(0xFF78909C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mammal':
        return Icons.pets_rounded;
      case 'bird':
        return Icons.flutter_dash_rounded;
      case 'reptile':
      case 'amphibian':
        return Icons.pest_control_rodent_rounded;
      case 'fish':
        return Icons.phishing_rounded;
      case 'insect':
        return Icons.bug_report_rounded;
      default:
        return Icons.nature_rounded;
    }
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
        : 'Reference specimen photo',
    license?.trim().isNotEmpty == true ? license! : 'CC BY-SA',
  ].join(' · ');
}

String _normalizeTaxonName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
