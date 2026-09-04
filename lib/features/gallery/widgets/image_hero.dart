import 'package:flutter/material.dart';

import '../models/pixabay_image.dart';

/// Shared-element wrapper for one photograph. The tile, the Details hero and
/// the full-screen viewer all use the same tag, so the picture flies between
/// them. Flutter pairs heroes only across the top two routes, so the three
/// never collide; within one route a tag is unique because the feed is
/// de-duplicated by id. Never nest one [ImageHero] inside another.
class ImageHero extends StatelessWidget {
  const ImageHero({super.key, required this.image, required this.child});

  final PixabayImage image;
  final Widget child;

  static Object tagFor(PixabayImage image) => 'pixabay-image-${image.id}';

  /// In flight, show what the source route had already painted rather than
  /// the destination's not-yet-loaded image.
  static Widget flightShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final from = fromHeroContext.widget;
    return from is Hero ? from.child : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tagFor(image),
      flightShuttleBuilder: flightShuttle,
      child: child,
    );
  }
}
