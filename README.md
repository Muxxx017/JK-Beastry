# J&K Bestiary

An offline-first Flutter field notebook and species guide, with an online
India-and-Himalaya species explorer.

## Run on a PC

From the project folder:

```powershell
flutter run -d edge
```

## Current features

- Browse a curated offline starter field guide of Jammu & Kashmir animals and
  plants, with identification, range caveats, habitat, diet, behavior, breeding,
  ecology, threats and an explicitly labeled fun fact where available. Offline
  search also matches those facts, not only names.
- Create field observations with a camera/gallery photo, species name, place,
  and notes. Notebook entries are saved on the device.
- Open **Explore species online** to search 50 results per page from
  community-observed animal and plant species in Jammu & Kashmir or across
  India and neighboring Himalayan countries, view regional
  observation counts, reference photos, photo attribution and license,
  conservation status when available, a taxonomic lineage from the GBIF
  Backbone Taxonomy, and a Wikipedia overview when available.
- Tap an online identification photo to open a full-screen viewer; pinch or
  pan to inspect it. Photo attribution and license are retained in the viewer.
- On Android, open the app once, then add the **Daily animal** home-screen
  widget from the launcher’s Widgets picker. It rotates through the curated
  animal facts by day and shows the common name, scientific name and fun fact.
  The text works offline; an iNaturalist reference photo and its credit/license
  load online. Photos are cached only when the license permits reuse.
- Save individual online species facts to an offline library. Online photos and
  full articles are not downloaded with the saved record.
- Online species records are served by the public iNaturalist API. Photo URLs
  and rights remain with their respective photographers; the app displays the
  attribution/license returned with each reference image.

## Data coverage and identification limits

The online explorer is an observation-based learning aid, not a complete
taxonomic census or verified range database. It only lists species represented
in iNaturalist observations in the selected geographic area and may contain
gaps, incomplete information, or community identification errors. The bundled
offline catalog is a curated starter set, not a downloaded catalogue of every
species in Jammu & Kashmir or India. Some range statements are broad and need
local verification; a country or region observation is not proof of native
range. Online reference photos initially require an internet connection. The Android
daily widget caches its current photo only when its license permits reuse;
otherwise, the widget keeps the photo online-only. Photos in the species
explorer are not bundled for offline reuse.

Offline natural-history entries are concise learning summaries. The reference
buttons on each entry search published literature and specialist databases by
scientific name; they are research starting points, not a bibliography proving
each individual statement. Conservation categories and local occurrence should
be checked against current specialist sources before being used for research.
The offline guide includes major taxonomic ranks through genus/species, while
the online lineage is matched live against GBIF. Taxonomic authorities may
disagree or revise accepted names. If a provider is unavailable, its section
shows a short retry message instead of a raw network exception; other species
information remains available.

Uploaded field photos are currently kept locally in the notebook. Automatic
species recognition is not enabled: a dependable plant-and-animal vision
provider and a secure service configuration are needed before photos can be
sent to an identification service. Do not put private API keys in a mobile or
web app bundle.

## Checks

```powershell
flutter analyze
flutter test
flutter build web
```
