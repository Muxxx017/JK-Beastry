import 'dart:convert';
import 'dart:typed_data';

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
        'per_page': '$pageSize',
        'page': '$page',
      }),
    );
    final taxonRecords = matchingTaxaJson['results'] as List<dynamic>;
    final queryTerms = _searchTerms(query);
    final matchingTaxa = taxonRecords
        .whereType<Map<String, dynamic>>()
        .map(InatTaxon.fromAutocompleteJson)
        .where((taxon) => _nameMatchesQuery(taxon, queryTerms))
        .toList();

    if (matchingTaxa.isEmpty) {
      final totalMatches = matchingTaxaJson['total_results'] as int? ?? 0;
      return InatSpeciesPage(
        taxa: const [],
        totalResults: 0,
        hasMore: page * pageSize < totalMatches,
      );
    }

    try {
      final countsJson = await _getJson(
        Uri.https('api.inaturalist.org', '/v1/observations/species_counts', {
          'place_id': placeIds,
          'taxon_id': matchingTaxa.map((taxon) => taxon.id).join(','),
          'rank': 'species',
          'quality_grade': 'research',
          'per_page': '$pageSize',
          'page': '$page',
          'order': 'desc',
          'order_by': 'observations_count',
        }),
      );
      final counts = countsJson['results'] as List<dynamic>;
      final countedTaxa = counts
          .whereType<Map<String, dynamic>>()
          .map(InatTaxon.fromSpeciesCountJson)
          .where((taxon) => _nameMatchesQuery(taxon, queryTerms))
          .toList();

      final matchingTaxaCount =
          matchingTaxaJson['total_results'] as int? ?? countedTaxa.length;
      return InatSpeciesPage(
        taxa: countedTaxa,
        totalResults: countsJson['total_results'] as int? ?? countedTaxa.length,
        hasMore: page * pageSize < matchingTaxaCount,
      );
    } catch (_) {
      return InatSpeciesPage(
        taxa: matchingTaxa,
        totalResults: matchingTaxa.length,
        hasMore: false,
      );
    }
  }

  List<String> _searchTerms(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((term) => term.isNotEmpty)
      .toList();

  bool _nameMatchesQuery(InatTaxon taxon, List<String> queryTerms) {
    final nameTerms = _searchTerms('${taxon.name} ${taxon.commonName ?? ''}');
    return queryTerms.every(nameTerms.contains);
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

  Future<InatTaxon?> findTaxonByScientificName(
    String scientificName, {
    bool allowBinomialFallback = true,
  }) async {
    final normalizedName = _normalizeScientificName(scientificName);
    if (normalizedName.isEmpty) return null;

    final exactMatch = await _findExactTaxon(normalizedName);
    if (exactMatch != null || !allowBinomialFallback) return exactMatch;

    final terms = normalizedName.split(' ');
    if (terms.length < 3) return null;
    return _findExactTaxon(terms.take(2).join(' '));
  }

  Future<InatTaxon?> _findExactTaxon(String scientificName) async {
    try {
      final json = await _getJson(
        Uri.https('api.inaturalist.org', '/v1/taxa/autocomplete', {
          'q': scientificName,
          'per_page': '10',
        }),
      );
      final results = json['results'];
      if (results is! List) return null;

      for (final result in results.whereType<Map<String, dynamic>>()) {
        final taxonName = result['name'];
        if (taxonName is String) {
          final normalized = _normalizeScientificName(taxonName);
          if (normalized == scientificName ||
              normalized.startsWith(scientificName) ||
              scientificName.startsWith(normalized)) {
            return InatTaxon.fromAutocompleteJson(result);
          }
        }
      }
      for (final result in results.whereType<Map<String, dynamic>>()) {
        if (result['default_photo'] != null) {
          return InatTaxon.fromAutocompleteJson(result);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<Uint8List> downloadReusablePhoto(InatTaxon taxon) async {
    final photo = taxon.reusableOfflinePhoto;
    if (photo == null) {
      throw StateError(
        'No photo with an approved offline-reuse license is available.',
      );
    }
    return downloadPhoto(photo);
  }

  Future<Uint8List> downloadPhoto(InatTaxonPhoto photo) async {
    final uri = Uri.tryParse(photo.url ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        !_isTrustedPhotoHost(uri.host)) {
      throw const FormatException('The reference photo URL is not trusted.');
    }
    final request = http.Request('GET', uri)
      ..headers['User-Agent'] = 'JandKBestiary/1.0';
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'The reference photo returned HTTP ${response.statusCode}.',
        uri,
      );
    }
    const maxPhotoBytes = 12 * 1024 * 1024;
    final contentLength = response.contentLength;
    if (contentLength != null && contentLength > maxPhotoBytes) {
      throw const FormatException(
        'The reference photo has an invalid file size.',
      );
    }
    final contentType = response.headers['content-type']?.toLowerCase();
    if (contentType != null && !contentType.startsWith('image/')) {
      throw const FormatException(
        'The reference photo URL did not return an image.',
      );
    }
    final bytes = BytesBuilder(copy: false);
    var receivedBytes = 0;
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      receivedBytes += chunk.length;
      if (receivedBytes > maxPhotoBytes) {
        throw const FormatException(
          'The reference photo has an invalid file size.',
        );
      }
      bytes.add(chunk);
    }
    if (receivedBytes == 0) {
      throw const FormatException(
        'The reference photo has an invalid file size.',
      );
    }
    return bytes.takeBytes();
  }

  Future<InatTaxonPhoto?> findCommonsPhoto(String scientificName) async {
    final name = _normalizeScientificName(scientificName);
    if (name.isEmpty) return null;
    final json = await _getJson(
      Uri.https('commons.wikimedia.org', '/w/api.php', {
        'action': 'query',
        'generator': 'search',
        'gsrsearch': '"$name"',
        'gsrnamespace': '6',
        'gsrlimit': '25',
        'prop': 'imageinfo',
        'iiprop': 'url|extmetadata',
        'iiurlwidth': '1280',
        'format': 'json',
        'origin': '*',
      }),
      source: 'Wikimedia Commons',
    );
    final pages = (json['query'] as Map<String, dynamic>?)?['pages'];
    if (pages is! Map<String, dynamic>) return null;
    final candidates = pages.values.whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => (a['index'] as int? ?? 0).compareTo(b['index'] as int? ?? 0),
      );
    final nameTokens = _scientificNameTokens(name);
    for (final page in candidates) {
      final imageInfo = page['imageinfo'];
      if (imageInfo is! List || imageInfo.isEmpty) continue;
      final info = imageInfo.first;
      if (info is! Map<String, dynamic>) continue;
      final metadata = info['extmetadata'];
      if (metadata is! Map<String, dynamic>) continue;
      final categories = _commonsMetadataValue(metadata, 'Categories');
      final description = _commonsMetadataValue(metadata, 'ImageDescription');
      if (!_containsScientificName(categories, nameTokens) &&
          !_containsScientificName(description, nameTokens)) {
        continue;
      }
      final license = _commonsLicense(
        _commonsMetadataValue(metadata, 'LicenseShortName'),
        _commonsMetadataValue(metadata, 'License'),
      );
      if (license == null) continue;
      final imageUrl = info['thumburl'] as String? ?? info['url'] as String?;
      final sourceUrl = info['descriptionurl'] as String?;
      if (!_isHttpsUrlOnHost(imageUrl, const {
        'upload.wikimedia.org',
        'thumb.wikimedia.org',
      })) {
        continue;
      }
      if (!_isHttpsUrlOnHost(sourceUrl, const {'commons.wikimedia.org'})) {
        continue;
      }
      final artist = _stripHtml(_commonsMetadataValue(metadata, 'Artist'));
      return InatTaxonPhoto(
        url: imageUrl,
        attribution: artist.isEmpty ? 'Wikimedia Commons' : artist,
        license: license,
        sourceUrl: sourceUrl,
      );
    }
    return null;
  }

  String _commonsMetadataValue(Map<String, dynamic> metadata, String key) {
    final entry = metadata[key];
    return entry is Map<String, dynamic> ? entry['value'] as String? ?? '' : '';
  }

  bool _containsScientificName(String text, List<String> nameTokens) {
    final textTokens = _scientificNameTokens(text);
    if (nameTokens.length > textTokens.length) return false;
    for (
      var start = 0;
      start <= textTokens.length - nameTokens.length;
      start++
    ) {
      var matches = true;
      for (var offset = 0; offset < nameTokens.length; offset++) {
        if (textTokens[start + offset] != nameTokens[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  List<String> _scientificNameTokens(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty)
      .toList();

  String? _commonsLicense(String shortName, String licenseCode) {
    final value = '$shortName $licenseCode'.toLowerCase();
    if (value.contains('cc0') || value.contains('cc-zero')) {
      return shortName.isEmpty ? 'CC0' : shortName;
    }
    if (value.contains('public domain') ||
        value.contains('pd-old') ||
        value.contains('pd-art')) {
      return 'public-domain';
    }
    if (RegExp(r'cc[- ]by[- ](sa|nc|nd)').hasMatch(value)) return null;
    final isAttributionLicense =
        RegExp(r'^cc\s*by(?:\s+[0-9.]+)?$').hasMatch(shortName.toLowerCase()) ||
        RegExp(r'^cc-by(?:-[0-9.]+)?$').hasMatch(licenseCode.toLowerCase());
    if (isAttributionLicense) {
      return shortName.isEmpty ? 'CC BY' : shortName;
    }
    return null;
  }

  String _stripHtml(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();

  bool _isTrustedPhotoHost(String host) =>
      host == 'inaturalist.org' ||
      host.endsWith('.inaturalist.org') ||
      host.endsWith('.amazonaws.com') ||
      host == 'upload.wikimedia.org' ||
      host == 'thumb.wikimedia.org';

  bool _isHttpsUrlOnHost(String? value, Set<String> hosts) {
    final uri = Uri.tryParse(value ?? '');
    return uri != null &&
        uri.scheme == 'https' &&
        hosts.contains(uri.host.toLowerCase());
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
        .get(
          uri,
          headers: const {
            'User-Agent': 'JandKBestiary/1.0 (species reference app)',
          },
        )
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

String _normalizeScientificName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
