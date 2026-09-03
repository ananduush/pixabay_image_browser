import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Initial-loading placeholder: chip bars, a 4:3 hero block with caption
/// bars, three square tiles and another hero block, each pulsing between
/// 45% and 100% opacity on a 1.4s cycle with staggered phases.
class GallerySkeleton extends StatefulWidget {
  const GallerySkeleton({super.key});

  @override
  State<GallerySkeleton> createState() => _GallerySkeletonState();
}

class _GallerySkeletonState extends State<GallerySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            16,
            AppSpacing.gutter,
            0,
          ),
          child: Row(
            spacing: 9,
            children: <Widget>[
              _Block(pulse: _pulse, width: 78, height: 12),
              _Block(pulse: _pulse, phase: .1, width: 52, height: 12),
              _Block(pulse: _pulse, phase: .2, width: 64, height: 12),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.xl,
            AppSpacing.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.lg,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _Block(pulse: _pulse),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _StaticBar(width: 140, height: 11),
                      _StaticBar(width: 64, height: 11, faint: true),
                    ],
                  ),
                ],
              ),
              Row(
                spacing: AppSpacing.gridGap,
                children: <Widget>[
                  for (final phase in const <double>[.1, .2, .3])
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _Block(pulse: _pulse, phase: phase),
                      ),
                    ),
                ],
              ),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: _Block(pulse: _pulse, phase: .15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.pulse, this.phase = 0, this.width, this.height});

  final Animation<double> pulse;

  /// Fraction of the cycle this block lags behind (CSS animation-delay).
  final double phase;
  final double? width;
  final double? height;

  static const double _min = .45;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (BuildContext context, Widget? child) {
        final t = (pulse.value - phase) % 1;
        // 0% → .45, 50% → 1, 100% → .45 with an ease-in-out shape.
        final opacity = _min + (1 - _min) * (1 - math.cos(2 * math.pi * t)) / 2;
        return Opacity(opacity: opacity, child: child);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.inkFill7,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.image)),
          ),
        ),
      ),
    );
  }
}

class _StaticBar extends StatelessWidget {
  const _StaticBar({
    required this.width,
    required this.height,
    this.faint = false,
  });

  final double width;
  final double height;
  final bool faint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: faint ? AppColors.inkFill55 : AppColors.inkFill7,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.image),
          ),
        ),
      ),
    );
  }
}
