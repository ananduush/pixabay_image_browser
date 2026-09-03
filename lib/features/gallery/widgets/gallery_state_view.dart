import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// glyph, title, body, then whatever the state offers
class GalleryStateView extends StatelessWidget {
  const GalleryStateView({
    super.key,
    required this.glyph,
    required this.title,
    required this.body,
    this.topPadding = 110,
    this.children = const <Widget>[],
  });

  final Widget glyph;
  final String title;
  final String body;
  final double topPadding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        topPadding,
        AppSpacing.xxl,
        0,
      ),
      child: Column(
        children: <Widget>[
          glyph,
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.stateTitle,
          ),
          const SizedBox(height: 9),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.stateBody,
          ),
          ...children,
        ],
      ),
    );
  }
}
