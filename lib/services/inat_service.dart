import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zoology_app/models/inat_taxon.dart';
import 'package:zoology_app/models/taxonomy_classification.dart';

class InatSpeciesPage {
  final List<InatTaxon> taxa;
  final int totalResults;
  final bool hasMore;

  const InatSpeciesPage({
    required this.taxa,
    required this.totalResults,
    this.hasMore = false,
  });
}

class InatService {
  static const animalsTaxonId = 1;
  static const plantsTaxonId = 47126;
  static const jammuKashmirPlaceId = '184749';
  static const regionalPlaceIds = '6681,7335,7707,7076,6903,7341';
  static const pageSize = 50;

  final http.Client _client;

  InatService({http.Client? client}) : _client = client ?? http.Client();

  Future<InatSpeciesPage> searchRegionalSpecies({
    required String query,
    required bool plants,
    int page = 1,
    String placeIds = jammuKashmirPlaceId,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isNotEmpty) {
      return _searchNamedRegionalSpecies(
        query: normalizedQuery,
        plants: plants,
        page: page,
        placeIds: placeIds,
      );
    }

    final parameters = <String, String>{
      'place_id': placeIds,
      'taxon_id': '${plants ? plantsTaxonId : animalsTaxonId}',
      'rank': 'species',
      'quality_grade': 'research',
      'per_page': '$pageSize',
      'page': '$page',
      'order': 'desc',
      'order_by': 'observations_count',
    };
    final json = await _getJson(
      Uri.https(
        'api.inaturalist.org',
        '/v1/observations/species_counts',
        parameters,
      ),
    );
    final results = json['results'] as List<dynamic>;
    final taxa = results
        .whereType<Map<String, dynamic>>()
        .map(InatTaxon.fromSpeciesCountJson)
        .toList();
    return InatSpeciesPage(
      taxa: taxa,
      totalResults: json['total_results'] as int? ?? taxa.length,
      hasMore: page * pageSize < (json['total_results'] as int? ?? taxa.length),
    );
  }

  Future<InatSpeciesPage> _searchNamedRegionalSpecies({
    required String query,
    required bool plants,
    required int page,
    required String placeIds,
  }) async {
    final matchingTaxaJson = await _getJson(
      Uri.https('api.inaturalist.org', '/v1/taxa/autocomplete', {
        'q': query,
        'taxon_id': '${plants ? plantsTaxonId : animalsTaxonId}',
        'rank': 'species',
        'per_page': '$pageSize',
        'page': '$page',
      }),
    );
    final taxonRecords = matchingTaxaJson['results'] as List<dynamic>;
    final queryTerms = query.toLowerCase().split(RegExp(r'\s+'));
    final matchingTaxa = taxonRecords
        .whereType<Map<String, dynamic>>()
        .map(InatTaxon.fromAutocompleteJson)
        .where((taxon) {
          final searchableName = '${taxon.name} ${taxon.commonName ?? ''}'
              .toLowerCase();
          return queryTerms.every(searchableName.contains);
        })
        .toList();

    if (matchingTaxa.isEmpty) {
      final totalMatches = matchingTaxaJson['total_results'] as int? ?? 0;
      return InatSpeciesPage(
        taxa: const [],
        totalResults: 0,
        hasMore: page * pageSize < totalMatches,
      );
    }

    final countsJson = await _getJson(
      Uri.https('api.inaturalist.org', '/v1/observations/species_counts', {
        'place_id': placeIds,
        'taxon_id': matchingTaxa.map((taxon) => taxon.id).join(','),
        'rank': 'species',
        'quality_grade': 'research',
        'per_page': '$pageSize',
        'order': 'desc',
        'order_by': 'observations_count',
      }),
    );
    final counts = countsJson['results'] as List<dynamic>;
    final taxa = counts
        .whereType<Map<String, dynamic>>()
        .map(InatTaxon.fromSpeciesCountJson)
        .where((taxon) {
          final searchableName = '${taxon.name} ${taxon.commonName ?? ''}'
              .toLowerCase();
          return queryTerms.every(searchableName.contains);
        })
        .toList();
    final matchingTaxaCount = matchingTaxaJson['total_results'] as int? ?? 0;
    return InatSpeciesPage(
      taxa: taxa,
      totalResults: countsJson['total_results'] as int? ?? taxa.length,
      hasMore: page * pageSize < matchingTaxaCount,
    );
  }

  Future<InatTaxon> getTaxonDetails(int id) async {
    final json = await _getJson(
      Uri.https('api.inaturalist.org', '/v1/taxa/$id', {'locale': 'en'}),
    );
    final results = json['results'] as List<dynamic>;
    if (results.isEmpty || results.first is! Map<String, dynamic>) {
      throw const FormatException('The species record was not found.');
    }
    return InatTaxon.fromDetailJson(results.first as Map<String, dynamic>);
  }

  Future<TaxonomyClassification?> getTaxonomicClassification(
    String scientificName,
  ) async {
    final json = await _getJson(
      Uri.https('api.gbif.org', '/v1/species/match', {
        'name': scientificName,
        'verbose': 'false',
      }),
      source: 'GBIF',
    );
    final confidence = json['confidence'];
    if (json['usageKey'] is! int ||
        json['scientificName'] is! String ||
        json['matchType'] == 'NONE' ||
        (confidence is int && confidence < 80)) {
      return null;
    }
    return TaxonomyClassification.fromJson(json);
  }

  Future<String?> getWikipediaSummary(String wikipediaUrl) async {
    final title = Uri.parse(wikipediaUrl).pathSegments.last;
    final json = await _getJson(
      Uri.https('en.wikipedia.org', '/api/rest_v1/page/summary/$title'),
      source: 'Wikipedia',
    );
    return json['extract'] as String?;
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    String source = 'iNaturalist',
  }) async {
    final response = await _client
        .get(uri, headers: const {'User-Agent': 'JandKBestiary/1.0'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        '$source returned HTTP ${response.statusCode}. Please try again later.',
        uri,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected species data from iNaturalist.');
    }
    return decoded;
  }

  void close() => _client.close();
}
