import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The design's toast: a compact ink capsule that rises in above the
/// floating bar, waits, and fades out. One at a time — a new message
/// replaces whatever is showing.
///
/// Callers capture the [OverlayState] *before* awaiting whatever they will
/// report on, so a route popped during the await cannot leave them with a
/// dead context.
abstract final class AppToast {
  static const Duration duration = Duration(milliseconds: 2600);
  static const Duration motion = Duration(milliseconds: 220);

  /// Gap between the toast and the floating bar it must clear.
  static const double barGap = 12;

  static OverlayEntry? _entry;

  static void show(
    OverlayState overlay,
    String message, {
    required double bottomOffset,
  }) {
    _entry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => _ToastPill(
        message: message,
        bottomOffset: bottomOffset,
        onDone: () => _remove(entry),
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (_entry != entry) return;
    _entry = null;
    entry.remove();
  }
}

class _ToastPill extends StatefulWidget {
  const _ToastPill({
    required this.message,
    required this.bottomOffset,
    required this.onDone,
  });

  final String message;
  final double bottomOffset;
  final VoidCallback onDone;

  @override
  State<_ToastPill> createState() => _ToastPillState();
}

class _ToastPillState extends State<_ToastPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: AppToast.motion,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _motion,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _rise = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic));

  // Owned by the widget so it dies with the overlay, never dangling.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _motion.forward();
    _timer = Timer(AppToast.duration, _hide);
  }

  Future<void> _hide() async {
    await _motion.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.bottomOffset,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _rise,
              child: Material(
                type: MaterialType.transparency,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.inkButton,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.buttonBorder),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.buttonShadow,
                        offset: Offset(0, 10),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: AppTypography.toast,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
