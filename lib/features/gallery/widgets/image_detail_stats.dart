import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/pixabay_image.dart';

/// Likes · Views · Downloads between two hairlines, as designed.
class ImageDetailStats extends StatelessWidget {
  const ImageDetailStats({super.key, required this.image});

  final PixabayImage image;

  static const String likesLabel = 'Likes';
  static const String viewsLabel = 'Views';
  static const String downloadsLabel = 'Downloads';

  /// Inset of the second and third cells, so the numbers clear the rule.
  static const double cellInset = 16;

  static final RegExp _thousands = RegExp(r'(\d)(?=(\d{3})+$)');

  /// `48210` → `48,210`. The design groups thousands rather than abbreviating.
  static String formatCount(int value) {
    final digits = value.abs().toString();
    final grouped = digits.replaceAllMapped(_thousands, (m) => '${m[1]},');
    return value < 0 ? '-$grouped' : grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.rule9),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: ImageDetailMetric(
                value: formatCount(image.likes),
                label: likesLabel,
              ),
            ),
            const _Rule(),
            Expanded(
              child: ImageDetailMetric(
                value: formatCount(image.views),
                label: viewsLabel,
                leftPadding: cellInset,
              ),
            ),
            const _Rule(),
            Expanded(
              child: ImageDetailMetric(
                value: formatCount(image.downloads),
                label: downloadsLabel,
                leftPadding: cellInset,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One metric cell: value in Newsreader over an uppercase label. The value
/// scales down rather than overflowing when the cell is narrow.
class ImageDetailMetric extends StatelessWidget {
  const ImageDetailMetric({
    super.key,
    required this.value,
    required this.label,
    this.leftPadding = 0,
  });

  final String value;
  final String label;
  final double leftPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        leftPadding,
        AppSpacing.md,
        0,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 3,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, softWrap: false, style: AppTypography.metric),
          ),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.metricLabel,
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 1, child: ColoredBox(color: AppColors.rule9));
  }
}
