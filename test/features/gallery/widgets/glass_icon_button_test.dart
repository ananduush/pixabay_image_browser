import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/glass_icon_button.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('is a 44pt labelled button that reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassIconButton(
              icon: Icons.arrow_back_ios_new,
              label: GlassIconButton.backLabel,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(GlassIconButton)),
      const Size(GlassIconButton.size, GlassIconButton.size),
    );

    await tester.tap(find.bySemanticsLabel(GlassIconButton.backLabel));
    await tester.pump();

    expect(taps, 1);
  });
}
