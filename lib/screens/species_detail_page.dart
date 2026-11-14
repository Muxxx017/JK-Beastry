import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoology_app/data/species_data.dart';
import 'package:zoology_app/models/zoology_species.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';
import 'package:zoology_app/widgets/bestiary_mark.dart';
import 'package:zoology_app/widgets/field_landscape.dart';
import 'package:zoology_app/widgets/offline_species_download_button.dart';
import 'package:zoology_app/widgets/species_reference_photo.dart';

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
                SpeciesReferencePhoto(species: species, height: 280),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OfflineSpeciesDownloadButton(species: species)),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pop(species.commonName),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Log Sighting'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: .72),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const BestiaryMark(),
                            const SizedBox(height: 8),
                            Text(
                              species.commonName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              species.scientificName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 17,
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
                    'Also known as: ${species.searchTerms.join(' · ')}',
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
                    _InfoChip(
                      label: 'Conservation',
                      value: species.conservation,
                    ),
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
                // Interactive vocalization call player or educational acoustic card
                if ((species.isVocal && species.vocalization.trim().isNotEmpty) || !species.isVocal)
                  InteractiveVocalizationWidget(species: species),
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
                    OutlinedButton.icon(
                      onPressed: () => _openReference(
                        context,
                        Uri.https('www.iucnredlist.org', '/search', {
                          'query': species.scientificName,
                        }),
                      ),
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('IUCN Red List'),
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
            color: BestiaryPalette.page,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BestiaryPalette.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FUN FACT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: BestiaryPalette.moss,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
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
          _SectionTitle(title: title),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _openReference(BuildContext context, Uri url) {
    launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

class InteractiveVocalizationWidget extends StatefulWidget {
  final ZoologySpecies? species;
  final String? vocalization;
  final String? commonName;
  final String? audioAsset;
  final bool? isVocal;
  final String? vocalizationNote;
  final AudioPlayer? player;
  final bool autoPlay;

  const InteractiveVocalizationWidget({
    super.key,
    this.species,
    this.vocalization,
    this.commonName,
    this.audioAsset,
    this.isVocal,
    this.vocalizationNote,
    this.player,
    this.autoPlay = false,
  });

  @override
  State<InteractiveVocalizationWidget> createState() =>
      InteractiveVocalizationWidgetState();
}

class InteractiveVocalizationWidgetState
    extends State<InteractiveVocalizationWidget>
    with SingleTickerProviderStateMixin {
  late final AudioPlayer _player;
  bool _ownsPlayer = false;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;
  bool _isPlaying = false;
  late AnimationController _controller;

  PlayerState get playerState => _playerState;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;

  String get _resolvedCommonName =>
      widget.commonName ?? widget.species?.commonName ?? 'Fauna';

  String get _resolvedVocalization =>
      widget.vocalization ?? widget.species?.vocalization ?? '';

  bool get _resolvedIsVocal =>
      widget.isVocal ?? widget.species?.isVocal ?? true;

  String? get _resolvedVocalizationNote =>
      widget.vocalizationNote ?? widget.species?.vocalizationNote;

  String? get _resolvedAudioAsset {
    if (widget.audioAsset != null) return widget.audioAsset;
    if (widget.species?.audioAsset != null) return widget.species!.audioAsset;
    final match = kSpeciesCatalog.cast<ZoologySpecies?>().firstWhere(
      (s) =>
          s != null &&
          s.commonName.toLowerCase() == _resolvedCommonName.toLowerCase(),
      orElse: () => null,
    );
    return match?.audioAsset;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ownsPlayer = widget.player == null;
    _player = widget.player ?? AudioPlayer();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
        _isPlaying = (state == PlayerState.playing);
        if (_isPlaying) {
          _controller.repeat(reverse: true);
        } else {
          _controller.stop();
        }
      });
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() => _duration = dur);
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playerState = PlayerState.completed;
        _isPlaying = false;
        _position = Duration.zero;
        _controller.stop();
      });
    });

    if (widget.autoPlay && _resolvedIsVocal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _togglePlay();
      });
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    if (_ownsPlayer) {
      _player.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playerState = PlayerState.playing;
        _controller.repeat(reverse: true);
      } else {
        _playerState = PlayerState.paused;
        _controller.stop();
      }
    });

    _syncAudioPlayback();
  }

  Future<void> _syncAudioPlayback() async {
    final assetPath = _resolvedAudioAsset;
    if (_isPlaying) {
      if (assetPath != null && assetPath.trim().isNotEmpty) {
        try {
          final cleanPath = assetPath.startsWith('assets/')
              ? assetPath.substring(7)
              : assetPath;
          await _player.play(AssetSource(cleanPath));
        } catch (_) {
          // Gracefully handle missing device audio sink in test environments
        }
      }
    } else {
      try {
        await _player.pause();
      } catch (_) {}
    }
  }

  Future<void> _seek(double value) async {
    final target = Duration(milliseconds: value.round());
    try {
      await _player.seek(target);
    } catch (_) {}
    if (mounted) {
      setState(() => _position = target);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolvedIsVocal) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BestiaryPalette.forest.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: BestiaryPalette.forest,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMUNICATION & ACOUSTICS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: BestiaryPalette.forest,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                        ),
                        Text(
                          'Non-vocal species communication mechanisms',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: BestiaryPalette.moss,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _resolvedVocalizationNote ??
                            (_resolvedVocalization.isNotEmpty
                                ? _resolvedVocalization
                                : 'This species lacks audible vocal cords and communicates via non-vocal sensory signals (substrate vibrations, chemical pheromones, or visual dewlap displays).'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black87,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_resolvedVocalization.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _resolvedVocalization,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: BestiaryPalette.forest,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  onPressed: _togglePlay,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VOCALIZATION & SOUNDS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: BestiaryPalette.forest,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                      ),
                      Text(
                        _isPlaying
                            ? 'Simulating acoustic wave for $_resolvedCommonName...'
                            : 'Tap to simulate audio call',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isPlaying)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(24, (index) {
                        final wave = (math.sin(
                                    _controller.value * math.pi * 2 +
                                        index * 0.45) +
                                1) /
                            2;
                        final height = 6.0 + wave * 22.0;
                        return Container(
                          width: 4,
                          height: height,
                          decoration: BoxDecoration(
                            color: BestiaryPalette.forest.withValues(
                              alpha: 0.6 + wave * 0.4,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            if (_resolvedAudioAsset != null || _duration > Duration.zero) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: BestiaryPalette.moss,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: BestiaryPalette.forest,
                          inactiveTrackColor: const Color(0xFFC8E6C9),
                          thumbColor: BestiaryPalette.forest,
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? _position.inMilliseconds
                                  .clamp(0, _duration.inMilliseconds)
                                  .toDouble()
                              : 0.0,
                          max: _duration.inMilliseconds > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: _duration.inMilliseconds > 0
                              ? (val) => _seek(val)
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            if (_resolvedVocalization.isNotEmpty)
              Text(
                _resolvedVocalization,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (_resolvedVocalizationNote != null &&
                _resolvedVocalizationNote != _resolvedVocalization) ...[
              const SizedBox(height: 6),
              Text(
                'Bio-acoustic note: $_resolvedVocalizationNote',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
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

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: BestiaryPalette.page,
      side: const BorderSide(color: BestiaryPalette.line),
    );
  }
}

class _LocalTaxonomy extends StatelessWidget {
  final ZoologySpecies species;

  const _LocalTaxonomy({required this.species});

  @override
  Widget build(BuildContext context) {
    final ranks = ['Kingdom', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];
    final items = ranks
        .where((rank) => species.taxonomy.containsKey(rank))
        .map((rank) => MapEntry(rank, species.taxonomy[rank]!))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Taxonomic hierarchy'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BestiaryPalette.page,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BestiaryPalette.line),
          ),
          child: Column(
            children: items.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        e.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: BestiaryPalette.moss,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontStyle: e.key == 'Genus' || e.key == 'Species'
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
