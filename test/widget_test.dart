// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:repeat_after_me/main.dart';

void main() {
  testWidgets('uses Japanese for Japanese system locales',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('リピート・アフター・ミー'), findsOneWidget);
    expect(find.text('音声ライブラリ'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
      '名前を検索',
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('メインページ'), findsOneWidget);
  });

  testWidgets('uses English for non-Japanese system locales', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'FR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Repeat After Me'), findsOneWidget);
    expect(find.text('Your audio library'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
      'Search names',
    );
  });

  testWidgets('opens the drawer and closes after selecting the current page',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Main page'), findsOneWidget);
    final mainPageTile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Main page'),
        matching: find.byType(ListTile),
      ),
    );
    expect(mainPageTile.selected, isTrue);

    await tester.tap(find.text('Main page'));
    await tester.pumpAndSettle();
    expect(find.text('Main page'), findsNothing);
  });
}
