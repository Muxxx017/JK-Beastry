# E2E Test Infra: J&K Bestiary

## Test Philosophy
- Opaque-box, requirement-driven testing. Verification tests the product from the perspective of an end user and zoological field researcher, derived strictly from `ORIGINAL_REQUEST.md`.
- No internal coupling or mock circumvention.
- Testing methodology: Category-Partition, Boundary Value Analysis, Pairwise Interaction Testing, and Real-World Zoological Field Guide Workflows.

## Feature Inventory
| # | Feature | Source (Requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Accurate Species Imagery (R1) | ORIGINAL_REQUEST § R1 | 5 | 5 | ✓ |
| 2 | Interactive Fauna Quiz (R2) | ORIGINAL_REQUEST § R2 | 5 | 5 | ✓ |
| 3 | Animal Vocalizations & Audio (R3) | ORIGINAL_REQUEST § R3 | 5 | 5 | ✓ |
| 4 | Search Matching & Discovery (R4) | ORIGINAL_REQUEST § R4 | 5 | 5 | ✓ |
| 5 | Regional Fauna Catalog Expansion (R5) | ORIGINAL_REQUEST § R5 | 5 | 5 | ✓ |
| 6 | Zoology Feature Upgrades (R6) | ORIGINAL_REQUEST § R6 | 5 | 5 | ✓ |
| 7 | Zero Analyzer & Clean Build (R7) | ORIGINAL_REQUEST § R7 | 5 | 5 | ✓ |

## Test Architecture
- **Test Runner**: Flutter Test framework (`flutter test`).
- **Test Locations**:
  - `test/e2e/tier1_feature_coverage_test.dart`: Isolates and verifies each individual feature (F1-F7).
  - `test/e2e/tier2_boundary_corner_test.dart`: Exercises edge conditions (hyphenated queries, empty search, special characters, rapid quiz cycling, offline fallback triggers, non-vocal species audio handling).
  - `test/e2e/tier3_cross_feature_test.dart`: Exercises pairwise interactions (search + detail audio playback, filter + quiz facts, offline mode + image fallbacks).
  - `test/e2e/tier4_real_world_scenarios_test.dart`: End-to-end user workflows (field observation, multi-taxa guide browsing, full quiz challenge run).

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Field Explorer Dachigam Expedition | Search Hangul by vernacular name "hangul", view detail page, verify offline photo loads, trigger vocalization. | Medium |
| 2 | High-Altitude Ladakh Snow Leopard Survey | Filter by Region "Ladakh" and Category "Mammal", verify Snow Leopard and Tibetan Wolf appear, check conservation status. | Medium |
| 3 | Wildlife Quiz Master Session | Launch Fauna Challenge card, cycle through 10+ questions, answer correctly/incorrectly, verify score updates and refresh. | High |
| 4 | Multi-Taxa Field Guide Discovery | Iterate through Mammal, Bird, Reptile, Amphibian, and Insect categories, verify zero plants, verify complete taxonomy. | High |
| 5 | Complete Offline Field Mode | Simulate network failure, browse catalog, verify zero 400/404 image errors, verify offline audio notes, verify observation notes store. | High |

## Coverage Thresholds
- Tier 1: ≥35 test cases (≥5 per feature across 7 features)
- Tier 2: ≥35 test cases (≥5 boundary cases per feature)
- Tier 3: ≥10 test cases (covering major cross-feature pairs)
- Tier 4: ≥5 realistic end-to-end scenarios
- **Total Suite**: ≥85 test cases
