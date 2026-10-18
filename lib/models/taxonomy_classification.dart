class TaxonomyClassification {
  final String? scientificName;
  final String? taxonomicStatus;
  final String? rank;
  final int? confidence;
  final int? usageKey;
  final String? kingdom;
  final String? phylum;
  final String? className;
  final String? order;
  final String? family;
  final String? genus;
  final String? species;

  const TaxonomyClassification({
    required this.scientificName,
    required this.taxonomicStatus,
    required this.rank,
    required this.confidence,
    required this.usageKey,
    required this.kingdom,
    required this.phylum,
    required this.className,
    required this.order,
    required this.family,
    required this.genus,
    required this.species,
  });

  factory TaxonomyClassification.fromJson(Map<String, dynamic> json) {
    return TaxonomyClassification(
      scientificName: json['scientificName'] as String?,
      taxonomicStatus: json['status'] as String?,
      rank: json['rank'] as String?,
      confidence: json['confidence'] as int?,
      usageKey: json['usageKey'] as int?,
      kingdom: json['kingdom'] as String?,
      phylum: json['phylum'] as String?,
      className: json['class'] as String?,
      order: json['order'] as String?,
      family: json['family'] as String?,
      genus: json['genus'] as String?,
      species: json['species'] as String?,
    );
  }

  String? get sourceUrl =>
      usageKey == null ? null : 'https://www.gbif.org/species/$usageKey';

  List<MapEntry<String, String>> get ranks => [
    if (kingdom != null) MapEntry('Kingdom', kingdom!),
    if (phylum != null) MapEntry('Phylum', phylum!),
    if (className != null) MapEntry('Class', className!),
    if (order != null) MapEntry('Order', order!),
    if (family != null) MapEntry('Family', family!),
    if (genus != null) MapEntry('Genus', genus!),
    if (species != null) MapEntry('Species', species!),
  ];
}
