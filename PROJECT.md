# Project: J&K Bestiary (Jammu & Kashmir Fauna Field Guide)

## Architecture
- **Framework**: Flutter (Dart 3.x), Material Design 3, offline-first local state architecture.
- **Data Layer**:
  - `lib/models/zoology_species.dart`: Canonical `ZoologySpecies` data model representing species taxonomy, common/vernacular names, status, habitat, diet, vocalization, and media metadata.
  - `lib/data/species_data.dart`: `kSpeciesCatalog` containing comprehensive curated regional fauna records across Mammals, Birds, Reptiles, Amphibians, Fish, and Invertebrates.
  - `lib/data/observation_store.dart`: User field observations stored in local `SharedPreferences`.
  - `lib/data/offline_taxa_store.dart`: Downloaded and cached species stored locally.
- **Service Layer**:
  - `lib/services/inat_service.dart`: iNaturalist and GBIF API integration for online fauna queries and observations.
  - `lib/services/offline_species_service.dart`: Local cache resolution for species imagery, audio, and observation synchronization.
- **Presentation Layer**:
  - `lib/main.dart`: Navigation shell with tabs (Discover, Guide/Catalog, Field Journal, Settings). Host to Fauna Challenge Quiz Card, Category Filters, Regional Filters, and Guide Search.
  - `lib/screens/species_detail_page.dart`: Full zoological field profile, taxonomy badges, IUCN status, physical traits, habitat distribution, and audio vocalization player.
  - `lib/screens/online_species_page.dart`: Online wildlife atlas search with curated offline fallback matching.
  - `lib/widgets/species_reference_photo.dart`: Network image loader with verified URLs, memory caching, and bundled offline asset fallbacks.
  - `lib/widgets/interactive_vocalization_widget.dart` (or within detail page): Real audio playback for species calls with offline fallbacks.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F1 | Accurate Species Imagery (R1) | Replace broken 400/404 URLs with verified endpoints, bundle offline fallback images for all species, fix ID naming mismatches. | M2 | ORIGINAL_REQUEST § R1 |
| F2 | Interactive Fauna Quiz (R2) | Dynamic question cycling, 30+ question bank, shuffle, score tracking, and tab-persistence without stalling. | M5 | ORIGINAL_REQUEST § R2 |
| F3 | Animal Vocalizations & Audio (R3) | Add `audioplayers`, bundle authentic regional animal calls in `assets/audio/`, implement functional playback in detail view. | M3 | ORIGINAL_REQUEST § R3 |
| F4 | Search Matching & Discovery (R4) | Word-boundary token matching, hyphen normalization, tiered relevance sorting (names > aliases > taxonomy > body), and partial matching. | M4 | ORIGINAL_REQUEST § R4 |
| F5 | Regional Fauna Catalog Expansion (R5) | Expand `kSpeciesCatalog` across 5 taxa (Mammals, Birds, Reptiles, Amphibians, Invertebrates), strictly 0 plants, correct Hangul nomenclature. | M1 | ORIGINAL_REQUEST § R5 |
| F6 | Zoology Feature Upgrades (R6) | Regional filtering (Jammu, Kashmir, Ladakh, Pir Panjal), IUCN status filtering, vernacular name indexing, acoustic education for non-vocal species. | M1, M4 | ORIGINAL_REQUEST § R6 |
| F7 | Quality Assurance & Release (R7) | Zero analyzer issues, 100% passing automated test suite (Tiers 1-4), clean `flutter build apk --release`. | M6 | ORIGINAL_REQUEST § R7 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Catalog & Zoology Data Expansion | Expand `kSpeciesCatalog` to ~140 native species across 5 taxa; scrub all residual flora text; fix Hangul nomenclature; add audio metadata and region tags. | none | DONE (144 species across 6 classes, 0 plants, 145/145 tests pass) |
| M2 | Media & Offline Imagery Pipeline | Eliminate 400/404 errors; update image URLs to verified iNaturalist endpoints; bundle fallback assets in `assets/species/`; fix asset ID mapping. | M1 | DONE (144 verified URLs, 146 offline bundled assets, tap-to-zoom & credit overlay verified, 161/161 tests pass) |
| M3 | Audio Playback Engine & Vocalizations | Add `audioplayers`; bundle authentic audio in `assets/audio/`; wire playback with offline support; acoustic notes for non-vocal fauna. | M1 | DONE (20 bundled audio files in assets/audio/, genuine AudioPlayer playback, 184/184 tests pass) |
| M4 | Search & Regional Discovery Upgrades | Implement tiered relevance ranking, hyphen/punctuation sanitization, partial search in online explorer, and regional filter bar. | M1 | DONE (Tiered relevance ranking, symmetric normalization, regional filter bar, 100% taxa discoverability across 144 species, 281/281 tests pass) |
| M5 | Interactive Fauna Quiz Expansion & State | Expand to 30+ question bank; implement question cycling, shuffle, scoring, and tab state preservation. | M1 | DONE (37 regional questions across 6 classes, 0 flora, FaunaQuizController tab persistence, score tracking, completion summary, 305/305 tests pass) |
| M6 | E2E Testing, Quality Assurance & Build Release | Requirement-driven E2E tests (Tiers 1-4); pass 100% test suite; zero analyzer errors; release APK build verification. | M2, M3, M4, M5 | DONE (389/389 tests pass across Tiers 1-5, 0 analyzer issues, release APK built at 87.39 MB, clean audit) |

## Interface Contracts
### Data Model (`ZoologySpecies`) ↔ All Modules
- `id`: unique kebab-case identifier (e.g. `cervus-hanglu-hanglu`, `panthera-uncia`).
- `commonName`: primary English common name.
- `scientificName`: valid binomen/trinomen (e.g. `Cervus hanglu hanglu`).
- `category`: strictly one of `'Mammal'`, `'Bird'`, `'Reptile'`, `'Amphibian'`, `'Fish'`, `'Insect'`.
- `region`: primary biogeographical region (`'Kashmir'`, `'Jammu'`, `'Ladakh'`, `'Trans-Himalaya'`, `'Pir Panjal'`).
- `audioAsset`: nullable String path to bundled offline sound (e.g. `assets/audio/hangul.mp3`).
- `isVocal`: boolean flag indicating whether the species vocalizes.
- `searchTerms`: list of regional aliases, vernacular names, and taxonomic synonyms.

### Media Pipeline ↔ UI Presentation
- `SpeciesReferencePhoto`: Takes `ZoologySpecies species`. Checks bundled asset in `assets/species/${species.id}.jpg`. If absent, loads verified network URL. On error or offline, falls back to bundled asset or zoological art plate. Never throws unhandled HTTP 400/404 exceptions.

### Audio Player ↔ Detail Page
- `InteractiveVocalizationWidget`: Takes `ZoologySpecies species`. If `species.isVocal` is true and audio is present, plays `species.audioAsset` via `AudioPlayer`. Handles play, pause, seek, completion, and offline mode. If `species.isVocal` is false, displays educational acoustic card explaining non-vocal communication.

## Code Layout
- `lib/models/`: Data models (`zoology_species.dart`, `observation.dart`).
- `lib/data/`: Static catalogs and local storage (`species_data.dart`, `observation_store.dart`, `offline_taxa_store.dart`).
- `lib/services/`: External API and offline cache services (`inat_service.dart`, `offline_species_service.dart`).
- `lib/screens/`: App screens (`species_detail_page.dart`, `online_species_page.dart`).
- `lib/widgets/`: Modular UI widgets (`species_reference_photo.dart`, `interactive_vocalization_widget.dart`).
- `assets/species/`: Bundled offline species imagery.
- `assets/audio/`: Bundled offline animal vocalization audio files.
- `test/`: Unit, widget, and E2E test suites.
