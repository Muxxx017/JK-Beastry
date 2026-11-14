class ZoologySpecies {
  final String id;
  final String commonName;
  final String scientificName;
  final String category;
  final String region;
  final String status;
  final String habitat;
  final String size;
  final String conservation;
  final String feature;
  final String funFact;
  final String distribution;
  final String diet;
  final String behavior;
  final String breeding;
  final String threats;
  final String ecologicalRole;
  final String identification;
  final String vocalization;
  final String imageUrl;
  final String imageAttribution;
  final String imageLicense;
  final List<String> searchTerms;
  final Map<String, String> taxonomy;
  final String? audioAsset;
  final bool isVocal;
  final String? vocalizationNote;

  const ZoologySpecies({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.region,
    required this.status,
    required this.habitat,
    required this.size,
    required this.conservation,
    required this.feature,
    required this.funFact,
    this.distribution = '',
    this.diet = '',
    this.behavior = '',
    this.breeding = '',
    this.threats = '',
    this.ecologicalRole = '',
    this.identification = '',
    this.vocalization = '',
    this.imageUrl = '',
    this.imageAttribution = '',
    this.imageLicense = '',
    this.searchTerms = const [],
    this.taxonomy = const {},
    this.audioAsset,
    this.isVocal = true,
    this.vocalizationNote,
  });

  factory ZoologySpecies.fromJson(Map<String, dynamic> json) {
    return ZoologySpecies(
      id: json['id'] as String,
      commonName: json['commonName'] as String,
      scientificName: json['scientificName'] as String,
      category: json['category'] as String,
      region: json['region'] as String,
      status: json['status'] as String,
      habitat: json['habitat'] as String,
      size: json['size'] as String,
      conservation: json['conservation'] as String,
      feature: json['feature'] as String,
      funFact: json['funFact'] as String,
      distribution: json['distribution'] as String? ?? '',
      diet: json['diet'] as String? ?? '',
      behavior: json['behavior'] as String? ?? '',
      breeding: json['breeding'] as String? ?? '',
      threats: json['threats'] as String? ?? '',
      ecologicalRole: json['ecologicalRole'] as String? ?? '',
      identification: json['identification'] as String? ?? '',
      vocalization: json['vocalization'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      imageAttribution: json['imageAttribution'] as String? ?? '',
      imageLicense: json['imageLicense'] as String? ?? '',
      searchTerms:
          (json['searchTerms'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      taxonomy:
          (json['taxonomy'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      audioAsset: json['audioAsset'] as String?,
      isVocal: json['isVocal'] as bool? ?? true,
      vocalizationNote: json['vocalizationNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'commonName': commonName,
    'scientificName': scientificName,
    'category': category,
    'region': region,
    'status': status,
    'habitat': habitat,
    'size': size,
    'conservation': conservation,
    'feature': feature,
    'funFact': funFact,
    'distribution': distribution,
    'diet': diet,
    'behavior': behavior,
    'breeding': breeding,
    'threats': threats,
    'ecologicalRole': ecologicalRole,
    'identification': identification,
    'vocalization': vocalization,
    'imageUrl': imageUrl,
    'imageAttribution': imageAttribution,
    'imageLicense': imageLicense,
    'searchTerms': searchTerms,
    'taxonomy': taxonomy,
    if (audioAsset != null) 'audioAsset': audioAsset,
    'isVocal': isVocal,
    if (vocalizationNote != null) 'vocalizationNote': vocalizationNote,
  };

  ZoologySpecies copyWith({
    String? id,
    String? commonName,
    String? scientificName,
    String? category,
    String? region,
    String? status,
    String? habitat,
    String? size,
    String? conservation,
    String? feature,
    String? funFact,
    String? distribution,
    String? diet,
    String? behavior,
    String? breeding,
    String? threats,
    String? ecologicalRole,
    String? identification,
    String? vocalization,
    String? imageUrl,
    String? imageAttribution,
    String? imageLicense,
    List<String>? searchTerms,
    Map<String, String>? taxonomy,
    String? audioAsset,
    bool? isVocal,
    String? vocalizationNote,
  }) {
    return ZoologySpecies(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      category: category ?? this.category,
      region: region ?? this.region,
      status: status ?? this.status,
      habitat: habitat ?? this.habitat,
      size: size ?? this.size,
      conservation: conservation ?? this.conservation,
      feature: feature ?? this.feature,
      funFact: funFact ?? this.funFact,
      distribution: distribution ?? this.distribution,
      diet: diet ?? this.diet,
      behavior: behavior ?? this.behavior,
      breeding: breeding ?? this.breeding,
      threats: threats ?? this.threats,
      ecologicalRole: ecologicalRole ?? this.ecologicalRole,
      identification: identification ?? this.identification,
      vocalization: vocalization ?? this.vocalization,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAttribution: imageAttribution ?? this.imageAttribution,
      imageLicense: imageLicense ?? this.imageLicense,
      searchTerms: searchTerms ?? this.searchTerms,
      taxonomy: taxonomy ?? this.taxonomy,
      audioAsset: audioAsset ?? this.audioAsset,
      isVocal: isVocal ?? this.isVocal,
      vocalizationNote: vocalizationNote ?? this.vocalizationNote,
    );
  }

  String get searchableText => [
    commonName,
    scientificName,
    category,
    region,
    status,
    habitat,
    size,
    conservation,
    feature,
    funFact,
    distribution,
    diet,
    behavior,
    breeding,
    threats,
    ecologicalRole,
    identification,
    vocalization,
    ?vocalizationNote,
    ...taxonomy.values,
    ...searchTerms,
  ].join(' ').toLowerCase();
}
