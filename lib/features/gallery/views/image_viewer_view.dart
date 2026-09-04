import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../models/pixabay_image.dart';
import '../widgets/glass_icon_button.dart';
import '../widgets/image_detail_hero.dart';
import '../widgets/image_hero.dart';

/// Full-screen, uncropped view of the large image with pinch-to-zoom.
/// Double-tap zooms about the tapped point; a second double-tap resets.
class ImageViewerView extends StatefulWidget {
  const ImageViewerView({super.key, required this.image});

  final PixabayImage image;

  static const double minScale = 1;
  static const double maxScale = 4;
  static const double doubleTapScale = 2;

  static const double closeTopInset = 10;
  static const double closeLeftInset = 16;

  static const String failedHint = 'Close to return to the details';

  @override
  State<ImageViewerView> createState() => _ImageViewerViewState();
}

class _ImageViewerViewState extends State<ImageViewerView> {
  final TransformationController _transformation = TransformationController();

  Offset? _doubleTapAt;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapAt = details.localPosition;
  }

  void _toggleZoom() {
    final zoomed = _transformation.value.getMaxScaleOnAxis() > 1.01;
    final at = _doubleTapAt;
    if (zoomed || at == null) {
      _transformation.value = Matrix4.identity();
      return;
    }
    const scale = ImageViewerView.doubleTapScale;
    // scale about the tap point: move it to the origin, scale, move back
    _transformation.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final safeTop = MediaQuery.paddingOf(context).top;
    // light status bar glyphs over the ink backdrop
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                onDoubleTapDown: _onDoubleTapDown,
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  transformationController: _transformation,
                  minScale: ImageViewerView.minScale,
                  maxScale: ImageViewerView.maxScale,
                  clipBehavior: Clip.none,
                  child: Center(
                    // Sized to the photo's own ratio, so cover shows the whole
                    // image and the hero flight from the Details crop lands
                    // without a fit jump.
                    child: AspectRatio(
                      aspectRatio: image.aspectRatio,
                      child: ImageHero(
                        image: image,
                        child: CachedNetworkImage(
                          imageUrl: image.largeImageUrl,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 250),
                          placeholder: (BuildContext context, String url) =>
                              const ColoredBox(color: AppColors.skeleton),
                          errorWidget:
                              (BuildContext context, String url, Object e) =>
                                  const ImageDetailHeroFallback(
                                    hint: ImageViewerView.failedHint,
                                  ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: safeTop + ImageViewerView.closeTopInset,
              left: ImageViewerView.closeLeftInset,
              child: GlassIconButton(
                icon: Icons.close,
                iconSize: 18,
                label: GlassIconButton.closeLabel,
                onTap: Get.back<void>,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
