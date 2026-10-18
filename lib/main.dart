import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/data/daily_animal_widget_data.dart';
import 'package:zoology_app/data/observation_store.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/field_observation.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/screens/online_species_page.dart';

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
      title: 'Kashmir Zoology Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF365B43),
          surface: const Color(0xFFFAF9F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF9F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF9F5),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF24372B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF365B43)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            side: BorderSide(color: Color(0xFFE9E8E0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E7DF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE6E7DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF527D5C), width: 1.5),
          ),
        ),
      ),
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

  final List<String> categories = const [
    'All',
    'Mammal',
    'Bird',
    'Reptile',
    'Fish',
    'Insect',
    'Plant',
    'Not recorded',
  ];

  final Set<String> favorites = <String>{};
  final List<FieldObservation> observations = [];
  List<int>? selectedPhotoBytes;
  bool _loadingObservations = true;
  bool _savingObservation = false;
  bool _notebookExpanded = false;
  String selectedCategory = 'All';
  String query = '';

  @override
  void initState() {
    super.initState();
    _loadObservations();
  }

  @override
  void dispose() {
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
      _showMessage('Could not load field notes: $error');
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

  List<ZoologySpecies> get filteredSpecies {
    final normalizedQuery = query.trim().toLowerCase();

    final species = kSpeciesCatalog.where((species) {
      final matchesCategory =
          selectedCategory == 'All' ||
          species.category == selectedCategory ||
          (selectedCategory == 'Not recorded' &&
              species.status == 'Not currently recorded');

      final searchableText = species.searchableText;
      final matchesQuery = normalizedQuery
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty)
          .every(searchableText.contains);

      return matchesCategory && matchesQuery;
    }).toList();
    if (normalizedQuery.isNotEmpty) {
      species.sort((first, second) {
        int relevance(ZoologySpecies item) {
          final name = '${item.commonName} ${item.scientificName}'
              .toLowerCase();
          if (name == normalizedQuery) return 0;
          if (name.startsWith(normalizedQuery)) return 1;
          if (name.contains(normalizedQuery)) return 2;
          return 3;
        }

        return relevance(first).compareTo(relevance(second));
      });
    }
    return species;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('J&K Bestiary'),
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF314F3A),
                  borderRadius: BorderRadius.circular(22),
                ),
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
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'FIELD GUIDE  ·  JAMMU & KASHMIR',
                            style: TextStyle(
                              color: Color(0xFFD5E1CF),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.landscape_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Look closer.\nFind your wild.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A living notebook for the species around you.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroAction(
                          icon: Icons.edit_note_rounded,
                          label: 'Add field note',
                          onPressed: () {
                            setState(() => _notebookExpanded = true);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                Scrollable.ensureVisible(
                                  _notebookKey.currentContext!,
                                  duration: const Duration(milliseconds: 250),
                                );
                              }
                            });
                          },
                        ),
                        _HeroAction(
                          icon: Icons.public_rounded,
                          label: 'Explore online',
                          outlined: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const OnlineSpeciesPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (!kIsWeb &&
                        defaultTargetPlatform == TargetPlatform.android) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _showDailyWidgetInstructions,
                        icon: const Icon(
                          Icons.widgets_outlined,
                          color: Color(0xFFD5E1CF),
                        ),
                        label: const Text(
                          'Add the daily animal home-screen widget',
                          style: TextStyle(color: Color(0xFFD5E1CF)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              key: _notebookKey,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9E8E0)),
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
                              backgroundColor: Color(0xFFEAF0E9),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFF365B43),
                              ),
                            ),
                            title: const Text(
                              'Field notebook',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text('Record a moment outdoors'),
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
                                        fillColor: Colors.white,
                                        hintText: 'Species / unknown sighting',
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
                                        fillColor: Colors.white,
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
                              fillColor: Colors.white,
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
          if (observations.isNotEmpty || _loadingObservations)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  children: [
                    Text(
                      'Recent notes',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text('${observations.length} saved'),
                  ],
                ),
              ),
            ),
          if (_loadingObservations)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
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
                    subtitle: Text(
                      [
                        if (observation.location.isNotEmpty)
                          observation.location,
                        observation.notes,
                        _formatDate(observation.observedAt),
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }, childCount: observations.length),
            ),
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
          SliverToBoxAdapter(
            child: SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => selectedCategory = category),
                  );
                },
              ),
            ),
          ),
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
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (filteredSpecies.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No matching species found.'),
                ),
              ),
            )
          else
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
                          Container(
                            height: 112,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE9EFE6), Color(0xFFDCE7DA)],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: 8,
                                  top: 8,
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
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.red.shade600
                                          : Colors.black45,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Icon(
                                    _categoryIcon(species.category),
                                    size: 40,
                                    color: const Color(0xFF476A4D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                            child: Text(
                              species.commonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF27382C),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              species.scientificName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _SpeciesTag(
                                  label: species.category,
                                  color: const Color(0xFFEAF0E9),
                                  foreground: const Color(0xFF365B43),
                                ),
                                _SpeciesTag(
                                  label: species.status,
                                  color: _statusColor(species.status)
                                      .withValues(alpha: 0.12),
                                  foreground: _statusColor(species.status),
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
                  childAspectRatio: 0.82,
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
      case 'Plant':
        return Icons.local_florist_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class SpeciesDetailPage extends StatelessWidget {
  final ZoologySpecies species;

  const SpeciesDetailPage({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(species.commonName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.teal.shade700],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.commonName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    species.scientificName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
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
              const SizedBox(height: 20),
              _LocalTaxonomy(species: species),
            ],
            const SizedBox(height: 20),
            _detailSection('Region', species.region),
            _detailSection('Identification', species.identification),
            _detailSection('Characteristics', species.feature),
            _detailSection('Habitat', species.habitat),
            _detailSection('Range & local records', species.distribution),
            _detailSection('Diet', species.diet),
            _detailSection('Habit & behavior', species.behavior),
            _detailSection('Life cycle & breeding', species.breeding),
            _detailSection('Ecological role', species.ecologicalRole),
            _detailSection('Threats', species.threats),
            _detailSection('Conservation status', species.conservation),
            _detailSection('Fun fact', species.funFact),
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
    );
  }

  Widget _detailSection(String title, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title),
          Text(value),
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

class FavoritesPage extends StatelessWidget {
  final List<ZoologySpecies> species;

  const FavoritesPage({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: species.isEmpty
          ? const Center(child: Text('No favorite species yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: species.length,
              itemBuilder: (context, index) {
                final animal = species[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(animal.commonName),
                    subtitle: Text(animal.scientificName),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpeciesDetailPage(species: animal),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
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
