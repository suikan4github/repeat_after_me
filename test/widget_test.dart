// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/main.dart';
import 'package:repeat_after_me/settings_page.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class _FakeSafUtil extends SafUtilPlatform {
  int listCalls = 0;
  int rootListCalls = 0;
  bool failNextList = false;

  @override
  Future<List<SafDocumentFile>> list(String uri) async {
    listCalls++;
    if (uri == 'content://tree/music') rootListCalls++;
    if (failNextList) {
      failNextList = false;
      throw Exception('folder unavailable');
    }
    SafDocumentFile file(String name, {bool isDir = false}) => SafDocumentFile(
      uri: '$uri/$name',
      name: name,
      isDir: isDir,
      length: 1,
      lastModified: 1,
    );
    if (uri == 'content://tree/music') {
      return [file('hello.m4a'), file('notes.txt'), file('sub', isDir: true)];
    }
    if (uri == 'content://tree/music/sub') {
      return [file('nested.m4a'), file('deep', isDir: true)];
    }
    if (uri == 'content://tree/music/sub/deep') {
      return [file('deep.m4a')];
    }
    return [];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('with an audio folder selected', () {
    late _FakeSafUtil safUtil;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'settings.audioDirectoryUri': 'content://tree/music',
        'settings.audioDirectoryName': 'music',
      });
      safUtil = _FakeSafUtil();
      SafUtilPlatform.instance = safUtil;
    });

    testWidgets('lists only .m4a files directly in the folder', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('hello'), findsOneWidget);
      expect(find.text('notes'), findsNothing);
      expect(find.text('sub'), findsNothing);
    });

    testWidgets('reloads the list from the refresh button', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reload'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(safUtil.rootListCalls, 2);
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('lists nested audio after selecting a subdirectory', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('/sub').last);
      await tester.pumpAndSettle();

      expect(find.text('nested'), findsOneWidget);
      expect(find.text('hello'), findsNothing);
      expect(find.text('/sub'), findsOneWidget);
      expect((await AppSettings.load()).audioSubdirectoryPath, '/sub');
    });

    testWidgets('restores a selected nested directory after app restart', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final settings = await AppSettings.load();
      await settings.setAudioSubdirectoryPath('/sub/deep');

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('deep'), findsOneWidget);
      expect(find.text('/sub/deep'), findsOneWidget);
    });

    testWidgets('falls back to / and prompts when saved directory is missing', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({
        'settings.audioDirectoryUri': 'content://tree/music',
        'settings.audioDirectoryName': 'music',
        'settings.audioSubdirectoryPath': '/missing',
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'The saved folder is unavailable. Showing /; choose a folder again.',
        ),
        findsOneWidget,
      );
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('/'), findsOneWidget);
      expect((await AppSettings.load()).audioSubdirectoryPath, '/');

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('/').last);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The saved folder is unavailable. Showing /; choose a folder again.',
        ),
        findsNothing,
      );
    });

    testWidgets('recovers through the retry button after a load error', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      safUtil.failNextList = true;

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Could not load audio files'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('hello'), findsOneWidget);
    });
  });
  testWidgets('uses Japanese for Japanese system locales', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ja', 'JP')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('リピート・アフター・ミー'), findsOneWidget);
    expect(find.text('音声ライブラリ'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
      '絞り込み検索',
    );
    expect(find.byTooltip('連続再生'), findsOneWidget);
    expect(find.byTooltip('再生を停止'), findsOneWidget);

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
      'Filter by name',
    );
    expect(find.byTooltip('Play continuously'), findsOneWidget);
    expect(find.byTooltip('Stop playback'), findsOneWidget);
  });

  testWidgets('opens the drawer and closes after selecting the current page', (
    WidgetTester tester,
  ) async {
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

  testWidgets('opens appearance settings from navigation', (
    WidgetTester tester,
  ) async {
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
    const packageInfoChannel = MethodChannel(
      'dev.fluttercommunity.plus/package_info',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          packageInfoChannel,
          (call) async => {
            'appName': 'Repeat After Me',
            'packageName': 'com.example.repeat_after_me',
            'version': '1.0.0',
            'buildNumber': '6',
          },
        );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(packageInfoChannel, null),
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('バージョン情報'));
    await tester.pumpAndSettle();

    expect(find.text('1.0.0'), findsOneWidget);
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
