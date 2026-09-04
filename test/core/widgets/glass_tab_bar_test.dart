import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixabay_image_browser/core/widgets/glass_tab_bar.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required AppTab active,
    required ValueChanged<AppTab> onTap,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: <Widget>[GlassTabBar(active: active, onTap: onTap)],
          ),
        ),
      ),
    );
  }

  testWidgets('every tab is labelled and reports its tap', (tester) async {
    final taps = <AppTab>[];
    await pumpBar(tester, active: AppTab.explore, onTap: taps.add);

    await tester.tap(find.bySemanticsLabel(GlassTabBar.exploreActiveLabel));
    await tester.tap(find.bySemanticsLabel(GlassTabBar.favouritesLabel));
    await tester.tap(find.bySemanticsLabel(GlassTabBar.profileLabel));

    expect(taps, <AppTab>[AppTab.explore, AppTab.favourites, AppTab.profile]);
  });

  testWidgets('the scroll-to-top label only belongs to an active Explore', (
    tester,
  ) async {
    await pumpBar(tester, active: AppTab.profile, onTap: (_) {});

    expect(find.bySemanticsLabel(GlassTabBar.exploreLabel), findsOneWidget);
    expect(find.bySemanticsLabel(GlassTabBar.exploreActiveLabel), findsNothing);
    expect(find.bySemanticsLabel(GlassTabBar.profileLabel), findsOneWidget);
  });
}
