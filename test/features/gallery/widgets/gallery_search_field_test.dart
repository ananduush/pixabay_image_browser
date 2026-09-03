import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixabay_image_browser/features/gallery/widgets/gallery_search_field.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;
  late List<String> changes;
  late List<String> submissions;
  late int clears;
  late int cancels;

  setUpAll(() {
    // Fonts fall back to the test environment's defaults; no network.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
    changes = <String>[];
    submissions = <String>[];
    clears = 0;
    cancels = 0;
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pumpField(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GallerySearchField(
            controller: controller,
            focusNode: focusNode,
            onChanged: changes.add,
            onSubmitted: submissions.add,
            onClear: () => clears++,
            onCancel: () {
              cancels++;
              focusNode.unfocus();
            },
          ),
        ),
      ),
    );
  }

  Finder clearPill() => find.bySemanticsLabel(GallerySearchField.clearLabel);
  Finder cancel() => find.text(GallerySearchField.cancelLabel);

  testWidgets('shows the placeholder and no controls when idle', (
    tester,
  ) async {
    await pumpField(tester);

    expect(find.text(GallerySearchField.placeholder), findsOneWidget);
    expect(clearPill(), findsNothing);
    expect(cancel(), findsNothing);
  });

  testWidgets('reports keystrokes and the search action', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), 'fog');
    await tester.testTextInput.receiveAction(TextInputAction.search);

    expect(changes, <String>['fog']);
    expect(submissions, <String>['fog']);
  });

  testWidgets('the clear pill follows the controller text', (tester) async {
    await pumpField(tester);

    controller.text = 'fog';
    await tester.pump();
    expect(clearPill(), findsOneWidget);

    await tester.tap(clearPill());
    expect(clears, 1);

    controller.clear();
    await tester.pump();
    expect(clearPill(), findsNothing);
  });

  testWidgets('Cancel appears while focused and calls onCancel', (
    tester,
  ) async {
    await pumpField(tester);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(cancel(), findsOneWidget);

    await tester.tap(cancel());
    await tester.pump();

    expect(cancels, 1);
    expect(clears, 0);
    expect(cancel(), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });
}
