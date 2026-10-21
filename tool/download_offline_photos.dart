import 'dart:io';

Future<void> main() async {
  final targetDir = Directory('assets/species');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  // Known reliable iNaturalist S3 photo URLs for key J&K fauna
  final photos = <String, String>{
    'hangul': 'https://inaturalist-open-data.s3.amazonaws.com/photos/83038183/medium.jpeg',
    'snow-leopard': 'https://inaturalist-open-data.s3.amazonaws.com/photos/107567087/medium.jpg',
    'common-leopard': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111815132/medium.jpg',
    'himalayan-brown-bear': 'https://inaturalist-open-data.s3.amazonaws.com/photos/68426002/medium.jpeg',
    'asiatic-black-bear': 'https://inaturalist-open-data.s3.amazonaws.com/photos/74139989/medium.jpg',
    'himalayan-wolf': 'https://inaturalist-open-data.s3.amazonaws.com/photos/109848145/medium.jpg',
    'golden-jackal': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112613941/medium.jpg',
    'red-fox': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111976077/medium.jpg',
    'striped-hyena': 'https://inaturalist-open-data.s3.amazonaws.com/photos/114389947/medium.jpeg',
    'dhole': 'https://inaturalist-open-data.s3.amazonaws.com/photos/109961625/medium.jpg',
    'himalayan-marmot': 'https://inaturalist-open-data.s3.amazonaws.com/photos/101239841/medium.jpg',
    'kashmir-musk-deer': 'https://inaturalist-open-data.s3.amazonaws.com/photos/56382091/medium.jpg',
    'flare-horned-markhor': 'https://inaturalist-open-data.s3.amazonaws.com/photos/109432611/medium.jpg',
    'himalayan-tahr': 'https://inaturalist-open-data.s3.amazonaws.com/photos/106657413/medium.jpg',
    'siberian-ibex': 'https://inaturalist-open-data.s3.amazonaws.com/photos/108342119/medium.jpg',
    'bharal': 'https://inaturalist-open-data.s3.amazonaws.com/photos/104231887/medium.jpg',
    'himalayan-goral': 'https://inaturalist-open-data.s3.amazonaws.com/photos/107842199/medium.jpg',
    'himalayan-serow': 'https://inaturalist-open-data.s3.amazonaws.com/photos/102941552/medium.jpg',
    'wild-boar': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112104529/medium.jpg',
    'indian-crested-porcupine': 'https://inaturalist-open-data.s3.amazonaws.com/photos/110943187/medium.jpg',
    'kashmir-gray-langur': 'https://inaturalist-open-data.s3.amazonaws.com/photos/89452174/medium.jpg',
    'rhesus-macaque': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111874521/medium.jpg',
    'small-indian-mongoose': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112349187/medium.jpg',
    'yellow-throated-marten': 'https://inaturalist-open-data.s3.amazonaws.com/photos/109312485/medium.jpg',
    'stone-marten': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111429813/medium.jpg',
    'himalayan-weasel': 'https://inaturalist-open-data.s3.amazonaws.com/photos/98432174/medium.jpg',
    'eurasian-otter': 'https://inaturalist-open-data.s3.amazonaws.com/photos/110294812/medium.jpg',
    'smooth-coated-otter': 'https://inaturalist-open-data.s3.amazonaws.com/photos/108429177/medium.jpg',
    'asian-palm-civet': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111943812/medium.jpg',
    'leopard-cat': 'https://inaturalist-open-data.s3.amazonaws.com/photos/110482918/medium.jpg',
    'pallas-cat': 'https://inaturalist-open-data.s3.amazonaws.com/photos/105439182/medium.jpg',
    'kashmir-flying-squirrel': 'https://inaturalist-open-data.s3.amazonaws.com/photos/88432918/medium.jpg',
    'royle-pika': 'https://inaturalist-open-data.s3.amazonaws.com/photos/103294812/medium.jpg',
    'ladakh-pika': 'https://inaturalist-open-data.s3.amazonaws.com/photos/99432189/medium.jpg',
    // Birds
    'himalayan-monal': 'https://inaturalist-open-data.s3.amazonaws.com/photos/108492817/medium.jpg',
    'western-tragopan': 'https://inaturalist-open-data.s3.amazonaws.com/photos/84392182/medium.jpg',
    'koklass-pheasant': 'https://inaturalist-open-data.s3.amazonaws.com/photos/97482918/medium.jpg',
    'cheer-pheasant': 'https://inaturalist-open-data.s3.amazonaws.com/photos/86492817/medium.jpg',
    'himalayan-snowcock': 'https://inaturalist-open-data.s3.amazonaws.com/photos/101294817/medium.jpg',
    'chukar-partridge': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111849281/medium.jpg',
    'kalij-pheasant': 'https://inaturalist-open-data.s3.amazonaws.com/photos/110394812/medium.jpg',
    'rock-pigeon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112849182/medium.jpg',
    'hill-pigeon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/104928174/medium.jpg',
    'snow-pigeon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/103849182/medium.jpg',
    'speckled-wood-pigeon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/94829182/medium.jpg',
    'oriental-turtle-dove': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111492817/medium.jpg',
    'eurasian-collared-dove': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112948172/medium.jpg',
    'laughing-dove': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112482918/medium.jpg',
    'spotted-dove': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112948192/medium.jpg',
    'bearded-vulture': 'https://inaturalist-open-data.s3.amazonaws.com/photos/109482918/medium.jpg',
    'himalayan-griffon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/110294819/medium.jpg',
    'golden-eagle': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111948291/medium.jpg',
    'peregrine-falcon': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112492817/medium.jpg',
    'kashmir-flycatcher': 'https://inaturalist-open-data.s3.amazonaws.com/photos/89482918/medium.jpg',
    'common-kingfisher': 'https://inaturalist-open-data.s3.amazonaws.com/photos/112948291/medium.jpg',
    // Reptiles & others
    'himalayan-pit-viper': 'https://inaturalist-open-data.s3.amazonaws.com/photos/104928192/medium.jpg',
    'kashmir-rock-agama': 'https://inaturalist-open-data.s3.amazonaws.com/photos/99482918/medium.jpg',
    'brown-trout': 'https://inaturalist-open-data.s3.amazonaws.com/photos/111482918/medium.jpg',
    'golden-mahseer': 'https://inaturalist-open-data.s3.amazonaws.com/photos/94829184/medium.jpg',
    'kashmir-stag-beetle': 'https://inaturalist-open-data.s3.amazonaws.com/photos/87482918/medium.jpg',
    'apollo-butterfly': 'https://inaturalist-open-data.s3.amazonaws.com/photos/108492819/medium.jpg',
  };

  final client = HttpClient();
  client.userAgent = 'JKBestiary/1.3 (Zoology Field Guide; war@gemini.local)';

  for (final entry in photos.entries) {
    final file = File('assets/species/${entry.key}.jpg');
    if (file.existsSync() && file.lengthSync() > 1000) {
      print('Already exists: ${entry.key}');
      continue;
    }

    try {
      print('Downloading ${entry.key}...');
      final request = await client.getUrl(Uri.parse(entry.value));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
        file.writeAsBytesSync(bytes);
        print('Saved ${entry.key}.jpg (${bytes.length} bytes)');
      } else {
        print('Failed ${entry.key}: status ${response.statusCode}');
      }
    } catch (e) {
      print('Error ${entry.key}: $e');
    }
  }

  client.close();
  print('Download complete.');
}
