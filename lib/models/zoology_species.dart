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
  final List<String> searchTerms;
  final Map<String, String> taxonomy;

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
    this.searchTerms = const [],
    this.taxonomy = const {},
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
    ...taxonomy.values,
    ...searchTerms,
  ].join(' ').toLowerCase();
}
