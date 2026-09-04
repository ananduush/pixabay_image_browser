import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pixabay_image.dart';

/// "by {uploader} · {width} × {height}" with a small avatar. Pixabay has no
/// upload date, so the design's date slot carries the dimensions instead.
class ImageDetailCreator extends StatelessWidget {
  const ImageDetailCreator({super.key, required this.image});

  final PixabayImage image;

  static const double avatarSize = 24;

  static const String unknownUser = 'Unknown';

  static String metaLabel(PixabayImage image) {
    final user = image.user.trim().isEmpty ? unknownUser : image.user.trim();
    final hasSize = image.imageWidth > 0 && image.imageHeight > 0;
    final size = hasSize ? ' · ${image.imageWidth} × ${image.imageHeight}' : '';
    return 'by $user$size';
  }

  static String initialFor(String user) {
    final trimmed = user.trim();
    return trimmed.isEmpty ? '' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      children: <Widget>[
        _Avatar(image: image),
        Expanded(
          child: Text(
            metaLabel(image),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.detailMeta,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.image});

  final PixabayImage image;

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(
      initial: ImageDetailCreator.initialFor(image.user),
    );
    return SizedBox.square(
      dimension: ImageDetailCreator.avatarSize,
      child: ClipOval(
        child: image.userImageUrl.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: image.userImageUrl,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (BuildContext context, String url) => fallback,
                errorWidget: (BuildContext context, String url, Object e) =>
                    fallback,
              ),
      ),
    );
  }
}

/// Ink-fill disc with the uploader's initial, or a person glyph when the
/// name is empty too.
class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inkFill9,
      ),
      child: Center(
        child: initial.isEmpty
            ? const Icon(
                Icons.person_outline,
                size: 14,
                color: AppColors.text44,
              )
            : Text(initial, style: AppTypography.avatarInitial),
      ),
    );
  }
}
