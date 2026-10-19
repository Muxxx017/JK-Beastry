import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';
import 'package:zoology_app/widgets/bestiary_mark.dart';
import 'package:zoology_app/widgets/field_landscape.dart';

class SpeciesDetailPage extends StatelessWidget {
  final ZoologySpecies species;

  const SpeciesDetailPage({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(species.commonName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 228,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: BestiaryPalette.line),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const FieldLandscape(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Opacity(
                          opacity: .45,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 26),
                            child: BestiaryMark(size: 112),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${species.category.toUpperCase()}  ·  ${species.region.toUpperCase()}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: const Color(0xFFE8DFC8)),
                            ),
                            const Spacer(),
                            Text(
                              species.commonName,
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(color: BestiaryPalette.page),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              species.scientificName,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: const Color(0xFFE5E6DA),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (species.searchTerms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Also searched as: ${species.searchTerms.join(' · ')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Status', value: species.status),
                    _InfoChip(label: 'Category', value: species.category),
                    _InfoChip(label: 'Size', value: species.size),
                  ],
                ),
                if (species.taxonomy.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _LocalTaxonomy(species: species),
                ],
                const SizedBox(height: 20),
                _detailSection(context, 'Region', species.region),
                _detailSection(
                  context,
                  'Identification',
                  species.identification,
                ),
                _detailSection(context, 'Characteristics', species.feature),
                _detailSection(context, 'Habitat', species.habitat),
                _detailSection(
                  context,
                  'Range & local records',
                  species.distribution,
                ),
                _detailSection(context, 'Diet', species.diet),
                _detailSection(context, 'Habit & behavior', species.behavior),
                _detailSection(
                  context,
                  'Life cycle & breeding',
                  species.breeding,
                ),
                _detailSection(
                  context,
                  'Ecological role',
                  species.ecologicalRole,
                ),
                _detailSection(context, 'Threats', species.threats),
                _detailSection(
                  context,
                  'Conservation status',
                  species.conservation,
                ),
                _detailSection(context, 'Fun fact', species.funFact),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Research starting points'),
                const Text(
                  'These links help you check the scientific name in published '
                  'literature and specialist databases. They are search results, '
                  'not citations for every statement above.',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openReference(
                        context,
                        Uri.https('scholar.google.com', '/scholar', {
                          'q': species.scientificName,
                        }),
                      ),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Books & papers'),
                    ),
                    if (species.category == 'Plant')
                      OutlinedButton.icon(
                        onPressed: () => _openReference(
                          context,
                          Uri.https('powo.science.kew.org', '/results', {
                            'q': species.scientificName,
                          }),
                        ),
                        icon: const Icon(Icons.eco_outlined),
                        label: const Text('Kew Plants of the World'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _openReference(
                        context,
                        Uri.https('www.inaturalist.org', '/search', {
                          'q': species.scientificName,
                        }),
                      ),
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('iNaturalist records'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Regional guide entries are curated, not a complete census. '
                  'Range and conservation can vary locally; use the online explorer '
                  'and linked sources to verify records.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(BuildContext context, String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    if (title == 'Fun fact') {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BestiaryPalette.sage,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BestiaryPalette.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: BestiaryPalette.rust,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FUN FACT',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: BestiaryPalette.rust),
                    ),
                    const SizedBox(height: 6),
                    Text(value, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 17,
                decoration: BoxDecoration(
                  color: BestiaryPalette.brass,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 7),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Future<void> _openReference(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the reference search.')),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BestiaryPalette.sage,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: BestiaryPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

class _LocalTaxonomy extends StatelessWidget {
  final ZoologySpecies species;

  const _LocalTaxonomy({required this.species});

  @override
  Widget build(BuildContext context) {
    const rankOrder = [
      'Kingdom',
      'Phylum',
      'Class',
      'Order',
      'Family',
      'Genus',
      'Species',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scientific classification',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...rankOrder
                .where(species.taxonomy.containsKey)
                .map(
                  (rank) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 92,
                          child: Text(
                            rank,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            species.taxonomy[rank]!,
                            style: TextStyle(
                              fontStyle: rank == 'Genus' || rank == 'Species'
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            const Text(
              'Classification follows the GBIF Backbone Taxonomy; accepted '
              'names and rank placement can change as taxonomy is revised.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.https('www.gbif.org', '/species/search', {
                  'q': species.scientificName,
                }),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Check current GBIF taxonomy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
