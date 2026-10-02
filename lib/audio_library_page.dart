import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/settings_page.dart';
import 'package:repeat_after_me/widgets/app_navigation_drawer.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  static const _assetDirectory = 'assets/audio/';
  final _searchController = TextEditingController();
  late Future<List<_AudioEntry>> _audioNamesFuture;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? _playingAssetPath;
  bool _isPlaying = false;
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
    final names = manifest
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
      ..sort((first, second) => first.name.toLowerCase().compareTo(
            second.name.toLowerCase(),
          ));
    return names;
  }

  AudioPlayer _getPlayer() {
    final currentPlayer = _player;
    if (currentPlayer != null) return currentPlayer;

    final player = AudioPlayer();
    _player = player;
    _playerStateSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        if (state.processingState == ProcessingState.completed) {
          _playingAssetPath = null;
          _isPlaying = false;
        }
      });
    });
    return player;
  }

  Future<void> _togglePlayback(_AudioEntry entry) async {
    final player = _getPlayer();
    try {
      if (_playingAssetPath == entry.assetPath) {
        if (player.playing) {
          await player.pause();
        } else {
          await player.play();
        }
        return;
      }

      setState(() {
        _playingAssetPath = entry.assetPath;
        _isPlaying = false;
      });
      await player.setAsset(entry.assetPath);
      await player.play();
    } catch (error, stackTrace) {
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
                Text(
                  l10n.audioLibraryTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF18312F),
                        fontWeight: FontWeight.w700,
                      ),
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
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
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

                        final allNames =
                          snapshot.data ?? const <_AudioEntry>[];
                      final query = _query.trim().toLowerCase();
                        final filteredNames = allNames
                          .where((entry) =>
                            entry.name.toLowerCase().contains(query))
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
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
                                  onTap: () => _togglePlayback(entry),
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
                                    onPressed: () => _togglePlayback(entry),
                                    icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
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
          if (action != null) ...[
            const SizedBox(height: 12),
            action!,
          ],
        ],
      ),
    );
  }
}