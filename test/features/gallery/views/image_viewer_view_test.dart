import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/models/pixabay_image.dart';
import 'package:pixabay_image_browser/features/gallery/views/image_viewer_view.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_icon_button.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_hero.dart';

import '../../../support/fake_image_cache.dart';
import '../../../support/pixabay_fixtures.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    Get.testMode = true;
    installPendingImageCache();
  });

  tearDown(Get.reset);

  Future<void> pumpViewer(WidgetTester tester, PixabayImage image) async {
    await tester.pumpWidget(
      GetMaterialApp(home: ImageViewerView(image: image)),
    );
    await tester.pump();
  }

  double currentScale(WidgetTester tester) {
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    return viewer.transformationController?.value.getMaxScaleOnAxis() ?? 0;
  }

  Future<void> doubleTap(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(center);
    await tester.pump();
  }

  testWidgets('shows the large image at its own aspect ratio', (tester) async {
    final image = PixabayImage.fromJson(sampleHit());

    await pumpViewer(tester, image);

    final networkImage = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(networkImage.imageUrl, image.largeImageUrl);
    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width / size.height, closeTo(image.aspectRatio, 0.01));
    expect(find.bySemanticsLabel(GlassIconButton.closeLabel), findsOneWidget);
  });

  testWidgets('double tap zooms to 2× and a second double tap resets', (
    tester,
  ) async {
    await pumpViewer(tester, PixabayImage.fromJson(sampleHit()));
    expect(currentScale(tester), closeTo(1, 0.001));

    await doubleTap(tester);
    expect(
      currentScale(tester),
      closeTo(ImageViewerView.doubleTapScale, 0.001),
    );

    await doubleTap(tester);
    expect(currentScale(tester), closeTo(1, 0.001));
    // let the double-tap recogniser's timeout expire before teardown
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('a failed image shows the fallback with the viewer hint', (
    tester,
  ) async {
    installFailingImageCache();
    final image = PixabayImage.fromJson(<String, dynamic>{
      ...sampleHit(),
      'largeImageURL': 'https://example.test/viewer-broken_1280.jpg',
    });

    await pumpViewer(tester, image);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(ImageDetailHeroFallback.failedTitle), findsOneWidget);
    expect(find.text(ImageViewerView.failedHint), findsOneWidget);
  });
}
