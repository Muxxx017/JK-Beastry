import 'package:zoology_app/models/zoology_species.dart';

List<Map<String, String>> buildDailyAnimalWidgetRecords(
  Iterable<ZoologySpecies> speciesCatalog,
) {
  return speciesCatalog
      .where(
        (species) =>
            species.category.toLowerCase() != 'plant' &&
            species.funFact.trim().isNotEmpty,
      )
      .map(
        (species) => {
          'id': species.id,
          'commonName': species.commonName,
          'scientificName': species.scientificName,
          'funFact': species.funFact,
        },
      )
      .toList();
}
