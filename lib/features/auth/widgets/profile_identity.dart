import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/auth_user.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.user});

  final AuthUser user;

  static const double avatarSize = 56;

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String joinedLabel(DateTime date) {
    final local = date.toLocal();
    return 'Joined ${_months[local.month - 1]} ${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = user.createdAt;
    return Row(
      spacing: AppSpacing.md,
      children: <Widget>[
        SizedBox.square(
          dimension: avatarSize,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.inkFill8,
            ),
            child: Center(
              child: user.initial.isEmpty
                  ? const Icon(
                      Icons.person_outline,
                      size: 22,
                      color: AppColors.text44,
                    )
                  : Text(user.initial, style: AppTypography.avatarInitialLarge),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                user.email,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.profileName,
              ),
              if (createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    joinedLabel(createdAt),
                    style: AppTypography.profileMeta,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
