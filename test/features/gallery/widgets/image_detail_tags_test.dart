import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/image_detail_tags.dart';

void main() {
  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders one chip per tag and reports taps', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageDetailTags(
            tags: const <String>['forest', 'fog', 'mountains'],
            onTagTap: tapped.add,
          ),
        ),
      ),
    );

    expect(find.text('forest'), findsOneWidget);
    expect(find.text('fog'), findsOneWidget);
    expect(find.text('mountains'), findsOneWidget);

    await tester.tap(find.text('fog'));
    await tester.pump();

    expect(tapped, <String>['fog']);
  });

  test('uniqueTags drops repeats case-insensitively, keeping order', () {
    expect(
      ImageDetailTags.uniqueTags(<String>[
        'woman',
        'portrait',
        'Woman',
        'woman',
        'face',
      ]),
      <String>['woman', 'portrait', 'face'],
    );
  });

  testWidgets('repeated tags render one chip each', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImageDetailTags(tags: <String>['woman', 'woman', 'face']),
        ),
      ),
    );

    expect(find.byType(InkWell), findsNWidgets(2));
    expect(find.text('woman'), findsOneWidget);
  });

  testWidgets('renders nothing for an empty tag list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ImageDetailTags(tags: <String>[])),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('many long tags wrap without overflowing a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final tags = <String>[
      for (var i = 0; i < 30; i++) 'an unusually long tag number $i',
      'supercalifragilisticexpialidocious_and_then_some_more_characters',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ImageDetailTags(tags: tags)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(InkWell), findsNWidgets(tags.length));
  });
}
