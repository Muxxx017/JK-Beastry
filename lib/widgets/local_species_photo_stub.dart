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
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.image_not_supported_outlined));
}
