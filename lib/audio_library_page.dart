import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/settings_page.dart';
import 'package:repeat_after_me/widgets/app_navigation_drawer.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({
    super.key,
    required this.settings,
    this.playerFactory,
  });

  final AppSettings settings;
  final AudioPlayer Function()? playerFactory;

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  static const _assetDirectory = 'assets/audio/';
  static const _continuousPlaybackInterval = Duration(seconds: 1);
  final _searchController = TextEditingController();
  late Future<List<_AudioEntry>> _audioNamesFuture;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? _playingAssetPath;
  bool _isPlaying = false;
  bool _isContinuousPlaying = false;
  String? _lastUserPlayedAssetPath;
  String? _lastContinuousEndedAssetPath;
  int _playbackActivityOrder = 0;
  int _lastUserPlaybackOrder = 0;
  int _lastContinuousEndOrder = 0;
  int _playbackGeneration = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _audioNamesFuture = _loadAudioNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<List<_AudioEntry>> _loadAudioNames() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final names =
        manifest
            .listAssets()
            .where(
              (path) =>
                  path.startsWith(_assetDirectory) &&
                  path.toLowerCase().endsWith('.m4a'),
            )
            .map((path) {
              final filename = path.split('/').last;
              return _AudioEntry(
                assetPath: path,
                name: filename.substring(0, filename.length - 4),
              );
            })
            .toList()
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );
    return names;
  }

  AudioPlayer _getPlayer() {
    final currentPlayer = _player;
    if (currentPlayer != null) return currentPlayer;

    final player = widget.playerFactory?.call() ?? AudioPlayer();
    _player = player;
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          if (!_isContinuousPlaying) _playingAssetPath = null;
          _isPlaying = false;
        }
      });
    });
    return player;
  }

  Future<void> _togglePlayback(_AudioEntry entry) async {
    final player = _getPlayer();
    final generation = ++_playbackGeneration;
    if (_isContinuousPlaying && _playingAssetPath != null) {
      _recordContinuousPlaybackEnd(_playingAssetPath!);
    }
    setState(() => _isContinuousPlaying = false);
    try {
      if (_playingAssetPath == entry.assetPath) {
        if (player.playing) {
          await player.pause();
        } else {
          _recordUserPlayback(entry);
          await player.play();
        }
        return;
      }

      setState(() {
        _playingAssetPath = entry.assetPath;
        _isPlaying = false;
      });
      // A completed source leaves `playing` true, which would make play() a no-op.
      await player.stop();
      if (generation != _playbackGeneration) return;
      await player.setAsset(entry.assetPath);
      if (generation != _playbackGeneration) return;
      _recordUserPlayback(entry);
      await player.play();
    } catch (error, stackTrace) {
      if (generation != _playbackGeneration) return;
      debugPrint('Audio playback failed for ${entry.assetPath}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _playingAssetPath = null;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  void _recordUserPlayback(_AudioEntry entry) {
    _lastUserPlayedAssetPath = entry.assetPath;
    _lastUserPlaybackOrder = ++_playbackActivityOrder;
  }

  Future<void> _startContinuousPlayback() async {
    final generation = ++_playbackGeneration;
    final player = _getPlayer();
    setState(() {
      _isContinuousPlaying = true;
    });

    try {
      final allEntries = await _audioNamesFuture;
      if (!_isCurrentContinuousPlayback(generation)) return;
      final query = _query.trim().toLowerCase();
      final entries = allEntries
          .where((entry) => entry.name.toLowerCase().contains(query))
          .toList();
      if (entries.isEmpty) {
        setState(() => _isContinuousPlaying = false);
        return;
      }

      final lastPlayedOrder = _lastUserPlaybackOrder;
      final lastEndedOrder = _lastContinuousEndOrder;
      final lastPath = lastPlayedOrder > lastEndedOrder
          ? _lastUserPlayedAssetPath
          : _lastContinuousEndedAssetPath;
      final lastIndex = entries.indexWhere(
        (entry) => entry.assetPath == lastPath,
      );
      var index = lastIndex < 0 ? 0 : lastIndex;

      await player.stop();
      while (_isCurrentContinuousPlayback(generation)) {
        final entry = entries[index];
        // just_audio keeps `playing` true after completion, which makes the
        // next play() a no-op; stop() resets it so the new source is audible.
        await player.stop();
        if (!_isCurrentContinuousPlayback(generation)) return;
        await player.setAsset(entry.assetPath);
        if (!_isCurrentContinuousPlayback(generation)) return;
        setState(() {
          _playingAssetPath = entry.assetPath;
          _isPlaying = false;
        });
        final completion = player.playerStateStream.firstWhere(
          (state) =>
              state.processingState == ProcessingState.completed ||
              !_isCurrentContinuousPlayback(generation),
        );
        await player.play();
        if (!_isCurrentContinuousPlayback(generation)) return;
        final completedState = await completion;
        if (completedState.processingState != ProcessingState.completed ||
            !_isCurrentContinuousPlayback(generation)) {
          return;
        }

        _recordContinuousPlaybackEnd(entry.assetPath);
        await Future<void>.delayed(_continuousPlaybackInterval);
        if (!_isCurrentContinuousPlayback(generation)) return;
        index = (index + 1) % entries.length;
      }
    } catch (error, stackTrace) {
      if (!_isCurrentContinuousPlayback(generation)) return;
      debugPrint('Continuous audio playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isContinuousPlaying = false;
        _playingAssetPath = null;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  bool _isCurrentContinuousPlayback(int generation) =>
      mounted && _isContinuousPlaying && generation == _playbackGeneration;

  void _recordContinuousPlaybackEnd(String assetPath) {
    _lastContinuousEndedAssetPath = assetPath;
    _lastContinuousEndOrder = ++_playbackActivityOrder;
  }

  Future<void> _stopPlayback() async {
    ++_playbackGeneration;
    if (_isContinuousPlaying && _playingAssetPath != null) {
      _recordContinuousPlaybackEnd(_playingAssetPath!);
    }
    setState(() => _isContinuousPlaying = false);
    try {
      await _player?.stop();
      if (!mounted) return;
      setState(() {
        _playingAssetPath = null;
        _isPlaying = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Stopping audio playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppNavigationDrawer(
        selectedDestination: AppDestination.main,
        onDestinationSelected: (destination) {
          if (destination == AppDestination.settings) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(settings: widget.settings),
              ),
            );
          }
        },
      ),
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.audioLibraryTitle,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF18312F),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.continuousPlay,
                      onPressed: _isContinuousPlaying
                          ? null
                          : _startContinuousPlayback,
                      icon: const Icon(Icons.repeat),
                    ),
                    IconButton(
                      tooltip: l10n.stopPlayback,
                      onPressed:
                          !_isContinuousPlaying && _playingAssetPath == null
                          ? null
                          : _stopPlayback,
                      icon: const Icon(Icons.stop),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder<List<_AudioEntry>>(
                    future: _audioNamesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        debugPrint('Audio asset load error: ${snapshot.error}');
                        return _MessageState(
                          icon: Icons.warning_amber_rounded,
                          title: l10n.loadErrorTitle,
                          message: l10n.loadErrorMessage,
                          action: TextButton.icon(
                            onPressed: () => setState(
                              () => _audioNamesFuture = _loadAudioNames(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                          ),
                        );
                      }

                      final allNames = snapshot.data ?? const <_AudioEntry>[];
                      final query = _query.trim().toLowerCase();
                      final filteredNames = allNames
                          .where(
                            (entry) => entry.name.toLowerCase().contains(query),
                          )
                          .toList();

                      if (filteredNames.isEmpty) {
                        return _MessageState(
                          icon: query.isEmpty
                              ? Icons.library_music_outlined
                              : Icons.search_off,
                          title: query.isEmpty
                              ? l10n.emptyTitle
                              : l10n.noMatchesTitle,
                          message: query.isEmpty
                              ? l10n.emptyMessage
                              : l10n.noMatchesMessage,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              l10n.itemCount(filteredNames.length),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filteredNames.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: colors.outlineVariant,
                              ),
                              itemBuilder: (context, index) {
                                final entry = filteredNames[index];
                                final isCurrent =
                                    _playingAssetPath == entry.assetPath;
                                final isPlaying = isCurrent && _isPlaying;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  onTap: _isContinuousPlaying
                                      ? null
                                      : () => _togglePlayback(entry),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.graphic_eq,
                                      color: colors.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    entry.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  trailing: IconButton(
                                    tooltip: isPlaying
                                        ? l10n.pauseAudio
                                        : l10n.playAudio,
                                    onPressed: _isContinuousPlaying
                                        ? null
                                        : () => _togglePlayback(entry),
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioEntry {
  const _AudioEntry({required this.assetPath, required this.name});

  final String assetPath;
  final String name;
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}
