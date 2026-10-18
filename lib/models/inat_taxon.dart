class InatTaxon {
  final int id;
  final String name;
  final String? commonName;
  final String rank;
  final int? regionalObservations;
  final int totalObservations;
  final String? conservationStatus;
  final String? photoUrl;
  final String? photoAttribution;
  final String? photoLicense;
  final String? wikipediaUrl;
  final List<InatTaxonPhoto> photos;

  const InatTaxon({
    required this.id,
    required this.name,
    required this.commonName,
    required this.rank,
    required this.regionalObservations,
    required this.totalObservations,
    required this.conservationStatus,
    required this.photoUrl,
    required this.photoAttribution,
    required this.photoLicense,
    required this.wikipediaUrl,
    this.photos = const [],
  });

  String get displayName => commonName ?? name;
  String get taxonUrl => 'https://www.inaturalist.org/taxa/$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'commonName': commonName,
    'rank': rank,
    'regionalObservations': regionalObservations,
    'totalObservations': totalObservations,
    'conservationStatus': conservationStatus,
    'photoUrl': photoUrl,
    'photoAttribution': photoAttribution,
    'photoLicense': photoLicense,
    'wikipediaUrl': wikipediaUrl,
    'photos': photos
        .map(
          (photo) => {
            'url': photo.url,
            'attribution': photo.attribution,
            'license': photo.license,
          },
        )
        .toList(),
  };

  factory InatTaxon.fromJson(Map<String, dynamic> json) {
    final photoRecords = json['photos'] as List<dynamic>? ?? [];
    return InatTaxon(
      id: json['id'] as int,
      name: json['name'] as String,
      commonName: json['commonName'] as String?,
      rank: json['rank'] as String? ?? 'unknown',
      regionalObservations: json['regionalObservations'] as int?,
      totalObservations: json['totalObservations'] as int? ?? 0,
      conservationStatus: json['conservationStatus'] as String?,
      photoUrl: json['photoUrl'] as String?,
      photoAttribution: json['photoAttribution'] as String?,
      photoLicense: json['photoLicense'] as String?,
      wikipediaUrl: json['wikipediaUrl'] as String?,
      photos: photoRecords
          .whereType<Map<String, dynamic>>()
          .map(InatTaxonPhoto.fromJson)
          .toList(),
    );
  }

  factory InatTaxon.fromSpeciesCountJson(Map<String, dynamic> json) {
    final taxon = json['taxon'] as Map<String, dynamic>;
    final photo = taxon['default_photo'] as Map<String, dynamic>?;
    final conservation = taxon['conservation_status'] as Map<String, dynamic>?;

    return InatTaxon(
      id: taxon['id'] as int,
      name: taxon['name'] as String,
      commonName: taxon['preferred_common_name'] as String?,
      rank: taxon['rank'] as String? ?? 'unknown',
      regionalObservations: json['count'] as int?,
      totalObservations: taxon['observations_count'] as int? ?? 0,
      conservationStatus: conservation?['status_name'] as String?,
      photoUrl: _photoUrl(photo),
      photoAttribution: photo?['attribution'] as String?,
      photoLicense: photo?['license_code'] as String?,
      wikipediaUrl: _secureUrl(taxon['wikipedia_url'] as String?),
    );
  }

  factory InatTaxon.fromAutocompleteJson(Map<String, dynamic> json) {
    final photo = json['default_photo'] as Map<String, dynamic>?;
    final conservation = json['conservation_status'] as Map<String, dynamic>?;
    return InatTaxon(
      id: json['id'] as int,
      name: json['name'] as String,
      commonName: json['preferred_common_name'] as String?,
      rank: json['rank'] as String? ?? 'unknown',
      regionalObservations: null,
      totalObservations: json['observations_count'] as int? ?? 0,
      conservationStatus: conservation?['status_name'] as String?,
      photoUrl: _photoUrl(photo),
      photoAttribution: photo?['attribution'] as String?,
      photoLicense: photo?['license_code'] as String?,
      wikipediaUrl: _secureUrl(json['wikipedia_url'] as String?),
    );
  }

  factory InatTaxon.fromDetailJson(Map<String, dynamic> json) {
    final photo = json['default_photo'] as Map<String, dynamic>?;
    final conservation = json['conservation_status'] as Map<String, dynamic>?;
    final taxonPhotos = json['taxon_photos'] as List<dynamic>? ?? [];
    final photos = <InatTaxonPhoto>[];
    for (final item in taxonPhotos) {
      if (item is! Map<String, dynamic>) continue;
      final photoJson = item['photo'];
      if (photoJson is Map<String, dynamic>) {
        final parsed = InatTaxonPhoto.fromJson(photoJson);
        if (parsed.url != null) photos.add(parsed);
      }
    }

    return InatTaxon(
      id: json['id'] as int,
      name: json['name'] as String,
      commonName: json['preferred_common_name'] as String?,
      rank: json['rank'] as String? ?? 'unknown',
      regionalObservations: null,
      totalObservations: json['observations_count'] as int? ?? 0,
      conservationStatus: conservation?['status_name'] as String?,
      photoUrl: _photoUrl(photo),
      photoAttribution: photo?['attribution'] as String?,
      photoLicense: photo?['license_code'] as String?,
      wikipediaUrl: _secureUrl(json['wikipedia_url'] as String?),
      photos: photos,
    );
  }
}

class InatTaxonPhoto {
  final String? url;
  final String? attribution;
  final String? license;

  const InatTaxonPhoto({
    required this.url,
    required this.attribution,
    required this.license,
  });

  factory InatTaxonPhoto.fromJson(Map<String, dynamic> json) {
    return InatTaxonPhoto(
      url: _photoUrl(json),
      attribution: json['attribution'] as String?,
      license: json['license_code'] as String?,
    );
  }
}

String? _photoUrl(Map<String, dynamic>? photo) {
  if (photo == null) return null;
  return photo['medium_url'] as String? ?? photo['url'] as String?;
}

String? _secureUrl(String? url) {
  if (url == null) return null;
  return url.startsWith('http://') ? 'https://${url.substring(7)}' : url;
}
