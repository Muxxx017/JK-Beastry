import 'dart:io';

import 'data_mammals.dart';
import 'data_birds.dart';
import 'data_other.dart';

void main() {
  final allSpecies = <Map<String, dynamic>>[
    ...mammalsData,
    ...birdsData,
    ...otherFaunaData,
  ];

  // Verify uniqueness of IDs
  final seenIds = <String>{};
  for (final sp in allSpecies) {
    final id = sp['id'] as String;
    if (!seenIds.add(id)) {
      throw StateError('Duplicate species ID found: $id');
    }
  }

  print('Total animal species to generate: ${allSpecies.length}');

  final buffer = StringBuffer();
  buffer.writeln("// J&K Bestiary - Curated Zoology Species Catalog");
  buffer.writeln("// Pure Zoology Focus: Mammals, Birds, Reptiles, Amphibians, Fishes, Insects of J&K");
  buffer.writeln("import 'package:zoology_app/models/zoology_species.dart';");
  buffer.writeln();
  buffer.writeln("const List<ZoologySpecies> kSpeciesCatalog = [");

  for (final s in allSpecies) {
    buffer.writeln("  ZoologySpecies(");
    buffer.writeln("    id: '${_escape(s['id'])}',");
    buffer.writeln("    commonName: '${_escape(s['commonName'])}',");
    buffer.writeln("    scientificName: '${_escape(s['scientificName'])}',");
    buffer.writeln("    category: '${_escape(s['category'])}',");
    buffer.writeln("    region: '${_escape(s['region'])}',");
    buffer.writeln("    status: '${_escape(s['status'])}',");
    buffer.writeln("    habitat: '${_escape(s['habitat'])}',");
    buffer.writeln("    size: '${_escape(s['size'])}',");
    buffer.writeln("    conservation: '${_escape(s['conservation'])}',");
    buffer.writeln("    feature: '${_escape(s['feature'])}',");
    buffer.writeln("    funFact: '${_escape(s['funFact'])}',");
    buffer.writeln("    distribution: '${_escape(s['distribution'])}',");
    buffer.writeln("    diet: '${_escape(s['diet'])}',");
    buffer.writeln("    behavior: '${_escape(s['behavior'])}',");
    buffer.writeln("    breeding: '${_escape(s['breeding'])}',");
    buffer.writeln("    threats: '${_escape(s['threats'])}',");
    buffer.writeln("    ecologicalRole: '${_escape(s['ecologicalRole'])}',");
    buffer.writeln("    identification: '${_escape(s['identification'])}',");
    buffer.writeln("    vocalization: '${_escape(s['vocalization'])}',");
    buffer.writeln("    imageUrl: '${_escape(s['imageUrl'] ?? '')}',");
    buffer.writeln("    imageAttribution: '${_escape(s['imageAttribution'] ?? '')}',");
    buffer.writeln("    imageLicense: '${_escape(s['imageLicense'] ?? '')}',");

    // Search terms
    final terms = (s['searchTerms'] as List<dynamic>? ?? [])
        .map((t) => "'${_escape(t.toString())}'")
        .join(', ');
    buffer.writeln("    searchTerms: [$terms],");

    // Taxonomy map
    final tax = s['taxonomy'] as Map<String, dynamic>? ?? {};
    buffer.writeln("    taxonomy: {");
    tax.forEach((k, v) {
      buffer.writeln("      '${_escape(k)}': '${_escape(v.toString())}',");
    });
    buffer.writeln("    },");
    buffer.writeln("  ),");
  }

  buffer.writeln("];");

  final outputFile = File('lib/data/species_data.dart');
  outputFile.writeAsStringSync(buffer.toString());
  print('Successfully generated ${outputFile.path} with ${allSpecies.length} species!');
}

String _escape(dynamic val) {
  if (val == null) return '';
  return val.toString().replaceAll("'", "\\'");
}
