import 'dart:io';

import 'package:flutter/material.dart';

class LocalSpeciesPhoto extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const LocalSpeciesPhoto({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) => Image.file(
    File(path),
    fit: fit,
    errorBuilder: (context, error, stackTrace) =>
        const Center(child: Icon(Icons.broken_image_outlined)),
  );
}
