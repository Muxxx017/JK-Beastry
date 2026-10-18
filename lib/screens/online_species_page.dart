import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zoology_app/data/offline_taxa_store.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/taxonomy_classification.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/screens/species_detail_page.dart';
import 'package:zoology_app/services/inat_service.dart';
import 'package:zoology_app/widgets/zoomable_photo.dart';

class OnlineSpeciesPage extends StatefulWidget {
  final InatService? service;

  const OnlineSpeciesPage({super.key, this.service});

  @override
  State<OnlineSpeciesPage> createState() => _OnlineSpeciesPageState();
}

class _OnlineSpeciesPageState extends State<OnlineSpeciesPage> {
  late final InatService _service;
  late final bool _ownsService;
  final TextEditingController _queryController = TextEditingController();
  List<InatTaxon> _taxa = [];
  int _totalResults = 0;
  int _page = 0;
  bool _hasMoreResults = false;
  bool _plants = false;
  String _placeIds = InatService.jammuKashmirPlaceId;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  Timer? _searchDebounce;
  int _requestVersion = 0;

  List<ZoologySpecies> get _curatedMatches {
    final query = _normalizedSearchTerms(_queryController.text).toSet();
    if (query.isEmpty) return const [];

    return kSpeciesCatalog.where((species) {
      if (_plants != (species.category == 'Plant')) return false;
      final searchableTerms = _normalizedSearchTerms(species.searchableText);
      return query.every(searchableTerms.contains);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _ownsService = widget.service == null;
    _service = widget.service ?? InatService();
    _search();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    if (_ownsService) _service.close();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search({bool nextPage = false}) async {
    if (nextPage && (_loading || _loadingMore)) return;
    _searchDebounce?.cancel();
    final requestVersion = ++_requestVersion;
    final requestedPage = nextPage ? _page + 1 : 1;
    setState(() {
      _error = null;
      if (nextPage) {
        _loadingMore = true;
      } else {
        _loading = true;
        _loadingMore = false;
        _page = 0;
        _hasMoreResults = false;
        _taxa = [];
      }
    });

    try {
      final result = await _service.searchRegionalSpecies(
        query: _queryController.text,
        plants: _plants,
        page: requestedPage,
        placeIds: _placeIds,
      );
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        if (nextPage) {
          _taxa.addAll(result.taxa);
        } else {
          _taxa = result.taxa;
        }
        _totalResults = result.totalResults;
        _page = requestedPage;
        _hasMoreResults = result.hasMore;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () => _search());
  }

  Future<void> _openUrl(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the source page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPageAvailable = _hasMoreResults;
    final curatedMatches = _curatedMatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore species online'),
        actions: [
          IconButton(
            tooltip: 'Offline species',
            icon: const Icon(Icons.download_done_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OfflineSpeciesPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Search species observed in Jammu & Kashmir. '
                    'This live community dataset reaches beyond the curated offline guide, '
                    'but observation records are not a complete census or proof of native range.',
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: DropdownButtonFormField<String>(
                initialValue: _placeIds,
                decoration: const InputDecoration(
                  labelText: 'Observation region',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: InatService.jammuKashmirPlaceId,
                    child: Text('Jammu & Kashmir'),
                  ),
                  DropdownMenuItem(
                    value: InatService.regionalPlaceIds,
                    child: Text('India & neighboring Himalaya'),
                  ),
                ],
                onChanged: (placeIds) {
                  if (placeIds == null) return;
                  setState(() => _placeIds = placeIds);
                  _search();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Animals'),
                    icon: Icon(Icons.pets_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Plants'),
                    icon: Icon(Icons.local_florist_rounded),
                  ),
                ],
                selected: {_plants},
                onSelectionChanged: (selection) {
                  setState(() => _plants = selection.first);
                  _search();
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                key: const Key('onlineSpeciesSearchField'),
                controller: _queryController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  labelText: 'Search names, common or scientific',
                  hintText: 'e.g. snow leopard, orchid, Salmo trutta',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _queryController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _queryController.clear();
                            _search();
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (_) {
                  _requestVersion++;
                  setState(() {
                    _taxa = [];
                    _error = null;
                    _loading = true;
                  });
                  _scheduleSearch();
                },
              ),
            ),
          ),
          if (curatedMatches.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From the offline field guide',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Curated reference entries · separate from online sighting counts',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final species = curatedMatches[index];
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    key: Key('curatedSpecies-${species.id}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SpeciesDetailPage(species: species),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF0E9),
                      child: Icon(
                        species.category == 'Plant'
                            ? Icons.eco_rounded
                            : Icons.pets_rounded,
                        color: const Color(0xFF365B43),
                      ),
                    ),
                    title: Text(species.commonName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          species.scientificName,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          species.funFact,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'OFFLINE FIELD GUIDE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              }, childCount: curatedMatches.length),
            ),
          ],
          if (_taxa.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _queryController.text.trim().isEmpty
                      ? '${_placeIds == InatService.jammuKashmirPlaceId ? 'Jammu & Kashmir' : 'India & neighboring Himalaya'}'
                            '  ·  ${_taxa.length} of $_totalResults observed ${_plants ? 'plant' : 'animal'} species'
                      : '${_taxa.length} observed ${_plants ? 'plant' : 'animal'} species whose names match “${_queryController.text.trim()}”'
                            '${_hasMoreResults ? ' · more matches available' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (_loading && _taxa.isEmpty && curatedMatches.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_loading && _taxa.isEmpty && curatedMatches.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(),
              ),
            ),
          if (!_loading && _error != null && curatedMatches.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 44),
                      const SizedBox(height: 12),
                      const Text('Could not load online species.'),
                      const SizedBox(height: 8),
                      Text(
                        'Check your internet connection and try again. '
                        'Observation records may be incomplete.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _search,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_loading && _error != null && curatedMatches.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_rounded),
                    title: const Text('Online sightings are unavailable'),
                    subtitle: const Text(
                      'Your curated offline guide results remain available.',
                    ),
                    trailing: IconButton(
                      tooltip: 'Retry online search',
                      onPressed: _search,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
              ),
            ),
          if (!_loading &&
              _error == null &&
              _taxa.isEmpty &&
              curatedMatches.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _queryController.text.trim().isEmpty
                        ? 'No observed species are available right now.'
                        : 'No matching observed species or offline guide entries found.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (_taxa.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final taxon = _taxa[index];
                return _OnlineTaxonTile(
                  taxon: taxon,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OnlineTaxonDetailsPage(
                          service: _service,
                          taxon: taxon,
                          placeIds: _placeIds,
                          openUrl: _openUrl,
                        ),
                      ),
                    );
                  },
                );
              }, childCount: _taxa.length),
            ),
          if (nextPageAvailable && !_loading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: OutlinedButton.icon(
                  onPressed: _loadingMore
                      ? null
                      : () => _search(nextPage: true),
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_loadingMore ? 'Loading' : 'Load more species'),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                'Taxonomy and observation counts are provided by iNaturalist. '
                'The totals reflect community observations and can include gaps or misidentifications. '
                'Open a species for its source links and photo credits/licenses.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _normalizedSearchTerms(String value) => value
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((term) => term.isNotEmpty)
    .toList();

class _OnlineTaxonTile extends StatelessWidget {
  final InatTaxon taxon;
  final VoidCallback onTap;

  const _OnlineTaxonTile({required this.taxon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 62,
          height: 62,
          child: taxon.photoUrl == null
              ? const CircleAvatar(child: Icon(Icons.nature_rounded))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    taxon.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
                          color: Color(0xFFE8F1E9),
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                  ),
                ),
        ),
        title: Text(taxon.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taxon.name,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(
              '${taxon.regionalObservations ?? 0} regional observations'
              '${taxon.conservationStatus == null ? '' : ' • ${taxon.conservationStatus}'}',
            ),
            if (taxon.photoUrl != null)
              Text(
                [
                  taxon.photoAttribution ?? 'Photo credit not provided',
                  taxon.photoLicense ?? 'License not specified',
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class OnlineTaxonDetailsPage extends StatefulWidget {
  final InatService service;
  final InatTaxon taxon;
  final String placeIds;
  final Future<void> Function(String url) openUrl;

  const OnlineTaxonDetailsPage({
    super.key,
    required this.service,
    required this.taxon,
    this.placeIds = InatService.regionalPlaceIds,
    required this.openUrl,
  });

  @override
  State<OnlineTaxonDetailsPage> createState() => _OnlineTaxonDetailsPageState();
}

class _OnlineTaxonDetailsPageState extends State<OnlineTaxonDetailsPage> {
  late Future<InatTaxon> _details;
  final OfflineTaxaStore _offlineStore = OfflineTaxaStore();

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<InatTaxon> _loadDetails() {
    return widget.service.getTaxonDetails(widget.taxon.id);
  }

  void _retryDetails() {
    setState(() {
      _details = _loadDetails();
    });
  }

  Future<void> _saveOffline() async {
    try {
      await _offlineStore.save(widget.taxon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Species facts saved for offline reference.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save species facts: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taxon.displayName),
        actions: [
          IconButton(
            tooltip: 'Save species facts offline',
            onPressed: _saveOffline,
            icon: const Icon(Icons.download_for_offline_outlined),
          ),
        ],
      ),
      body: FutureBuilder<InatTaxon>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.taxon.name,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text(
                  'Species · ${widget.taxon.regionalObservations ?? 0} '
                  'regional observations',
                ),
                const SizedBox(height: 18),
                _TaxonomicLineage(
                  service: widget.service,
                  scientificName: widget.taxon.name,
                  openUrl: widget.openUrl,
                ),
                if (widget.taxon.wikipediaUrl != null) ...[
                  const SizedBox(height: 18),
                  _WikipediaSummary(
                    service: widget.service,
                    wikipediaUrl: widget.taxon.wikipediaUrl!,
                    openUrl: widget.openUrl,
                  ),
                ],
                const SizedBox(height: 18),
                _SourceUnavailable(
                  message:
                      'Extra species information is temporarily unavailable. '
                      'Your species record and taxonomy search are still available.',
                  onRetry: _retryDetails,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => widget.openUrl(widget.taxon.taxonUrl),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open iNaturalist record'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final taxon = snapshot.data!;
          final photos = taxon.photos.isNotEmpty
              ? taxon.photos
              : taxon.photoUrl == null
              ? <InatTaxonPhoto>[]
              : [
                  InatTaxonPhoto(
                    url: taxon.photoUrl,
                    attribution: taxon.photoAttribution,
                    license: taxon.photoLicense,
                  ),
                ];
          final curatedSpecies = _curatedSpeciesFor(taxon.name);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                taxon.name,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text(
                'Rank: ${taxon.rank} • Regional observations: '
                '${widget.taxon.regionalObservations ?? 0}',
              ),
              const SizedBox(height: 20),
              _TaxonomicLineage(
                service: widget.service,
                scientificName: taxon.name,
                openUrl: widget.openUrl,
              ),
              const SizedBox(height: 20),
              _CuratedNaturalHistory(
                species: curatedSpecies,
                onlineScientificName: taxon.name,
              ),
              if (taxon.conservationStatus != null) ...[
                const SizedBox(height: 8),
                Text('Conservation: ${taxon.conservationStatus}'),
              ],
              if (taxon.wikipediaUrl != null) ...[
                const SizedBox(height: 20),
                _WikipediaSummary(
                  service: widget.service,
                  wikipediaUrl: taxon.wikipediaUrl!,
                  openUrl: widget.openUrl,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Identification photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (photos.isEmpty)
                const Text(
                  'No reference photos are available for this species.',
                )
              else
                ...photos.map(
                  (photo) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ZoomablePhoto(
                            key: ValueKey('onlineSpeciesPhoto-${photo.url}'),
                            url: photo.url!,
                            width: double.infinity,
                            height: 240,
                            attribution: photo.attribution,
                            license: photo.license,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            if (photo.attribution != null) photo.attribution!,
                            'License: ${photo.license ?? 'All rights reserved / not specified'}',
                          ].join(' • '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => widget.openUrl(taxon.taxonUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open full iNaturalist record'),
              ),
              if (taxon.wikipediaUrl != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => widget.openUrl(taxon.wikipediaUrl!),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Open encyclopedia article'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => widget.openUrl(
                  'https://www.inaturalist.org/observations?taxon_id=${taxon.id}&place_id=${widget.placeIds}',
                ),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('View regional observations'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Community observations can be misidentified or incomplete. '
                'Check multiple features and expert sources before making a final identification.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class OfflineSpeciesPage extends StatefulWidget {
  const OfflineSpeciesPage({super.key});

  @override
  State<OfflineSpeciesPage> createState() => _OfflineSpeciesPageState();
}

class _OfflineSpeciesPageState extends State<OfflineSpeciesPage> {
  final OfflineTaxaStore _store = OfflineTaxaStore();
  late Future<List<InatTaxon>> _savedTaxa;

  @override
  void initState() {
    super.initState();
    _savedTaxa = _store.load();
  }

  Future<void> _remove(int id) async {
    try {
      await _store.remove(id);
      if (!mounted) return;
      setState(() => _savedTaxa = _store.load());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove species: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline species')),
      body: FutureBuilder<List<InatTaxon>>(
        future: _savedTaxa,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load saved species: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final taxa = snapshot.data!;
          if (taxa.isEmpty) {
            return const Center(
              child: Text(
                'Open a species online and save its facts for offline use.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Names and species facts are stored on this device. Reference photos and full articles still need internet.',
                ),
              ),
              ...taxa.map(
                (taxon) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_rounded),
                    title: Text(taxon.displayName),
                    subtitle: Text(
                      '${taxon.name} • ${taxon.rank}'
                      '${taxon.conservationStatus == null ? '' : ' • ${taxon.conservationStatus}'}',
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _CachedTaxonPage(taxon: taxon),
                        ),
                      );
                    },
                    trailing: IconButton(
                      tooltip: 'Remove offline record',
                      onPressed: () => _remove(taxon.id),
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CachedTaxonPage extends StatelessWidget {
  final InatTaxon taxon;

  const _CachedTaxonPage({required this.taxon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(taxon.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            taxon.name,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text('Rank: ${taxon.rank}'),
          if (taxon.regionalObservations != null)
            Text('Regional observations: ${taxon.regionalObservations}'),
          if (taxon.conservationStatus != null)
            Text('Conservation: ${taxon.conservationStatus}'),
          const SizedBox(height: 20),
          const Text(
            'Cached facts only. Reference images and encyclopedia information are shown online and are not stored in this offline record.',
          ),
          const SizedBox(height: 8),
          if (taxon.photoAttribution != null)
            Text('Photo credit: ${taxon.photoAttribution}'),
          if (taxon.photoLicense != null)
            Text('Photo license: ${taxon.photoLicense}'),
        ],
      ),
    );
  }
}

ZoologySpecies? _curatedSpeciesFor(String scientificName) {
  final onlineName = _normalizedSearchTerms(scientificName).take(2).join(' ');
  for (final species in kSpeciesCatalog) {
    final curatedName = _normalizedSearchTerms(species.scientificName)
        .take(2)
        .join(' ');
    if (curatedName == onlineName) {
      return species;
    }
  }
  return null;
}

class _CuratedNaturalHistory extends StatelessWidget {
  final ZoologySpecies? species;
  final String onlineScientificName;

  const _CuratedNaturalHistory({
    required this.species,
    required this.onlineScientificName,
  });

  @override
  Widget build(BuildContext context) {
    final item = species;
    if (item == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Natural history & fun fact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'A curated fact sheet is not available for this species yet. '
            'The encyclopedia overview and source links below are provided separately.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Natural history & fun fact',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (item.scientificName.toLowerCase() !=
            onlineScientificName.trim().toLowerCase()) ...[
          const SizedBox(height: 4),
          Text(
            'Related offline guide profile: ${item.commonName} '
            '(${item.scientificName}). It shares the same genus and species '
            'name; subspecies or accepted names may differ.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 10),
        _naturalHistoryField(context, 'Characteristics', item.feature),
        _naturalHistoryField(context, 'Identification', item.identification),
        _naturalHistoryField(context, 'Habitat', item.habitat),
        _naturalHistoryField(
          context,
          'Range & local records',
          item.distribution,
        ),
        _naturalHistoryField(context, 'Diet', item.diet),
        _naturalHistoryField(context, 'Habit & behavior', item.behavior),
        _naturalHistoryField(context, 'Life cycle & breeding', item.breeding),
        _naturalHistoryField(context, 'Ecological role', item.ecologicalRole),
        _naturalHistoryField(context, 'Threats', item.threats),
        _naturalHistoryField(context, 'Conservation status', item.conservation),
        if (item.funFact.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFFEAF0E9),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fun fact',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(item.funFact),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Source: curated offline Jammu & Kashmir field guide. '
          'Use the linked specialist references to verify identification and conservation details.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

Widget _naturalHistoryField(BuildContext context, String label, String value) {
  if (value.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}

class _WikipediaSummary extends StatefulWidget {
  final InatService service;
  final String wikipediaUrl;
  final Future<void> Function(String url) openUrl;

  const _WikipediaSummary({
    required this.service,
    required this.wikipediaUrl,
    required this.openUrl,
  });

  @override
  State<_WikipediaSummary> createState() => _WikipediaSummaryState();
}

class _WikipediaSummaryState extends State<_WikipediaSummary> {
  late Future<String?> _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.service.getWikipediaSummary(widget.wikipediaUrl);
  }

  void _load() {
    setState(() {
      _summary = widget.service.getWikipediaSummary(widget.wikipediaUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _summary,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Natural history overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (snapshot.hasError)
              _SourceUnavailable(
                message:
                    'The encyclopedia overview is temporarily unavailable.',
                onRetry: _load,
              )
            else if (snapshot.connectionState != ConnectionState.done)
              const LinearProgressIndicator()
            else
              Text(
                snapshot.data == null || snapshot.data!.isEmpty
                    ? 'No encyclopedia summary is available.'
                    : snapshot.data!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(height: 1.55, color: const Color(0xFF39433A)),
              ),
            const SizedBox(height: 6),
            const Text(
              'Source: Wikipedia. For regional identification and scientific detail, consult specialist references.',
            ),
            OutlinedButton.icon(
              onPressed: () => widget.openUrl(widget.wikipediaUrl),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open source article'),
            ),
          ],
        );
      },
    );
  }
}

class _TaxonomicLineage extends StatefulWidget {
  final InatService service;
  final String scientificName;
  final Future<void> Function(String url) openUrl;

  const _TaxonomicLineage({
    required this.service,
    required this.scientificName,
    required this.openUrl,
  });

  @override
  State<_TaxonomicLineage> createState() => _TaxonomicLineageState();
}

class _TaxonomicLineageState extends State<_TaxonomicLineage> {
  late Future<TaxonomyClassification?> _classification;

  @override
  void initState() {
    super.initState();
    _classification = widget.service.getTaxonomicClassification(
      widget.scientificName,
    );
  }

  void _load() {
    setState(() {
      _classification = widget.service.getTaxonomicClassification(
        widget.scientificName,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<TaxonomyClassification?>(
          future: _classification,
          builder: (context, snapshot) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scientific classification',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (snapshot.connectionState != ConnectionState.done)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  _SourceUnavailable(
                    message: 'Taxonomy could not be loaded right now.',
                    onRetry: _load,
                  )
                else if (snapshot.data == null || snapshot.data!.ranks.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No confident classification match was returned. '
                        'Check the accepted name in a taxonomic database.',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => widget.openUrl(
                          Uri.https('www.gbif.org', '/tools/species-lookup', {
                            'search': widget.scientificName,
                          }).toString(),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text('Search GBIF taxonomy'),
                      ),
                    ],
                  )
                else ...[
                  ...snapshot.data!.ranks.map(
                    (rank) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(
                              rank.key,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rank.value,
                              style: TextStyle(
                                fontStyle:
                                    rank.key == 'Species' || rank.key == 'Genus'
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.data!.scientificName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'GBIF match: ${snapshot.data!.scientificName}'
                        '${snapshot.data!.taxonomicStatus == null ? '' : ' · ${snapshot.data!.taxonomicStatus}'}'
                        '${snapshot.data!.confidence == null ? '' : ' · ${snapshot.data!.confidence}% match'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  if (snapshot.data!.sourceUrl != null)
                    TextButton.icon(
                      onPressed: () =>
                          widget.openUrl(snapshot.data!.sourceUrl!),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Taxonomy source: GBIF'),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SourceUnavailable extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SourceUnavailable({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
