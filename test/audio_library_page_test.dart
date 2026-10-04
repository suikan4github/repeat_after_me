import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/audio_library_page.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstTitle =
          tester.widgetList<ListTile>(find.byType(ListTile)).first.title!
              as Text;
      await tester.tap(find.byTooltip('Play continuously'));
      await tester.pump();
      await tester.pump();

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
      expect(player.startedAssetPaths, hasLength(2));
      expect(player.startedAssetPaths[1], isNot(player.startedAssetPaths[0]));
      final secondTitle = player.startedAssetPaths[1]
          .split('/')
          .last
          .replaceFirst(RegExp(r'\.m4a$', caseSensitive: false), '');
      expect(_rowHasPauseIcon(tester, secondTitle), isTrue);
    },
  );

  testWidgets('disables item play buttons during continuous playback', (
    tester,
  ) async {
    final player = _ControlledAudioPlayer();
    await _pumpPage(tester, player);

    await tester.tap(find.byTooltip('Play continuously'));
    await tester.pump();
    await tester.pump();
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
    await tester.pump();
    await tester.pump();
    player.completeCurrentItem();
    await tester.pump();

    await tester.tap(find.byType(ListTile).at(3));
    await tester.pump();
    await tester.pump();

    final tappedTitle =
        (tester.widgetList<ListTile>(find.byType(ListTile)).elementAt(3).title!
                as Text)
            .data!;
    expect(player.startedAssetPaths, hasLength(2));
    expect(player.startedAssetPaths.last, endsWith('$tappedTitle.m4a'));
  });
}

Future<void> _pumpPage(WidgetTester tester, AudioPlayer player) async {
  final settings = await AppSettings.load();
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AudioLibraryPage(settings: settings, playerFactory: () => player),
    ),
  );
  await tester.pumpAndSettle();
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
