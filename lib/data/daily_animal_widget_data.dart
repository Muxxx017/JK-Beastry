import 'package:zoology_app/models/zoology_species.dart';

const _faunaCategories = {
  'mammal',
  'bird',
  'reptile',
  'amphibian',
  'fish',
  'insect',
};

List<Map<String, String>> buildDailyAnimalWidgetRecords(
  Iterable<ZoologySpecies> speciesCatalog,
) {
  return speciesCatalog
      .where(
        (species) =>
            _faunaCategories.contains(species.category.toLowerCase()) &&
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
