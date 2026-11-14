import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
import 'package:zoology_app/data/fauna_quiz_data.dart';
import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/fauna_quiz_question.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/online_species_page.dart';
import 'package:zoology_app/screens/species_detail_page.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';
import 'package:zoology_app/widgets/bestiary_banner.dart';
import 'package:zoology_app/widgets/bestiary_mark.dart';
import 'package:zoology_app/widgets/field_landscape.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KashmirZoologyApp());
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    unawaited(_syncDailyAnimalWidget());
  }
}

Future<void> _syncDailyAnimalWidget() async {
  final animals = buildDailyAnimalWidgetRecords(kSpeciesCatalog);

  try {
    await const MethodChannel(
      'com.kashmir.zoology/daily_animal_widget',
    ).invokeMethod<void>('setDailyAnimals', {'animals': jsonEncode(animals)});
  } on PlatformException catch (error) {
    debugPrint('Could not update the daily animal widget: ${error.message}');
  } on MissingPluginException catch (error) {
    debugPrint('Daily animal widget platform channel is unavailable: $error');
  }
}

class KashmirZoologyApp extends StatelessWidget {
  const KashmirZoologyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J&K Bestiary',
      debugShowCheckedModeBanner: false,
      theme: BestiaryTheme.light,
      home: const SpeciesHomePage(),
    );
  }
}

class SpeciesHomePage extends StatefulWidget {
  const SpeciesHomePage({super.key});

  @override
  State<SpeciesHomePage> createState() => _SpeciesHomePageState();
}

class _SpeciesHomePageState extends State<SpeciesHomePage> {
  final _observationStore = ObservationStore();
  final _imagePicker = ImagePicker();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _notebookKey = GlobalKey();
  final FaunaQuizController _quizController = FaunaQuizController();

  final List<String> categories = const [
    'All',
    'Mammal',
    'Bird',
    'Reptile',
    'Amphibian',
    'Fish',
    'Insect',
  ];

  final List<String> regions = const [
    'All',
    'Jammu',
    'Kashmir',
    'Ladakh',
    'Trans-Himalaya',
    'Pir Panjal',
  ];

  final Set<String> favorites = <String>{};
  final List<FieldObservation> observations = [];
  List<int>? selectedPhotoBytes;
  bool _loadingObservations = true;
  bool _savingObservation = false;
  bool _notebookExpanded = false;
  int _selectedTab = 0;
  String selectedCategory = 'All';
  String selectedRegion = 'All';
  String query = '';

  static const _navChannel = MethodChannel('com.kashmir.zoology/navigation');

  @override
  void initState() {
    super.initState();
    _loadObservations();
    _initNavigationChannel();
  }

  void _initNavigationChannel() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _navChannel.setMethodCallHandler((call) async {
        if (call.method == 'openSpecies') {
          final speciesId = call.arguments as String?;
          if (speciesId != null && speciesId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToSpeciesById(speciesId);
            });
          }
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final initialId =
              await _navChannel.invokeMethod<String>('getInitialSpeciesId');
          if (initialId != null && initialId.isNotEmpty && mounted) {
            _navigateToSpeciesById(initialId);
          }
        } catch (e) {
          debugPrint('Navigation channel error: $e');
        }
      });
    }
  }

  void _navigateToSpeciesById(String speciesId) {
    if (!mounted || speciesId.trim().isEmpty) return;
    final cleanId = speciesId.trim().toLowerCase();

    ZoologySpecies? match;
    for (final sp in kSpeciesCatalog) {
      if (sp.id.toLowerCase() == cleanId ||
          sp.commonName.toLowerCase() == cleanId ||
          sp.scientificName.toLowerCase() == cleanId) {
        match = sp;
        break;
      }
    }
    match ??= kSpeciesCatalog.where((sp) {
      return sp.id.toLowerCase().contains(cleanId) ||
          cleanId.contains(sp.id.toLowerCase());
    }).firstOrNull;

    if (match != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SpeciesDetailPage(species: match!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _quizController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadObservations() async {
    try {
      final saved = await _observationStore.load();
      if (!mounted) return;
      setState(() {
        observations
          ..clear()
          ..addAll(saved);
        _loadingObservations = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingObservations = false);
      debugPrint('Could not load field notes: $error');
    }
  }

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 65,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => selectedPhotoBytes = bytes);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not add photo: $error');
    }
  }

  Future<void> _showPhotoOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _choosePhoto(source);
  }

  Future<void> _saveObservation() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      _showMessage('Add a note about what you observed before saving.');
      return;
    }

    setState(() => _savingObservation = true);
    final observation = FieldObservation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      speciesName: _speciesController.text.trim().isEmpty
          ? 'Unidentified observation'
          : _speciesController.text.trim(),
      location: _locationController.text.trim(),
      notes: notes,
      photoBase64: selectedPhotoBytes == null
          ? null
          : base64Encode(selectedPhotoBytes!),
      observedAt: DateTime.now(),
    );

    try {
      final updated = [observation, ...observations];
      await _observationStore.save(updated);
      if (!mounted) return;
      setState(() {
        observations
          ..clear()
          ..addAll(updated);
        selectedPhotoBytes = null;
        _savingObservation = false;
      });
      _speciesController.clear();
      _locationController.clear();
      _notesController.clear();
      _showMessage('Field note saved on this device.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingObservation = false);
      _showMessage('Could not save field note: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final datePart =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timePart =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }

  Future<void> _showObservationDetails(FieldObservation observation) async {
    final photoBytes = observation.photoBytes;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'FIELD ENTRY  ·  ${_formatDate(observation.observedAt)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  observation.speciesName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (observation.location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(child: Text(observation.location)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (photoBytes != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => Dialog.fullscreen(
                          backgroundColor: Colors.black,
                          child: Stack(
                            children: [
                              Center(
                                child: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 5,
                                  child: Image.memory(
                                    Uint8List.fromList(photoBytes),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SafeArea(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    tooltip: 'Close photo',
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: BestiaryPalette.page,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        Uint8List.fromList(photoBytes),
                        width: double.infinity,
                        height: 230,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the photograph to enlarge',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Text(observation.notes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ZoologySpecies> get filteredSpecies {
    final rawQuery = query.trim().toLowerCase();

    // Tokenize query into words, normalizing punctuation and hyphens
    final queryTokens = rawQuery
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final qSpaced = rawQuery
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final speciesList = kSpeciesCatalog.where((species) {
      final matchesCategory =
          selectedCategory == 'All' ||
          species.category == selectedCategory ||
          (selectedCategory == 'Not recorded' &&
              species.status == 'Not currently recorded');

      final matchesRegion =
          selectedRegion == 'All' ||
          species.region.toLowerCase().contains(selectedRegion.toLowerCase()) ||
          species.region
              .toLowerCase()
              .replaceAll('-', ' ')
              .contains(selectedRegion.toLowerCase().replaceAll('-', ' ')) ||
          species.region == selectedRegion;

      if (!matchesCategory || !matchesRegion) return false;

      if (queryTokens.isEmpty) return true;

      final searchDoc = [
        species.id,
        species.id.replaceAll('-', ' '),
        species.commonName,
        species.commonName.replaceAll('-', ' '),
        species.scientificName,
        ...species.searchTerms,
        ...species.searchTerms.map((t) => t.replaceAll('-', ' ')),
        ...species.taxonomy.values,
        species.searchableText,
        species.searchableText.replaceAll('-', ' '),
      ].join(' ').toLowerCase();

      return queryTokens.every((token) => searchDoc.contains(token));
    }).toList();

    if (queryTokens.isNotEmpty) {
      speciesList.sort((a, b) {
        final tierA = computeSpeciesRelevanceTier(a, rawQuery);
        final tierB = computeSpeciesRelevanceTier(b, rawQuery);

        if (tierA != tierB) {
          return tierA.compareTo(tierB);
        }

        // Secondary tie-breaker: exact word match in commonName
        final aWords = a.commonName.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
        final bWords = b.commonName.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
        final aExactWord = aWords.contains(rawQuery) || aWords.contains(qSpaced);
        final bExactWord = bWords.contains(rawQuery) || bWords.contains(qSpaced);
        if (aExactWord != bExactWord) {
          return aExactWord ? -1 : 1;
        }

        // Tertiary tie-breaker: length of common name (shorter names first)
        final lengthComp = a.commonName.length.compareTo(b.commonName.length);
        if (lengthComp != 0) return lengthComp;

        // Quaternary: alphabetical
        return a.commonName.compareTo(b.commonName);
      });
    }

    return speciesList;
  }

  ZoologySpecies get _animalOfTheDay {
    final animals = kSpeciesCatalog
        .where(
          (species) =>
              species.category != 'Plant' && species.funFact.trim().isNotEmpty,
        )
        .toList();
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year)).inDays;
    return animals[dayOfYear % animals.length];
  }

  SliverToBoxAdapter _buildTabHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: BestiaryPalette.sage,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: BestiaryPalette.forest),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: BestiaryPalette.rust),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: BestiaryPalette.mutedInk),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverOverview() {
    final animal = _animalOfTheDay;
    final threatenedCount = kSpeciesCatalog
        .where((s) => s.conservation.toLowerCase().contains('endangered') || s.conservation.toLowerCase().contains('vulnerable'))
        .length;
    final date = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${months[date.month - 1].toUpperCase()} ${date.day}  ·  FIELD EDITION NO. ${(date.difference(DateTime(date.year)).inDays + 1).toString().padLeft(3, '0')}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _CollectionStat(
                      value: '${kSpeciesCatalog.length}',
                      label: 'FIELD GUIDE ENTRIES',
                      icon: Icons.menu_book_outlined,
                    ),
                    _CollectionStat(
                      value: '$threatenedCount',
                      label: 'THREATENED FAUNA',
                      icon: Icons.shield_outlined,
                    ),
                    _CollectionStat(
                      value: '${observations.length}',
                      label: 'YOUR OBSERVATIONS',
                      icon: Icons.edit_note_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY IN THE FIELD',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: BestiaryPalette.rust),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Meet the ${animal.commonName}',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SpeciesDetailPage(species: animal),
                          ),
                        );
                      },
                      child: const Text('Open field note  →'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  color: BestiaryPalette.page,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 92,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SpeciesReferencePhoto(
                              species: animal,
                              height: 112,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal.scientificName,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                animal.funFact,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.bookmark_outline_rounded,
                          color: BestiaryPalette.brass,
                        ),
                      ],
                    ),
                  ),
                ),
                InteractiveFaunaChallengeCard(controller: _quizController),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const Key('discoverGuideButton'),
                      onPressed: () => setState(() => _selectedTab = 2),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: const Text('Browse the field guide'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('discoverJournalButton'),
                      onPressed: () => setState(() => _selectedTab = 1),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Write a field note'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OnlineSpeciesPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.public_rounded),
                      label: const Text('Explore live records'),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'A field guide to the living Himalaya',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedTab = 2),
                      child: const Text('View all  →'),
                    ),
                  ],
                ),
                Text(
                  'Fauna and wildlife recorded across Jammu & Kashmir.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: BestiaryPalette.mutedInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BestiaryMark(size: 36),
            SizedBox(width: 10),
            Text('J&K Bestiary'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Explore regional species online',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OnlineSpeciesPage(),
                ),
              );
            },
            icon: const Icon(Icons.public_rounded),
          ),
          IconButton(
            tooltip: 'Favorites',
            onPressed: () {
              final favoriteSpecies = kSpeciesCatalog
                  .where((item) => favorites.contains(item.id))
                  .toList();
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FavoritesPage(species: favoriteSpecies),
                ),
              );
            },
            icon: const Icon(Icons.favorite_border_rounded),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('primaryNavigation'),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            key: Key('discoverTab'),
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            key: Key('journalTab'),
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Journal',
          ),
          NavigationDestination(
            key: Key('guideTab'),
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Field guide',
          ),
        ],
      ),
      body: CustomScrollView(
        key: ValueKey('bestiary-tab-$_selectedTab'),
        slivers: [
          if (_selectedTab == 0)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        children: [
                          const Positioned.fill(child: FieldLandscape()),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'FIELD NOTES  ·  JAMMU & KASHMIR',
                                        style: TextStyle(
                                          color: Color(0xFFD5E1CF),
                                          fontSize: 10,
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 9),
                                    const BestiaryMark(size: 44),
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'The field guide\nof the Himalaya.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: BestiaryPalette.page,
                                        fontSize: 38,
                                        height: 1.02,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Observe the wild. Keep a record.\nDiscover your place in nature.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: .88,
                                        ),
                                      ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _HeroAction(
                                      icon: Icons.edit_note_rounded,
                                      label: 'Open journal',
                                      onPressed: () =>
                                          setState(() => _selectedTab = 1),
                                    ),
                                    _HeroAction(
                                      icon: Icons.auto_stories_outlined,
                                      label: 'Browse the guide',
                                      outlined: true,
                                      onPressed: () =>
                                          setState(() => _selectedTab = 2),
                                    ),
                                  ],
                                ),
                                if (!kIsWeb &&
                                    defaultTargetPlatform ==
                                        TargetPlatform.android) ...[
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: _showDailyWidgetInstructions,
                                    icon: const Icon(
                                      Icons.widgets_outlined,
                                      color: Color(0xFFD5E1CF),
                                    ),
                                    label: const Text(
                                      'Add the daily animal home-screen widget',
                                      style: TextStyle(
                                        color: Color(0xFFD5E1CF),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedTab == 0) _buildDiscoverOverview(),
          if (_selectedTab == 1)
            _buildTabHeading(
              eyebrow: 'YOUR FIELD RECORD',
              title: 'Field journal',
              subtitle: 'A personal record of the lives and landscapes you encounter.',
              icon: Icons.edit_note_rounded,
            ),
          if (_selectedTab == 1)
            SliverToBoxAdapter(
              child: Container(
                key: _notebookKey,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: BestiaryPalette.page,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BestiaryPalette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: const Key('fieldNotebookToggle'),
                              onTap: () => setState(
                                () => _notebookExpanded = !_notebookExpanded,
                              ),
                              leading: const CircleAvatar(
                                backgroundColor: BestiaryPalette.sage,
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: BestiaryPalette.forest,
                                ),
                              ),
                              title: const Text(
                                'Field notebook',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                observations.isEmpty
                                    ? 'Your private field journal · saved on this device'
                                    : '${observations.length} saved '
                                          '${observations.length == 1 ? 'entry' : 'entries'} · private to this device',
                              ),
                              trailing: Icon(
                                _notebookExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.add_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_notebookExpanded) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: _showPhotoOptions,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: selectedPhotoBytes == null
                                        ? Icon(
                                            Icons.add_a_photo_rounded,
                                            size: 42,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        : Image.memory(
                                            Uint8List.fromList(
                                              selectedPhotoBytes!,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _speciesController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: BestiaryPalette.page,
                                          hintText:
                                              'Species / unknown sighting',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _locationController,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: BestiaryPalette.page,
                                          hintText: 'Location / GPS',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: const Key('observationNotesField'),
                              controller: _notesController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: BestiaryPalette.page,
                                hintText: 'Describe behaviour, habitat, weather, calls, tracks or signs…',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                key: const Key('saveObservationButton'),
                                onPressed: _savingObservation
                                    ? null
                                    : _saveObservation,
                                icon: const Icon(Icons.save_alt_rounded),
                                label: Text(
                                  _savingObservation ? 'Saving' : 'Save note',
                                ),
                                style: FilledButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _showPhotoOptions,
                                icon: const Icon(Icons.add_a_photo_rounded),
                                label: const Text(
                                  'Add a photo from camera or gallery',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          if (_selectedTab == 1 &&
              (observations.isNotEmpty || _loadingObservations))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Recent field entries',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text('${observations.length} saved'),
                  ],
                ),
              ),
            ),
          if (_selectedTab == 1 && _loadingObservations)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_selectedTab == 1 && observations.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final observation = observations[index];
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: ListTile(
                    leading: observation.photoBytes == null
                        ? const CircleAvatar(
                            child: Icon(Icons.menu_book_rounded),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              Uint8List.fromList(observation.photoBytes!),
                              width: 54,
                              height: 54,
                              fit: BoxFit.cover,
                            ),
                          ),
                    title: Text(observation.speciesName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            _formatDate(observation.observedAt),
                            if (observation.location.isNotEmpty)
                              observation.location,
                          ].join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          observation.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _showObservationDetails(observation),
                  ),
                );
              }, childCount: observations.length),
            ),
          if (_selectedTab == 1 &&
              observations.isEmpty &&
              !_loadingObservations)
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: BestiaryPalette.moss,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your field journal is waiting.',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Open the notebook above to begin your first entry. '
                          'Your notes and photos stay on this device.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedTab == 2)
            _buildTabHeading(
              eyebrow: 'CURATED REGIONAL SPECIES',
              title: 'The field guide',
              subtitle: 'Names, identification notes and natural history from the region.',
              icon: Icons.auto_stories_rounded,
            ),
          if (_selectedTab == 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: TextField(
                  key: const Key('speciesSearchField'),
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: 'Search species, region or scientific name',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                  ),
                ),
              ),
            ),
          if (_selectedTab == 2)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  key: const Key('categoryFilterBar'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return ChoiceChip(
                      key: Key('categoryChip-$category'),
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                    );
                  },
                ),
              ),
            ),
          if (_selectedTab == 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    key: const Key('regionalFilterBar'),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: regions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final region = regions[index];
                      final isSelected = selectedRegion == region;
                      return ChoiceChip(
                        key: Key('regionChip-$region'),
                        label: Text(region),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => selectedRegion = region),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (_selectedTab == 2)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Species guide',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF263B2A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredSpecies.length} species',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedTab == 2 && filteredSpecies.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No matching species found.'),
                ),
              ),
            )
          else if (_selectedTab == 2)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final species = filteredSpecies[index];
                  final isFavorite = favorites.contains(species.id);

                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpeciesDetailPage(species: species),
                        ),
                      );
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 124,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SpeciesReferencePhoto(
                                  species: species,
                                  height: 124,
                                ),
                                Positioned(
                                  left: 12,
                                  top: 12,
                                  child: Text(
                                    'FIELD GUIDE  ·  ${(index + 1).toString().padLeft(2, '0')}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: const Color(0xFFE8DFC8),
                                        ),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  bottom: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _categoryIcon(species.category),
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          species.category.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Center icon removed for unobstructed photo
                                Positioned(
                                  right: 5,
                                  top: 4,
                                  child: IconButton(
                                    tooltip: isFavorite
                                        ? 'Remove favorite'
                                        : 'Add favorite',
                                    onPressed: () {
                                      setState(() {
                                        if (isFavorite) {
                                          favorites.remove(species.id);
                                        } else {
                                          favorites.add(species.id);
                                        }
                                      });
                                    },
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: isFavorite
                                          ? const Color(0xFFFFDBCB)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  species.commonName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontFamily: 'serif',
                                        fontSize: 17,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  species.scientificName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  species.region,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 9),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _SpeciesTag(
                                      label: species.category,
                                      color: BestiaryPalette.sage,
                                      foreground: BestiaryPalette.forest,
                                    ),
                                    _SpeciesTag(
                                      label: species.status,
                                      color: _statusColor(species.status)
                                          .withValues(alpha: 0.12),
                                      foreground: _statusColor(species.status),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: filteredSpecies.length),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (MediaQuery.sizeOf(context).width / 220)
                      .floor()
                      .clamp(2, 5),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: MediaQuery.sizeOf(context).width < 500
                      ? 0.68
                      : 0.78,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDailyWidgetInstructions() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add your daily animal'),
        content: const Text(
          'On your Android home screen, touch and hold an empty area, tap '
          'Widgets, find J&K Bestiary, then drag the Daily animal widget onto '
          'your screen. Its name, scientific name and curated fun fact work '
          'offline. The photo loads from iNaturalist when internet is available '
          'and is cached only when its license allows reuse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Extinct in region':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Mammal':
        return Icons.pets_rounded;
      case 'Bird':
        return Icons.flutter_dash_rounded;
      case 'Reptile':
        return Icons.park_rounded;
      case 'Fish':
        return Icons.water_drop_rounded;
      case 'Insect':
        return Icons.bug_report_rounded;
      case 'Amphibian':
        return Icons.water_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class FavoritesPage extends StatelessWidget {
  final List<ZoologySpecies> species;

  const FavoritesPage({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Field bookmarks')),
      body: species.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bookmark_border_rounded,
                      size: 42,
                      color: BestiaryPalette.moss,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No field bookmarks yet.',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap the bookmark on a guide entry to keep it close.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                const BestiaryBanner(
                  eyebrow: 'Your field marks',
                  title: 'Field bookmarks',
                  subtitle: 'Species you have marked for another look.',
                  height: 170,
                ),
                const SizedBox(height: 14),
                ...species.map(
                  (animal) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_rounded),
                      title: Text(
                        animal.commonName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontFamily: 'serif'),
                      ),
                      subtitle: Text(
                        animal.scientificName,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      trailing: const Icon(Icons.arrow_outward_rounded),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpeciesDetailPage(species: animal),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CollectionStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _CollectionStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BestiaryPalette.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BestiaryPalette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: BestiaryPalette.moss),
          const SizedBox(width: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontFamily: 'serif', fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: outlined
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.14),
        side: BorderSide(
          color: Colors.white.withValues(alpha: outlined ? 0.32 : 0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SpeciesTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;

  const _SpeciesTag({
    required this.label,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class FaunaQuizController extends ChangeNotifier {
  final List<FaunaQuizQuestion> _initialQuestions;
  late List<FaunaQuizQuestion> _questions;
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  bool _isCompleted = false;

  FaunaQuizController({List<FaunaQuizQuestion>? questions})
      : _initialQuestions =
            List.unmodifiable(questions ?? kFaunaQuizQuestions) {
    _questions = List.from(_initialQuestions);
    if (_questions.isEmpty) {
      _isCompleted = true;
    }
  }

  List<FaunaQuizQuestion> get questions => List.unmodifiable(_questions);
  int get currentIndex => _currentIndex;
  int get questionIndex => _currentIndex;
  int? get selectedAnswer => _selectedAnswer;
  bool get answered => _answered;
  bool get isAnswered => _answered;
  int get score => _score;
  bool get isCompleted => _isCompleted;
  int get totalQuestions => _questions.length;

  FaunaQuizQuestion? get currentQuestion => _questions.isEmpty
      ? null
      : _questions[_currentIndex % _questions.length];

  void selectAnswer(int index) {
    if (_answered || _isCompleted || _questions.isEmpty) return;
    final current = currentQuestion;
    if (current == null) return;
    _selectedAnswer = index;
    _answered = true;
    if (index == current.correctIndex) {
      _score++;
    }
    notifyListeners();
  }

  void nextQuestion() {
    if ((!_answered && !_isCompleted) || _questions.isEmpty) return;
    if (_isCompleted) return;

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswer = null;
      _answered = false;
    } else {
      _isCompleted = true;
      _selectedAnswer = null;
      _answered = false;
    }
    notifyListeners();
  }

  void restartQuiz({bool shuffle = false}) {
    _currentIndex = 0;
    _selectedAnswer = null;
    _answered = false;
    _score = 0;
    _isCompleted = false;
    if (shuffle) {
      _questions = List.from(_initialQuestions)..shuffle();
    } else {
      _questions = List.from(_initialQuestions);
    }
    if (_questions.isEmpty) {
      _isCompleted = true;
    }
    notifyListeners();
  }
}

class InteractiveFaunaChallengeCard extends StatefulWidget {
  final FaunaQuizController? controller;
  final List<FaunaQuizQuestion>? questions;

  const InteractiveFaunaChallengeCard({
    super.key,
    this.controller,
    this.questions,
  });

  @override
  State<InteractiveFaunaChallengeCard> createState() =>
      _InteractiveFaunaChallengeCardState();
}

class _InteractiveFaunaChallengeCardState
    extends State<InteractiveFaunaChallengeCard> {
  FaunaQuizController? _localController;

  FaunaQuizController get _effectiveController =>
      widget.controller ?? _localController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _localController = FaunaQuizController(
        questions: widget.questions ?? kFaunaQuizQuestions,
      );
    }
  }

  @override
  void didUpdateWidget(InteractiveFaunaChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && _localController == null) {
      _localController = FaunaQuizController(
        questions: widget.questions ?? kFaunaQuizQuestions,
      );
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _effectiveController,
      builder: (context, _) {
        final controller = _effectiveController;
        if (controller.isCompleted) {
          return _buildCompletionView(context, controller);
        }
        final q = controller.currentQuestion;
        if (q == null) {
          return _buildEmptyView(context, controller);
        }
        return _buildQuestionCard(context, controller, q);
      },
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    FaunaQuizController controller,
    FaunaQuizQuestion q,
  ) {
    final options = q.options;
    final correct = q.correctIndex;
    final answered = controller.answered;
    final selectedAnswer = controller.selectedAnswer;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BestiaryPalette.brass.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BestiaryPalette.rust,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'INTERACTIVE FAUNA CHALLENGE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'Question ${controller.currentIndex + 1}/${controller.totalQuestions}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Score: ${controller.score} / ${controller.totalQuestions}',
            style: const TextStyle(
              fontSize: 12,
              color: BestiaryPalette.forest,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            q.prompt,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: answered
                    ? null
                    : () {
                        controller.selectAnswer(i);
                        HapticFeedback.lightImpact();
                      },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: !answered
                        ? Colors.white
                        : i == correct
                            ? const Color(0xFFE8F5E9)
                            : i == selectedAnswer
                                ? const Color(0xFFFFEBEE)
                                : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !answered
                          ? const Color(0xFFE0E0E0)
                          : i == correct
                              ? const Color(0xFF4CAF50)
                              : i == selectedAnswer
                                  ? const Color(0xFFE57373)
                                  : const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !answered
                            ? Icons.radio_button_unchecked
                            : i == correct
                                ? Icons.check_circle_rounded
                                : i == selectedAnswer
                                    ? Icons.cancel_rounded
                                    : Icons.radio_button_unchecked,
                        size: 20,
                        color: !answered
                            ? Colors.black38
                            : i == correct
                                ? const Color(0xFF2E7D32)
                                : i == selectedAnswer
                                    ? const Color(0xFFC62828)
                                    : Colors.black26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == correct && answered
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (answered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4F8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                q.explanation,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  controller.nextQuestion();
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Next Question'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionView(
    BuildContext context,
    FaunaQuizController controller,
  ) {
    final total = controller.totalQuestions;
    final score = controller.score;
    final percent = total > 0 ? ((score / total) * 100).round() : 0;
    final String rank;
    if (percent >= 100) {
      rank = '🏆 Himalayan Master Naturalist';
    } else if (percent >= 80) {
      rank = '🦌 Wildlife Field Biologist';
    } else if (percent >= 60) {
      rank = '🌲 Apprentice Ranger';
    } else {
      rank = '🔍 Junior Field Scout';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BestiaryPalette.brass.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: BestiaryPalette.rust,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'INTERACTIVE FAUNA CHALLENGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Icon(
            Icons.emoji_events_rounded,
            size: 48,
            color: BestiaryPalette.brass,
          ),
          const SizedBox(height: 8),
          const Text(
            'Fauna Challenge Complete!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2E1E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Final Score: $score / $total ($percent%)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: BestiaryPalette.forest,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BestiaryPalette.sage.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rank,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E2D),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => controller.restartQuiz(shuffle: false),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('Restart Quiz'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.restartQuiz(shuffle: true),
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('Shuffle Questions'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(
    BuildContext context,
    FaunaQuizController controller,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BestiaryPalette.brass.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'INTERACTIVE FAUNA CHALLENGE',
            style: TextStyle(
              color: BestiaryPalette.rust,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No fauna quiz questions available.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => controller.restartQuiz(),
            child: const Text('Reload Questions'),
          ),
        ],
      ),
    );
  }
}

/// Computes the relevance tier of a species for a given search query:
/// - Tier 0: Exact match on `commonName`, `scientificName`, or `id`.
/// - Tier 1: Prefix match (`startsWith`) on `commonName`, `scientificName`, or vernacular synonyms (`searchTerms`).
/// - Tier 2: Substring word-boundary match within `commonName`, `scientificName`, or `searchTerms`.
/// - Tier 3: Taxonomy matches (Order, Family, Genus).
/// - Tier 4: Matches occurring in descriptive text (habitat, diet, ecological role, etc.).
int computeSpeciesRelevanceTier(ZoologySpecies s, String query) {
  final cleanQuery = query
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleanQuery.isEmpty) return 4;

  final rawQuery = cleanQuery;
  final qSpaced = rawQuery
      .replaceAll(RegExp(r'[\-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (qSpaced.isEmpty) return 4;
  final qHyphen = qSpaced.replaceAll(' ', '-');
  final queryTokens = rawQuery
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList();

  final idLower = s.id.toLowerCase();
  final idSpaced = idLower.replaceAll('-', ' ');
  final commonLower = s.commonName.toLowerCase();
  final commonSpaced = commonLower.replaceAll(RegExp(r'[\-_]+'), ' ').trim();
  final sciLower = s.scientificName.toLowerCase();

  final commonClean = commonLower
      .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final commonCleanSpaced = commonClean
      .replaceAll(RegExp(r'[\-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final primaryCommon = commonLower
      .split('(')
      .first
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final primaryCommonSpaced = primaryCommon
      .replaceAll(RegExp(r'[\-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  final parentheticalCommon = commonLower.contains('(')
      ? commonLower
          .split('(')[1]
          .replaceAll(')', '')
          .trim()
          .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
      : '';
  final parentheticalSpaced = parentheticalCommon
      .replaceAll(RegExp(r'[\-_]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ---------------------------------------------------------------
  // Tier 0: Exact match on commonName, scientificName, or id
  // ---------------------------------------------------------------
  if (idLower == rawQuery ||
      idLower == qHyphen ||
      idSpaced == qSpaced ||
      commonLower == rawQuery ||
      commonSpaced == qSpaced ||
      commonClean == rawQuery ||
      commonClean == qSpaced ||
      commonCleanSpaced == qSpaced ||
      primaryCommon == rawQuery ||
      primaryCommon == qSpaced ||
      primaryCommonSpaced == qSpaced ||
      (parentheticalCommon.isNotEmpty &&
          (parentheticalCommon == rawQuery ||
              parentheticalCommon == qSpaced ||
              parentheticalSpaced == qSpaced)) ||
      sciLower == rawQuery ||
      sciLower == qSpaced) {
    return 0;
  }

  // ---------------------------------------------------------------
  // Tier 1: Prefix match (startsWith) on commonName, scientificName,
  // or vernacular synonyms (searchTerms like "hangul", "drenmo", "shan")
  // ---------------------------------------------------------------
  if (commonLower.startsWith(rawQuery) ||
      commonSpaced.startsWith(qSpaced) ||
      commonClean.startsWith(rawQuery) ||
      commonClean.startsWith(qSpaced) ||
      commonCleanSpaced.startsWith(qSpaced) ||
      primaryCommon.startsWith(rawQuery) ||
      primaryCommon.startsWith(qSpaced) ||
      primaryCommonSpaced.startsWith(qSpaced) ||
      (parentheticalCommon.isNotEmpty &&
          (parentheticalCommon.startsWith(rawQuery) ||
              parentheticalCommon.startsWith(qSpaced) ||
              parentheticalSpaced.startsWith(qSpaced))) ||
      sciLower.startsWith(rawQuery) ||
      sciLower.startsWith(qSpaced) ||
      idLower.startsWith(rawQuery) ||
      idLower.startsWith(qHyphen) ||
      idSpaced.startsWith(qSpaced)) {
    return 1;
  }

  for (final term in s.searchTerms) {
    final tLower = term.toLowerCase();
    final tClean = tLower
        .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tSpaced = tClean
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (tLower == rawQuery ||
        tClean == rawQuery ||
        tClean == qSpaced ||
        tSpaced == qSpaced ||
        (!tClean.contains(' ') && tClean.startsWith(rawQuery)) ||
        (!tSpaced.contains(' ') && tSpaced.startsWith(qSpaced)) ||
        (!tLower.contains(' ') && tLower.startsWith(rawQuery))) {
      return 1;
    }
  }

  // ---------------------------------------------------------------
  // Tier 2: Substring word-boundary match within commonName,
  // scientificName, or searchTerms
  // ---------------------------------------------------------------
  final escapedSpaced = RegExp.escape(qSpaced);
  final escapedRaw = RegExp.escape(rawQuery);
  final boundaryPattern = RegExp(r'\b' + escapedSpaced, caseSensitive: false);
  final rawBoundaryPattern = RegExp(r'\b' + escapedRaw, caseSensitive: false);

  if (boundaryPattern.hasMatch(commonSpaced) ||
      boundaryPattern.hasMatch(commonCleanSpaced) ||
      rawBoundaryPattern.hasMatch(commonClean) ||
      rawBoundaryPattern.hasMatch(commonLower) ||
      boundaryPattern.hasMatch(sciLower) ||
      rawBoundaryPattern.hasMatch(sciLower)) {
    return 2;
  }

  for (final term in s.searchTerms) {
    final tLower = term.toLowerCase();
    final tClean = tLower
        .replaceAll(RegExp(r'[^a-z0-9\s\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final tSpaced = tClean
        .replaceAll(RegExp(r'[\-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (boundaryPattern.hasMatch(tSpaced) ||
        rawBoundaryPattern.hasMatch(tClean) ||
        rawBoundaryPattern.hasMatch(tLower) ||
        tSpaced.contains(qSpaced) ||
        tClean.contains(rawQuery) ||
        tLower.contains(rawQuery)) {
      return 2;
    }
  }

  if (commonLower.contains(rawQuery) ||
      commonClean.contains(rawQuery) ||
      commonSpaced.contains(qSpaced) ||
      commonCleanSpaced.contains(qSpaced) ||
      sciLower.contains(rawQuery) ||
      sciLower.contains(qSpaced)) {
    return 2;
  }

  final nameTokens = [
    ...commonLower.split(RegExp(r'[^a-z0-9]+')),
    ...commonClean.split(RegExp(r'[^a-z0-9]+')),
    ...sciLower.split(RegExp(r'[^a-z0-9]+')),
  ];
  if (queryTokens.any((qTok) => nameTokens.any((nTok) => nTok.startsWith(qTok)))) {
    return 2;
  }

  // ---------------------------------------------------------------
  // Tier 3: Taxonomy matches (Order, Family, Genus)
  // ---------------------------------------------------------------
  for (final taxValue in s.taxonomy.values) {
    final taxLower = taxValue.toLowerCase();
    if (taxLower == rawQuery ||
        taxLower.startsWith(rawQuery) ||
        taxLower.contains(rawQuery) ||
        taxLower.contains(qSpaced)) {
      return 3;
    }
  }

  // ---------------------------------------------------------------
  // Tier 4: Matches occurring only in descriptive text (habitat, diet, etc.)
  // ---------------------------------------------------------------
  return 4;
}
