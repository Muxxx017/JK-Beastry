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
  final String? photoSourceUrl;
  final String? wikipediaUrl;
  final List<InatTaxonPhoto> photos;
  final String? offlinePhotoPath;
  final String? offlinePhotoUrl;
  final String? offlinePhotoAttribution;
  final String? offlinePhotoLicense;
  final String? offlinePhotoSourceUrl;
  final String? wikipediaSummary;
  final Map<String, String> offlineTaxonomy;

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
    this.photoSourceUrl,
    required this.wikipediaUrl,
    this.photos = const [],
    this.offlinePhotoPath,
    this.offlinePhotoUrl,
    this.offlinePhotoAttribution,
    this.offlinePhotoLicense,
    this.offlinePhotoSourceUrl,
    this.wikipediaSummary,
    this.offlineTaxonomy = const {},
  });

  String get displayName => commonName ?? name;
  String get taxonUrl => 'https://www.inaturalist.org/taxa/$id';

  List<InatTaxonPhoto> get availablePhotos {
    final available = <InatTaxonPhoto>[
      if (photoUrl != null)
        InatTaxonPhoto(
          url: photoUrl,
          attribution: photoAttribution,
          license: photoLicense,
          sourceUrl: photoSourceUrl ?? taxonUrl,
        ),
      ...photos,
    ];
    final seenUrls = <String>{};
    return available.where((photo) {
      final url = photo.url;
      return url != null && seenUrls.add(url);
    }).toList();
  }

  InatTaxonPhoto? get reusableOfflinePhoto {
    for (final photo in availablePhotos) {
      if (_allowsOfflineReuse(photo.license) && photo.url != null) return photo;
    }
    return null;
  }

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
    'photoSourceUrl': photoSourceUrl,
    'wikipediaUrl': wikipediaUrl,
    'offlinePhotoPath': offlinePhotoPath,
    'wikipediaSummary': wikipediaSummary,
    'offlineTaxonomy': offlineTaxonomy,
    'photos': photos
        .map(
          (photo) => {
            'url': photo.url,
            'attribution': photo.attribution,
            'license': photo.license,
            'source_url': photo.sourceUrl,
          },
        )
        .toList(),
    'offlinePhotoUrl': offlinePhotoUrl,
    'offlinePhotoAttribution': offlinePhotoAttribution,
    'offlinePhotoLicense': offlinePhotoLicense,
    'offlinePhotoSourceUrl': offlinePhotoSourceUrl,
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
      photoSourceUrl: json['photoSourceUrl'] as String?,
      wikipediaUrl: json['wikipediaUrl'] as String?,
      offlinePhotoPath: json['offlinePhotoPath'] as String?,
      offlinePhotoUrl: json['offlinePhotoUrl'] as String?,
      offlinePhotoAttribution: json['offlinePhotoAttribution'] as String?,
      offlinePhotoLicense: json['offlinePhotoLicense'] as String?,
      offlinePhotoSourceUrl: json['offlinePhotoSourceUrl'] as String?,
      wikipediaSummary: json['wikipediaSummary'] as String?,
      offlineTaxonomy:
          (json['offlineTaxonomy'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      photos: photoRecords
          .whereType<Map<String, dynamic>>()
          .map(InatTaxonPhoto.fromJson)
          .toList(),
    );
  }

  InatTaxon copyWith({
    String? photoUrl,
    String? photoAttribution,
    String? photoLicense,
    String? photoSourceUrl,
    String? offlinePhotoPath,
    String? offlinePhotoUrl,
    String? offlinePhotoAttribution,
    String? offlinePhotoLicense,
    String? offlinePhotoSourceUrl,
    String? wikipediaSummary,
    Map<String, String>? offlineTaxonomy,
  }) {
    return InatTaxon(
      id: id,
      name: name,
      commonName: commonName,
      rank: rank,
      regionalObservations: regionalObservations,
      totalObservations: totalObservations,
      conservationStatus: conservationStatus,
      photoUrl: photoUrl ?? this.photoUrl,
      photoAttribution: photoAttribution ?? this.photoAttribution,
      photoLicense: photoLicense ?? this.photoLicense,
      photoSourceUrl: photoSourceUrl ?? this.photoSourceUrl,
      wikipediaUrl: wikipediaUrl,
      photos: photos,
      offlinePhotoPath: offlinePhotoPath ?? this.offlinePhotoPath,
      offlinePhotoUrl: offlinePhotoUrl ?? this.offlinePhotoUrl,
      offlinePhotoAttribution:
          offlinePhotoAttribution ?? this.offlinePhotoAttribution,
      offlinePhotoLicense: offlinePhotoLicense ?? this.offlinePhotoLicense,
      offlinePhotoSourceUrl:
          offlinePhotoSourceUrl ?? this.offlinePhotoSourceUrl,
      wikipediaSummary: wikipediaSummary ?? this.wikipediaSummary,
      offlineTaxonomy: offlineTaxonomy ?? this.offlineTaxonomy,
    );
  }

  bool get hasReusableOfflinePhoto => reusableOfflinePhoto != null;

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
      photoSourceUrl: null,
      wikipediaUrl: _secureUrl(taxon['wikipedia_url'] as String?),
    );
  }

  bool _allowsOfflineReuse(String? license) {
    final normalized = license?.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '-',
    );
    return normalized == 'cc0' ||
        normalized == 'cc0-1.0' ||
        normalized == 'public-domain' ||
        RegExp(r'^cc-by(?:-[0-9.]+)?$').hasMatch(normalized ?? '');
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
      photoSourceUrl: null,
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
        if (parsed.url != null) {
          photos.add(
            InatTaxonPhoto(
              url: parsed.url,
              attribution: parsed.attribution,
              license: parsed.license,
              sourceUrl: 'https://www.inaturalist.org/taxa/${json['id']}',
            ),
          );
        }
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
      photoSourceUrl: null,
      wikipediaUrl: _secureUrl(json['wikipedia_url'] as String?),
      photos: photos,
    );
  }
}

class InatTaxonPhoto {
  final String? url;
  final String? attribution;
  final String? license;
  final String? sourceUrl;

  const InatTaxonPhoto({
    required this.url,
    required this.attribution,
    required this.license,
    this.sourceUrl,
  });

  factory InatTaxonPhoto.fromJson(Map<String, dynamic> json) {
    return InatTaxonPhoto(
      url: _photoUrl(json),
      attribution: json['attribution'] as String?,
      license: json['license_code'] as String?,
      sourceUrl: json['source_url'] as String?,
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
