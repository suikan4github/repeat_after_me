import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/audio_library_page.dart';
import 'package:repeat_after_me/audio_metadata_index.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:saf_stream/saf_stream_platform_interface.dart';
import 'package:saf_util/saf_util_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSafUtil extends SafUtilPlatform {
  @override
  Future<List<SafDocumentFile>> list(String uri) async =>
      List.generate(5, (index) {
        final name = 'phrase$index.m4a';
        return SafDocumentFile(
          uri: '$uri/$name',
          name: name,
          isDir: false,
          length: 1,
          lastModified: 1,
        );
      });
}

class _FakeSafStream extends SafStreamPlatform {
  @override
  Future<void> copyToLocalFile(String srcUri, String destPath) async {
    await File(destPath).writeAsBytes([1]);
  }
}

class _FakeAudioMetadataIndex extends AudioMetadataIndex {
  _FakeAudioMetadataIndex({this.tagsByUri = const {}});

  final Map<String, AudioMetadataTags> tagsByUri;

  @override
  Future<Map<String, AudioMetadataTags>> synchronizeDirectory({
    required String directoryUri,
    required List<AudioMetadataFile> files,
    required AudioMetadataExtractor extractMetadata,
  }) async => {
    for (final file in files)
      file.uri: tagsByUri[file.uri] ?? const AudioMetadataTags(),
  };

  @override
  Future<void> close() async {}
}

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('repeat-test');
    SharedPreferences.setMockInitialValues({
      'settings.audioDirectoryUri': 'content://tree/audio',
      'settings.audioDirectoryName': 'audio',
    });
    SafUtilPlatform.instance = _FakeSafUtil();
    SafStreamPlatform.instance = _FakeSafStream();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => temporaryDirectory.path,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await temporaryDirectory.delete(recursive: true);
  });

  testWidgets(
    'continuous playback waits for completion and a one-second gap per item',
    (tester) async {
      final player = _ControlledAudioPlayer();
      final settings = await AppSettings.load();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AudioLibraryPage(
            settings: settings,
            playerFactory: () => player,
            metadataIndex: _FakeAudioMetadataIndex(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstTitle =
          tester.widgetList<ListTile>(find.byType(ListTile)).first.title!
              as Text;
      await tester.tap(find.byTooltip('Play continuously'));
      await _waitForPlaybackStart(tester, player);

      expect(player.startedAssetPaths, hasLength(1));
      expect(_rowHasPauseIcon(tester, firstTitle.data!), isTrue);

      await tester.pump(const Duration(seconds: 2));
      expect(
        player.startedAssetPaths,
        hasLength(1),
        reason: 'A new item must not start while the current one is playing.',
      );
      expect(_rowHasPauseIcon(tester, firstTitle.data!), isTrue);

      player.completeCurrentItem();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 999));
      expect(player.startedAssetPaths, hasLength(1));

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      await _waitForPlaybackStart(tester, player, expectedCount: 2);
      expect(player.startedAssetPaths, hasLength(2));
      expect(player.startedAssetPaths[1], isNot(player.startedAssetPaths[0]));
      final secondTitle = player.startedAssetPaths[1]
          .split('/')
          .last
          .split('_')
          .first;
      expect(find.text(secondTitle), findsOneWidget);
    },
  );

  testWidgets('disables search filter changes during continuous playback', (
    tester,
  ) async {
    final player = _ControlledAudioPlayer();
    await _pumpPage(tester, player);

    await tester.enterText(find.byType(TextField), 'phrase');
    await tester.pump();
    await tester.tap(find.byTooltip('Play continuously'));
    await _waitForPlaybackStart(tester, player);
    expect(player.startedAssetPaths, hasLength(1));

    final searchField = tester.widget<TextField>(find.byType(TextField));
    expect(searchField.enabled, isFalse);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.refresh))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isFalse,
    );
    expect(searchField.controller!.text, 'phrase');
    expect(find.widgetWithText(ListTile, 'phrase0'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'phrase1'), findsOneWidget);
    expect((await AppSettings.load()).searchQuery, 'phrase');

    await tester.tap(find.byTooltip('Stop playback'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('disables item play buttons during continuous playback', (
    tester,
  ) async {
    final player = _ControlledAudioPlayer();
    await _pumpPage(tester, player);

    await tester.tap(find.byTooltip('Play continuously'));
    await _waitForPlaybackStart(tester, player);
    expect(player.startedAssetPaths, hasLength(1));

    final buttons = tester.widgetList<IconButton>(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.byType(IconButton),
      ),
    );
    expect(buttons, isNotEmpty);
    expect(buttons.every((button) => button.onPressed == null), isTrue);

    await tester.tap(find.byType(ListTile).at(3), warnIfMissed: false);
    await tester.pump();
    expect(player.startedAssetPaths, hasLength(1));
    expect(find.byTooltip('Stop playback'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.repeat))
          .onPressed,
      isNull,
    );
  });

  testWidgets('plays the tapped item after a previous item completed', (
    tester,
  ) async {
    final player = _ControlledAudioPlayer();
    await _pumpPage(tester, player);

    await tester.tap(find.byType(ListTile).at(0));
    await _waitForPlaybackStart(tester, player);
    player.completeCurrentItem();
    await tester.pump();

    await tester.tap(find.byType(ListTile).at(3));
    await _waitForPlaybackStart(tester, player, expectedCount: 2);

    final tappedTitle =
        (tester.widgetList<ListTile>(find.byType(ListTile)).elementAt(3).title!
                as Text)
            .data!;
    expect(player.startedAssetPaths, hasLength(2));
    expect(player.startedAssetPaths.last, contains('/${tappedTitle}_'));
  });

  testWidgets('searches title, album, and artist metadata', (tester) async {
    final player = _ControlledAudioPlayer();
    await _pumpPage(
      tester,
      player,
      metadataIndex: _FakeAudioMetadataIndex(
        tagsByUri: const {
          'content://tree/audio/phrase0.m4a': AudioMetadataTags(
            title: 'Autumn Leaves',
            album: 'Blue Note Sessions',
            artist: 'Eva Cassidy',
          ),
        },
      ),
    );

    for (final query in ['Autumn', 'Blue Note', 'Eva Cassidy']) {
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      expect(find.text('phrase0'), findsOneWidget, reason: 'query: $query');
      expect(find.text('phrase1'), findsNothing, reason: 'query: $query');
    }
  });

  testWidgets('restores the saved search query on launch', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.audioDirectoryUri': 'content://tree/audio',
      'settings.audioDirectoryName': 'audio',
      'settings.searchQuery': 'phrase1',
    });
    await _pumpPage(tester, _ControlledAudioPlayer());

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'phrase1',
    );
    expect(find.widgetWithText(ListTile, 'phrase1'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'phrase0'), findsNothing);
  });

  testWidgets('saves the query and lists history newest first', (tester) async {
    await _pumpPage(tester, _ControlledAudioPlayer());

    for (final word in ['one', 'two', 'three']) {
      await tester.enterText(find.byType(TextField), word);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
    }
    expect((await AppSettings.load()).searchQuery, 'three');

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    final titles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title! as Text).data)
        .toList();
    expect(titles.take(3), ['three', 'two', 'one']);

    await tester.tap(find.widgetWithText(ListTile, 'one'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'one',
    );
    expect((await AppSettings.load()).searchQuery, 'one');
  });

  testWidgets('item play commits the search word and hides history', (
    tester,
  ) async {
    await _pumpPage(tester, _ControlledAudioPlayer());

    await tester.enterText(find.byType(TextField), 'phrase');
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.play_arrow).first);
    await tester.pump();

    expect((await AppSettings.load()).searchHistory, ['phrase']);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  testWidgets('continuous play commits the search word and hides history', (
    tester,
  ) async {
    await _pumpPage(tester, _ControlledAudioPlayer());

    await tester.enterText(find.byType(TextField), 'phrase');
    await tester.pump();
    await tester.tap(find.byTooltip('Play continuously'));
    await tester.pump();

    expect((await AppSettings.load()).searchHistory, ['phrase']);
    expect(find.byIcon(Icons.history), findsNothing);
  });

  group('auto stop timer', () {
    bool isContinuous(WidgetTester tester) =>
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.repeat))
            .onPressed ==
        null;

    testWidgets('stops continuous playback after 15 minutes', (tester) async {
      final player = _ControlledAudioPlayer();
      await _pumpPage(tester, player);

      await tester.tap(find.byTooltip('Play continuously'));
      await _waitForPlaybackStart(tester, player);

      await tester.pump(const Duration(minutes: 14, seconds: 59));
      expect(isContinuous(tester), isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(isContinuous(tester), isFalse);
      expect(player.playing, isFalse);
    });

    testWidgets('manual stop cancels the timer and restart resets it', (
      tester,
    ) async {
      final player = _ControlledAudioPlayer();
      await _pumpPage(tester, player);

      await tester.tap(find.byTooltip('Play continuously'));
      await _waitForPlaybackStart(tester, player);
      await tester.pump(const Duration(minutes: 10));
      await tester.tap(find.byTooltip('Stop playback'));
      await tester.pump();
      expect(isContinuous(tester), isFalse);

      await tester.pump(const Duration(minutes: 10));
      await tester.tap(find.byTooltip('Play continuously'));
      await _waitForPlaybackStart(tester, player);

      // The old timer would have fired here, 5 minutes after the restart.
      await tester.pump(const Duration(minutes: 14, seconds: 59));
      expect(isContinuous(tester), isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(isContinuous(tester), isFalse);
    });
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  AudioPlayer player, {
  AudioMetadataIndex? metadataIndex,
}) async {
  final settings = await AppSettings.load();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AudioLibraryPage(
        settings: settings,
        playerFactory: () => player,
        metadataIndex: metadataIndex ?? _FakeAudioMetadataIndex(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _waitForPlaybackStart(
  WidgetTester tester,
  _ControlledAudioPlayer player, {
  int expectedCount = 1,
}) async {
  for (
    var attempt = 0;
    attempt < 20 && player.startedAssetPaths.length < expectedCount;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

bool _rowHasPauseIcon(WidgetTester tester, String title) {
  final row = find.ancestor(
    of: find.text(title),
    matching: find.byType(ListTile),
  );
  return find
      .descendant(of: row, matching: find.byIcon(Icons.pause))
      .evaluate()
      .isNotEmpty;
}

class _ControlledAudioPlayer extends AudioPlayer {
  final _stateController = StreamController<PlayerState>.broadcast();
  final List<String> startedAssetPaths = [];
  String? _assetPath;
  bool _playing = false;

  @override
  Stream<PlayerState> get playerStateStream => _stateController.stream;

  @override
  bool get playing => _playing;

  @override
  Future<Duration?> setAsset(
    String assetPath, {
    String? package,
    bool preload = true,
    Duration? initialPosition,
    dynamic tag,
  }) async {
    _assetPath = assetPath;
    return null;
  }

  @override
  Future<Duration?> setFilePath(
    String filePath, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    _assetPath = filePath;
    return null;
  }

  @override
  Future<void> play() async {
    // Like just_audio: a no-op while still flagged as playing.
    if (_playing) return;
    _playing = true;
    startedAssetPaths.add(_assetPath!);
    _stateController.add(PlayerState(true, ProcessingState.ready));
  }

  void completeCurrentItem() {
    // just_audio keeps `playing` true after completion.
    _stateController.add(PlayerState(true, ProcessingState.completed));
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _stateController.add(PlayerState(false, ProcessingState.idle));
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    await _stateController.close();
  }
}
