// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/main.dart';
import 'package:repeat_after_me/settings_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  testWidgets('opens appearance settings from navigation',
      (WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Color scheme'), findsOneWidget);
    expect(find.text('Seed color'), findsOneWidget);
    expect(find.text('Color variant'), findsOneWidget);
    expect(find.text('Speak button size'), findsNothing);

    await tester.tap(find.text('Follow system'));
    await tester.pumpAndSettle();
    expect(find.text('Seed color'), findsNothing);
    expect(find.text('Color variant'), findsNothing);
  });

  testWidgets('shows version and copyright from the drawer', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('バージョン情報'));
    await tester.pumpAndSettle();

    expect(find.text('0.1.1'), findsOneWidget);
    expect(find.text('© 2026 HORIE Seiichi'), findsOneWidget);
  });

  testWidgets('positions settings with a 3 to 7 vertical spacing ratio', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settings = await AppSettings.load();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsPage(settings: settings),
      ),
    );
    await tester.pumpAndSettle();

    final content = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.vertical,
    );
    final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
    final scaffoldBottom = tester.getBottomRight(find.byType(Scaffold)).dy;
    final contentRect = tester.getRect(content);
    final topSpace = contentRect.top - appBarBottom;
    final bottomSpace = scaffoldBottom - contentRect.bottom;

    expect(topSpace / bottomSpace, closeTo(3 / 7, 0.02));
  });

  test('persists appearance settings across reloads', () async {
    final settings = await AppSettings.load();
    await settings.setFollowSystemColors(true);
    await settings.setSeedColor(const Color(0xFF008577));
    await settings.setSchemeVariant(DynamicSchemeVariant.monochrome);

    final restored = await AppSettings.load();
    expect(restored.followSystemColors, isTrue);
    expect(restored.seedColor, const Color(0xFF008577));
    expect(restored.schemeVariant, DynamicSchemeVariant.monochrome);
  });
}
