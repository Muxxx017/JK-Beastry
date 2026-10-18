import 'package:flutter/material.dart';

class ZoomablePhoto extends StatelessWidget {
  final String url;
  final String? attribution;
  final String? license;
  final double? width;
  final double height;
  final BoxFit fit;

  const ZoomablePhoto({
    super.key,
    required this.url,
    required this.height,
    this.attribution,
    this.license,
    this.width,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) =>
            _PhotoViewer(url: url, attribution: attribution, license: license),
      ),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => SizedBox(
          width: width,
          height: height,
          child: const Center(child: Icon(Icons.broken_image_outlined)),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String url;
  final String? attribution;
  final String? license;

  const _PhotoViewer({
    required this.url,
    required this.attribution,
    required this.license,
  });

  @override
  Widget build(BuildContext context) {
    final credit = [
      if (attribution != null && attribution!.trim().isNotEmpty) attribution!,
      if (license != null && license!.trim().isNotEmpty) 'License: $license',
    ].join(' · ');

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Photo'),
          actions: [
            IconButton(
              tooltip: 'Close photo',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                minScale: 0.75,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            if (credit.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    credit,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
