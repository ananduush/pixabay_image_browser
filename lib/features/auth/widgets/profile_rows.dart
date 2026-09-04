import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// One key/value line of the Profile list; hairline rules above the first
/// row and under every row.
class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTypography.rowKey),
          Text(value, style: AppTypography.rowValue),
        ],
      ),
    );
  }
}

/// The rule-topped list the rows sit in.
class ProfileRows extends StatelessWidget {
  const ProfileRows({super.key, required this.children});

  final List<ProfileRow> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.rule9)),
      ),
      child: Column(children: children),
    );
  }
}
