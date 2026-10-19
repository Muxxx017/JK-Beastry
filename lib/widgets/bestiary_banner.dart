import 'package:flutter/material.dart';
import 'package:zoology_app/theme/bestiary_theme.dart';
import 'package:zoology_app/widgets/bestiary_mark.dart';
import 'package:zoology_app/widgets/field_landscape.dart';

class BestiaryBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final double height;

  const BestiaryBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.height = 184,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const FieldLandscape(),
            Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: .42,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: BestiaryMark(size: height * .46),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: const Color(0xFFE8DFC8)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(color: BestiaryPalette.page, fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFFE5E6DA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
