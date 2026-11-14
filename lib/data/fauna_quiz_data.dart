import 'dart:math';
import '../models/fauna_quiz_question.dart';

/// Comprehensive bank of verified Jammu & Kashmir regional fauna quiz questions.
/// Strictly 0 flora/plant entries; covers all 6 taxonomic classes (Mammals, Birds,
/// Reptiles, Amphibians, Fish, Insects).
const List<FaunaQuizQuestion> kFaunaQuizQuestions = [
  // ---------------------------------------------------------------------------
  // Foundational Questions (Indices 0–4: Preserving existing test compatibility)
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-mammal-hangul-01',
    prompt:
        'Which critically endangered deer is endemic to Kashmir and famous for its autumn mating bugle in Dachigam?',
    options: [
      'Kashmir Musk Deer',
      'Kashmir Stag (Hangul)',
      'Himalayan Serow',
      'Siberian Ibex',
    ],
    correctIndex: 1,
    explanation:
        'The Hangul (Cervus hanglu hanglu) is the state animal of Jammu & Kashmir and finds its last stronghold in Dachigam National Park.',
    speciesId: 'hangul',
    category: 'Mammal',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-snow-leopard-01',
    prompt:
        'Known as the "Ghost of the Mountains", this solitary apex predator roams the high snowfields of Ladakh and Kishtwar:',
    options: [
      'Himalayan Brown Bear',
      'Tibetan Wolf',
      'Snow Leopard',
      'Common Leopard',
    ],
    correctIndex: 2,
    explanation:
        'The Snow Leopard (Panthera uncia) uses its extraordinarily thick fur and long counterbalancing tail to hunt across precipitous screes.',
    speciesId: 'snow-leopard',
    category: 'Mammal',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-monal-01',
    prompt:
        'Which iridescent high-altitude pheasant is renowned for digging alpine bulbs and its ringing curlew-like whistles?',
    options: [
      'Western Tragopan',
      'Koklass Pheasant',
      'Kalij Pheasant',
      'Himalayan Monal',
    ],
    correctIndex: 3,
    explanation:
        'The Himalayan Monal (Lophophorus impejanus) exhibits rainbow plumage in males and loud whistling calls heard across subalpine slopes.',
    speciesId: 'monal',
    category: 'Bird',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-marmot-01',
    prompt:
        'Which animal produces high-pitched sentry alarm whistles from high-altitude talus slopes to warn its colony of raptors?',
    options: [
      'Himalayan Marmot',
      "Royle's Pika",
      'Ladakh Urial',
      'Indian Crested Porcupine',
    ],
    correctIndex: 0,
    explanation:
        'The Himalayan Marmot (Marmota himalayana) lives in extensive communal burrow networks across alpine meadows and warns colony members with loud whistles.',
    speciesId: 'himalayan-marmot',
    category: 'Mammal',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-fish-kashmir-snow-trout-01',
    prompt:
        'Known locally as "Khont", this indigenous river fish is a keystone coldwater swimmer of the Jhelum river basin:',
    options: [
      'Golden Mahseer',
      'Kashmiri Snow Trout',
      'Brown Trout',
      'Common Carp',
    ],
    correctIndex: 1,
    explanation:
        'The Kashmiri Snow Trout (Schizothorax esocinus) is a native cyprinid adapted to fast-flowing, cold snowmelt Himalayan rivers.',
    speciesId: 'kashmir-snow-trout',
    category: 'Fish',
    region: 'Kashmir',
  ),

  // ---------------------------------------------------------------------------
  // Additional Mammals
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-mammal-markhor-01',
    prompt:
        "Which magnificent wild goat of the Pir Panjal and Kazinag ranges possesses massive corkscrew-shaped horns and a name translating from Persian as 'snake eater'?",
    options: [
      'Himalayan Ibex',
      'Bharal (Blue Sheep)',
      'Markhor (Pir Panjal Markhor)',
      'Himalayan Tahr',
    ],
    correctIndex: 2,
    explanation:
        'The Markhor (Capra falconeri cashmiriensis) is adapted to sheer rocky cliffs; Persian folklore claims it kills and consumes venomous snakes (Mar = snake, Khor = eater).',
    speciesId: 'markhor',
    category: 'Mammal',
    region: 'Pir Panjal',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-tibetan-antelope-01',
    prompt:
        "Which high-altitude ungulate of northern Ladakh was historically decimated by poachers for its ultra-fine underwool known as 'Shahtoosh'?",
    options: [
      'Tibetan Gazelle (Goa)',
      'Tibetan Antelope (Chiru)',
      'Ladakh Urial',
      'Tibetan Argali',
    ],
    correctIndex: 1,
    explanation:
        'The Chiru (Pantholops hodgsonii) grows Shahtoosh underwool so exquisitely fine that a large shawl can pass through a finger ring, requiring 3 to 5 wild antelopes to be killed per shawl.',
    speciesId: 'tibetan-antelope',
    category: 'Mammal',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-pallas-cat-01',
    prompt:
        'Which stocky trans-Himalayan feline of eastern Ladakh has the densest fur of any wild cat in the world, round pupils, and low-set ears for peering over rocks?',
    options: [
      'Leopard Cat',
      'Jungle Cat',
      'Eurasian Lynx',
      "Pallas's Cat (Manul)",
    ],
    correctIndex: 3,
    explanation:
        "Pallas's Cat (Otocolobus manul) inhabits high cold-desert plateaus in Hanle and Changthang, surviving temperatures plunging to -50°C thanks to its extraordinarily dense silvery coat.",
    speciesId: 'pallas-cat',
    category: 'Mammal',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-brown-bear-01',
    prompt:
        'Which massive omnivore spends up to seven months in winter hibernation beneath high alpine snowpack in Drass, Suru, and Gurez valleys?',
    options: [
      'Asian Black Bear',
      'Himalayan Brown Bear',
      'Tibetan Wolf',
      'Striped Hyena',
    ],
    correctIndex: 1,
    explanation:
        'The Himalayan Brown Bear (Ursus arctos isabellinus), known locally as Drenmo or Lal Bhalu, hibernates from late autumn through spring in excavated high-altitude dens.',
    speciesId: 'himalayan-brown-bear',
    category: 'Mammal',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-mammal-ladakh-urial-01',
    prompt:
        "Known locally as the 'Shapu', this endemic wild sheep with backward-curving sickle horns is restricted to the arid open river valleys of Ladakh:",
    options: [
      'Ladakh Urial (Shapu)',
      'Tibetan Argali (Nyan)',
      'Bharal (Blue Sheep)',
      'Siberian Ibex',
    ],
    correctIndex: 0,
    explanation:
        'The Ladakh Urial (Ovis vignei vignei) inhabits gently sloping alluvial fans and arid valleys along the Indus and Shyok rivers, at lower elevations than the Argali.',
    speciesId: 'ladakh-urial',
    category: 'Mammal',
    region: 'Ladakh',
  ),

  // ---------------------------------------------------------------------------
  // Birds
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-bird-western-tragopan-01',
    prompt:
        "Known as the 'Jujurana' (King of Birds), which rare horned pheasant inflates bright sky-blue horns and an extravagant throat lappet during courtship in Kazinag?",
    options: [
      'Koklass Pheasant',
      'Cheer Pheasant',
      'Western Tragopan',
      'Kalij Pheasant',
    ],
    correctIndex: 2,
    explanation:
        'The Western Tragopan (Tragopan melanocephalus) is a globally vulnerable pheasant surviving in undisturbed temperate montane forests of Kazinag and Limber.',
    speciesId: 'western-tragopan',
    category: 'Bird',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-black-necked-crane-01',
    prompt:
        'Which stately bird is the State Bird of Ladakh and breeds exclusively on high-altitude wetlands like Tso Kar and Tso Moriri in the Indian subcontinent?',
    options: [
      'Bar-headed Goose',
      'Black-necked Crane',
      'Ruddy Shelduck',
      'Great Crested Grebe',
    ],
    correctIndex: 1,
    explanation:
        'The Black-necked Crane (Grus nigricollis) is deeply revered in Tibetan Buddhism and spends summer nesting in alpine marshes across Changthang, eastern Ladakh.',
    speciesId: 'black-necked-crane',
    category: 'Bird',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-lammergeier-01',
    prompt:
        'Which colossal mountain raptor is an obligate osteophage, obtaining over 85% of its diet from large bones that it shatters by dropping them onto rocky ossuaries?',
    options: [
      'Himalayan Griffon Vulture',
      'Golden Eagle',
      'Bearded Vulture (Lammergeier)',
      'Steppe Eagle',
    ],
    correctIndex: 2,
    explanation:
        'The Bearded Vulture (Gypaetus barbatus) drops bones from heights of 50–100 meters onto flat stone slabs to access nutritious bone marrow, digesting fragments with stomach acid of pH ~1.',
    speciesId: 'lammergeier',
    category: 'Bird',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-kashmir-flycatcher-01',
    prompt:
        'Which small passerine bird with a rufous-orange breast is a near-threatened breeding endemic restricted to the temperate deciduous forests of Kashmir?',
    options: [
      'Kashmir Flycatcher',
      'White-capped Redstart',
      'Blue Whistling Thrush',
      'Kashmir Nuthatch',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Flycatcher (Ficedula subrubra) breeds exclusively in mixed deciduous forests of Kashmir (Overa-Aru, Dachigam) before migrating southward.',
    speciesId: 'kashmir-flycatcher',
    category: 'Bird',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-bar-headed-goose-01',
    prompt:
        'Which extraordinary waterfowl migrates over the highest summits of the Himalaya, utilizing specialized oxygen-binding hemoglobin to fly above 7,000 meters?',
    options: [
      'Mallard',
      'Northern Pintail',
      'Bar-headed Goose',
      'Ruddy Shelduck',
    ],
    correctIndex: 2,
    explanation:
        "The Bar-headed Goose (Anser indicus) nests around Ladakh's high lakes (Tso Moriri) and performs trans-Himalayan migrations directly across extreme altitudes without relying on tailwinds.",
    speciesId: 'bar-headed-goose',
    category: 'Bird',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-wallcreeper-01',
    prompt:
        'Which ash-grey bird scales sheer vertical limestone precipices using oversized curved claws, repeatedly flicking open wings that reveal striking crimson-red patches?',
    options: [
      'Wallcreeper',
      'Alpine Chough',
      'Red-billed Chough',
      'Kashmir Nuthatch',
    ],
    correctIndex: 0,
    explanation:
        'The Wallcreeper (Tichodroma muraria) probes narrow rock fissures on vertical mountain cliffs with its slender down-curved needle bill, displaying bright crimson-and-white wing markings.',
    speciesId: 'wallcreeper',
    category: 'Bird',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-bird-golden-eagle-01',
    prompt:
        'Which formidable trans-Himalayan apex raptor with a 2-meter wingspan patrols high Ladakh ridges, hunting marmots, hares, and young wild ungulates?',
    options: [
      'Golden Eagle',
      'Peregrine Falcon',
      'Common Kestrel',
      'Eurasian Eagle-Owl',
    ],
    correctIndex: 0,
    explanation:
        'The Golden Eagle (Aquila chrysaetos daphanea) rules the high skies of Ladakh and Pir Panjal, capable of diving at speeds exceeding 240 km/h to strike prey on alpine turf.',
    speciesId: 'golden-eagle',
    category: 'Bird',
    region: 'Ladakh',
  ),

  // ---------------------------------------------------------------------------
  // Reptiles
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-reptile-rock-agama-01',
    prompt:
        'During the summer breeding season, dominant males of which native Himalayan lizard develop brilliant electric cobalt-blue throat and chest coloration while performing head-bob push-ups?',
    options: [
      'Kashmiri Rock Agama',
      'Ladakh Toad-headed Agama',
      'Himalayan Glacier Skink',
      "Stoliczka's Gecko",
    ],
    correctIndex: 0,
    explanation:
        'The Kashmiri Rock Agama (Laudakia tuberculata) basks on roadside cliffs and boulders, with territorial males displaying vivid blue nuptial colors and vigorous push-up rituals.',
    speciesId: 'kashmiri-rock-agama',
    category: 'Reptile',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-reptile-levantine-viper-01',
    prompt:
        "Known locally in Kashmir as the 'Khor Gunas', which heavy-bodied serpent is the valley's largest venomous viper, inhabiting dry rocky hillsides with a blunt triangular snout?",
    options: [
      'Himalayan Pit Viper',
      'Levantine Viper (Blunt-nosed Viper)',
      'Common Krait',
      'Spectacled Cobra',
    ],
    correctIndex: 1,
    explanation:
        'The Levantine Viper (Macrovipera lebetina) delivers potent cytotoxic venom and strikes with lightning speed from rocky hideaways in dry Kashmir ravines.',
    speciesId: 'levantine-viper',
    category: 'Reptile',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-reptile-pit-viper-01',
    prompt:
        'Which venomous serpent holds the altitude record for snakes in the Indian subcontinent, surviving at elevations up to 3,800 meters using specialized heat-sensing pits?',
    options: [
      'Common Wolf Snake',
      'Himalayan Keelback',
      'Himalayan Pit Viper',
      "Russell's Viper",
    ],
    correctIndex: 2,
    explanation:
        'The Himalayan Pit Viper (Gloydius himalayanus) thrives on subalpine screes and rocky margins, using loreal thermal pits between nostril and eye to detect warm-blooded rodents in darkness.',
    speciesId: 'himalayan-pit-viper',
    category: 'Reptile',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-reptile-russell-viper-01',
    prompt:
        "When alarmed, which venomous snake of Jammu's dry scrub and agricultural plains coils tightly and produces a warning hiss as loud as a high-pressure steam cooker?",
    options: [
      'Spectacled Cobra',
      "Russell's Viper",
      'Common Krait',
      'Checkered Keelback',
    ],
    correctIndex: 1,
    explanation:
        "Russell's Viper (Daboia russelii) produces the loudest warning hiss of any snake species on earth and possesses chain-like dorsal blotches with potent hemotoxic venom.",
    speciesId: 'russell-viper',
    category: 'Reptile',
    region: 'Jammu',
  ),
  FaunaQuizQuestion(
    id: 'q-reptile-toad-headed-agama-01',
    prompt:
        "Which cold-desert reptile of Ladakh's sand dunes rapidly vibrates its body sideways to bury into loose sand and possesses closable nasal valves to seal out dust storms?",
    options: [
      'Ladakh Toad-headed Agama',
      'Cliff Racer',
      'Kashmiri Rock Agama',
      'Himalayan Glacier Skink',
    ],
    correctIndex: 0,
    explanation:
        'The Ladakh Toad-headed Agama (Phrynocephalus theobaldi) survives extreme cold desert conditions in Nubra and Changthang at elevations up to 4,800 meters.',
    speciesId: 'ladakh-toad-headed-agama',
    category: 'Reptile',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-reptile-cliff-racer-01',
    prompt:
        'Which slender, non-venomous colubrid snake is highly adapted to rocky gorges and steep talus slopes across Ladakh and the northern mountain borders?',
    options: [
      'Cliff Racer (Ladakh Racer)',
      'Common Rat Snake',
      'Checkered Keelback',
      'Common Wolf Snake',
    ],
    correctIndex: 0,
    explanation:
        'The Cliff Racer (Platyceps ladacensis) is an agile diurnal hunter preying on agamas, skinks, and small rodents along dry rocky river valleys.',
    speciesId: 'cliff-racer',
    category: 'Reptile',
    region: 'Ladakh',
  ),

  // ---------------------------------------------------------------------------
  // Amphibians
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-amphibian-kashmir-paa-frog-01',
    prompt:
        'Which endangered, torrent-adapted frog clings to algae-slick boulders in rushing mountain cascades using heavily muscular limbs and fully webbed feet?',
    options: [
      'Hazara Torrent Frog (Kashmir Paa Frog)',
      'Indus Valley Bullfrog',
      'Skittering Frog',
      'Kashmir Cricket Frog',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Paa Frog (Allopaa hazarensis) is a rheophilic dicroglossid whose breeding males develop spiny chest nuptial pads to hold mates in thundering torrents.',
    speciesId: 'kashmir-paa-frog',
    category: 'Amphibian',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-amphibian-ladakh-toad-01',
    prompt:
        "Which high-altitude toad survives intense ultraviolet radiation, freezing night winds, and arid valleys as the primary native amphibian across Ladakh's cold desert?",
    options: [
      'Ladakh Toad (Baltistan Toad)',
      'Common Asian Toad',
      'Marbled Burrowing Frog',
      'Murree Hills Frog',
    ],
    correctIndex: 0,
    explanation:
        'The Ladakh Toad (Bufotes latastii) breeds in shallow sun-warmed glacial snowmelt pools at 2,600–3,800 meters and emits a high-pitched, cricket-like musical trill.',
    speciesId: 'ladakh-toad',
    category: 'Amphibian',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-amphibian-skardu-toad-01',
    prompt:
        'Which trans-Himalayan green toad hibernates for seven months of the year under permafrost boulders, displaying bright emerald marbling on an ivory dorsum?',
    options: [
      'Himalayan Toad',
      'Skardu Toad (Green Toad)',
      'Hazara Torrent Frog',
      'Black-spined Toad',
    ],
    correctIndex: 1,
    explanation:
        'The Skardu Toad (Bufotes pseudoraddei) emerges during the brief high-elevation summer (June–July) to feed on mountain insects and lay egg strings in glacial trickles.',
    speciesId: 'skardu-toad',
    category: 'Amphibian',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-amphibian-himalayan-toad-01',
    prompt:
        'Which robust, warty amphibian with prominent parotoid glands behind its eyes is commonly encountered in temperate montane habitats and subalpine meadows of Kashmir and Jammu?',
    options: [
      'Himalayan Toad',
      'Indus Valley Bullfrog',
      'Skittering Frog',
      'Marbled Burrowing Frog',
    ],
    correctIndex: 0,
    explanation:
        'The Himalayan Toad (Duttaphrynus himalayanus) is widely distributed from 1,200 to 3,600 meters, feeding on forest-floor invertebrates and breeding in mountain ponds.',
    speciesId: 'himalayan-toad',
    category: 'Amphibian',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-amphibian-cricket-frog-01',
    prompt:
        'Which small terrestrial frog produces repetitive clicking vocalizations across wetland fringes, rice paddies, and moist meadows of the Kashmir Valley?',
    options: [
      'Kashmir Cricket Frog',
      'Hazara Torrent Frog',
      'Skardu Toad',
      'Murree Hills Frog',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Cricket Frog (Minervarya kashmiriensis) is an endemic wetland dicroglossid that thrives in agricultural terraces and marsh edges around Srinagar and Baramulla.',
    speciesId: 'kashmir-cricket-frog',
    category: 'Amphibian',
    region: 'Kashmir',
  ),

  // ---------------------------------------------------------------------------
  // Fish
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-fish-sattar-snow-trout-01',
    prompt:
        "Known as 'Sattar Gaad', which endemic herbivorous fish of Kashmir Valley lakes possesses a blunt snout adapted for scraping algae and is harvested with traditional cast nets?",
    options: [
      'Rainbow Trout',
      'Sattar Snow Trout (Sattar Gaad)',
      'Kashmir Torrent Catfish',
      'Common Carp',
    ],
    correctIndex: 1,
    explanation:
        'The Sattar Snow Trout (Schizothorax curvifrons) is indigenous to Dal Lake and the Jhelum basin, serving a vital ecological role by regulating lake algae and periphyton.',
    speciesId: 'sattar-snow-trout',
    category: 'Fish',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-fish-golden-mahseer-01',
    prompt:
        "Renowned as the 'King of Himalayan Rivers', which legendary game fish with enormous golden scales and powerful fins inhabits the rocky foothill rivers of Jammu?",
    options: [
      'Kashmiri Snow Trout',
      'Brown Trout',
      'Golden Mahseer',
      'Kashmir Loach',
    ],
    correctIndex: 2,
    explanation:
        'The Golden Mahseer (Tor putitora) is an endangered apex cyprinid inhabiting turbulent, highly oxygenated waters of the Chenab, Tawi, and Poonch river drainages.',
    speciesId: 'golden-mahseer',
    category: 'Fish',
    region: 'Jammu',
  ),
  FaunaQuizQuestion(
    id: 'q-fish-torrent-catfish-01',
    prompt:
        'Which critically endangered endemic fish clings securely to smooth river stones in thundering mountain rapids using a corrugated thoracic adhesive sucker on its chest?',
    options: [
      'Kashmir Torrent Catfish',
      'Kashmir Stone Loach',
      'Sattar Snow Trout',
      'Common Snow Trout',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Torrent Catfish (Glyptothorax kashmirensis) possesses a specialized ridged thoracic sucker generating negative water pressure to prevent dislodgement in torrential rivers.',
    speciesId: 'kashmir-torrent-catfish',
    category: 'Fish',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-fish-stone-loach-01',
    prompt:
        'Which slender, bottom-dwelling fish with subterminal barbels lives among stones in high-velocity glacial snowmelt streams of Kashmir up to 3,000 meters?',
    options: [
      'Kashmir Loach (Stone Loach)',
      'Golden Mahseer',
      'Rainbow Trout',
      'Brown Trout',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Stone Loach (Triplophysa kashmirensis) is a specialized nemacheilid benthic feeder adapted to scouring macroinvertebrates from high-elevation glacial waters.',
    speciesId: 'kashmir-stone-loach',
    category: 'Fish',
    region: 'Kashmir',
  ),

  // ---------------------------------------------------------------------------
  // Insects
  // ---------------------------------------------------------------------------
  FaunaQuizQuestion(
    id: 'q-insect-noble-apollo-01',
    prompt:
        'Which majestic high-altitude butterfly survives freezing alpine moraines up to 5,000 meters by producing biological antifreeze glycoproteins in its blood?',
    options: [
      'Common Peacock Butterfly',
      "Noble Apollo (Charlton's Apollo)",
      'Large Cabbage White',
      'Indian Tortoiseshell',
    ],
    correctIndex: 1,
    explanation:
        'The Noble Apollo (Parnassius charltonius) has translucent creamy parchment wings with prominent crimson ocelli, flying across high scree slopes and passes of Ladakh and Kashmir.',
    speciesId: 'noble-apollo',
    category: 'Insect',
    region: 'Ladakh',
  ),
  FaunaQuizQuestion(
    id: 'q-insect-blue-emperor-01',
    prompt:
        'Which colossal dragonfly patrols lake margins at speeds over 30 km/h, rarely perching during the day and even devouring its captured insect prey while in mid-air?',
    options: [
      'Four-spotted Chaser',
      'Blue Emperor (Emperor Dragonfly)',
      'Seven-Spot Ladybird',
      'Asian Giant Hornet',
    ],
    correctIndex: 1,
    explanation:
        'The Blue Emperor (Anax imperator) is Kashmir\'s largest dragonfly, with males boasting an apple-green thorax and sky-blue abdomen as top aerial invertebrate predators.',
    speciesId: 'blue-emperor-dragonfly',
    category: 'Insect',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-insect-ladybird-01',
    prompt:
        "Which iconic spotted beetle serves as an essential biological pest control agent across Kashmir's valleys and agricultural orchards by devouring destructive aphid colonies?",
    options: [
      'Seven-Spot Ladybird',
      'Kashmir Stag Beetle',
      'Himalayan Rock Scorpion',
      'Asian Giant Hornet',
    ],
    correctIndex: 0,
    explanation:
        'The Seven-Spot Ladybird (Coccinella septempunctata) can consume thousands of sap-sucking aphids during its lifecycle, protecting agricultural ecosystems across Jammu & Kashmir.',
    speciesId: 'ladybird',
    category: 'Insect',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-insect-bumblebee-01',
    prompt:
        'Which densely furred insect is the primary cold-tolerant pollinator of high alpine vegetation up to 4,500 meters in Kashmir and Ladakh?',
    options: [
      'Himalayan High-Altitude Bumblebee',
      'Kashmir Apollo Butterfly',
      'Kashmir Swallowtail',
      'Blue Emperor Dragonfly',
    ],
    correctIndex: 0,
    explanation:
        'The Himalayan Bumblebee (Bombus tunicatus) uses shivering thermogenesis to generate thoracic body heat, allowing it to fly in near-freezing mountain winds to pollinate alpine vegetation.',
    speciesId: 'himalayan-bumblebee',
    category: 'Insect',
    region: 'Kashmir',
  ),
  FaunaQuizQuestion(
    id: 'q-insect-stag-beetle-01',
    prompt:
        'Which formidable beetle of old-growth temperate montane hardwood forests features colossal antler-like mandibles used by males to wrestle rivals for nutrient-rich sap?',
    options: [
      'Kashmir Stag Beetle',
      'Seven-Spot Ladybird',
      'Four-spotted Chaser',
      'Noble Apollo',
    ],
    correctIndex: 0,
    explanation:
        'The Kashmir Stag Beetle (Lucanus westermanni) is an indicator of mature forest ecosystems, where its larvae develop inside decaying hardwood timber over multiple years.',
    speciesId: 'kashmir-stag-beetle',
    category: 'Insect',
    region: 'Kashmir',
  ),
];

/// Alias for backwards compatibility if needed
const List<FaunaQuizQuestion> kDefaultFaunaQuizQuestions = kFaunaQuizQuestions;

/// Prepares fauna quiz questions with optional shuffling or seeded randomizer.
List<FaunaQuizQuestion> prepareQuizQuestions({
  bool shuffle = false,
  int? seed,
  List<FaunaQuizQuestion>? source,
}) {
  final list = List<FaunaQuizQuestion>.from(source ?? kFaunaQuizQuestions);
  if (shuffle) {
    if (seed != null) {
      list.shuffle(Random(seed));
    } else {
      list.shuffle();
    }
  }
  return list;
}
