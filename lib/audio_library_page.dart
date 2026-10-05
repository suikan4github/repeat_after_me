import 'dart:async';
import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/audio_metadata_index.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/settings_page.dart';
import 'package:repeat_after_me/widgets/app_navigation_drawer.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({
    super.key,
    required this.settings,
    this.playerFactory,
    this.metadataExtractor,
    this.metadataIndex,
  });

  final AppSettings settings;
  final AudioPlayer Function()? playerFactory;
  final AudioMetadataExtractor? metadataExtractor;
  final AudioMetadataIndex? metadataIndex;

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  static const _extension = '.m4a';
  static const _continuousPlaybackInterval = Duration(seconds: 1);
  static const _continuousPlaybackLimit = Duration(minutes: 15);
  final _safUtil = SafUtil();
  final _safStream = SafStream();
  late final AudioMetadataIndex _metadataIndex;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late Future<_AudioLibraryData> _audioLibraryFuture;
  String? _loadedDirectoryUri;
  String _loadedSubdirectoryPath = '/';
  bool _showSavedDirectoryError = false;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? _playingUri;
  bool _isPlaying = false;
  bool _isContinuousPlaying = false;
  Timer? _autoStopTimer;
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
    _metadataIndex = widget.metadataIndex ?? AudioMetadataIndex();
    _query = widget.settings.searchQuery;
    _searchController.text = _query;
    _searchFocusNode.addListener(_onSearchFocusChanged);
    _audioLibraryFuture = _loadAudioLibrary();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      unawaited(widget.settings.addSearchHistory(_query));
    }
    setState(() {});
  }

  void _setQuery(String value) {
    setState(() => _query = value);
    unawaited(widget.settings.setSearchQuery(value));
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    widget.settings.removeListener(_onSettingsChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_player?.dispose());
    if (widget.metadataIndex == null) unawaited(_metadataIndex.close());
    super.dispose();
  }

  void _onSettingsChanged() {
    if (widget.settings.audioDirectoryUri == _loadedDirectoryUri &&
        widget.settings.audioSubdirectoryPath == _loadedSubdirectoryPath) {
      return;
    }
    if (widget.settings.audioDirectoryUri != _loadedDirectoryUri) {
      _showSavedDirectoryError = false;
    }
    _resetPlaybackPosition();
    unawaited(_player?.stop());
    setState(() {
      _audioLibraryFuture = _loadAudioLibrary();
    });
  }

  void _reload() {
    _resetPlaybackPosition();
    unawaited(_player?.stop());
    setState(() {
      _audioLibraryFuture = _loadAudioLibrary();
    });
  }

  Future<void> _rebuildMetadataIndex() async {
    try {
      final library = await _audioLibraryFuture;
      await _metadataIndex.invalidateDirectory(library.selectedDirectory.uri);
      if (mounted) _reload();
    } catch (error, stackTrace) {
      debugPrint('Rebuilding audio metadata index failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loadErrorMessage)),
      );
    }
  }

  void _resetPlaybackPosition() {
    _autoStopTimer?.cancel();
    _playbackGeneration++;
    _isContinuousPlaying = false;
    _playingUri = null;
    _isPlaying = false;
    _lastUserPlayedAssetPath = null;
    _lastContinuousEndedAssetPath = null;
    _playbackActivityOrder = 0;
    _lastUserPlaybackOrder = 0;
    _lastContinuousEndOrder = 0;
  }

  Future<void> _selectSubdirectory(String path) async {
    setState(() => _showSavedDirectoryError = false);
    await widget.settings.setAudioSubdirectoryPath(path);
  }

  Future<_AudioLibraryData> _loadAudioLibrary() async {
    final rootUri = widget.settings.audioDirectoryUri;
    _loadedDirectoryUri = rootUri;
    _loadedSubdirectoryPath = widget.settings.audioSubdirectoryPath;
    if (rootUri == null) return const _AudioLibraryData.empty();

    final directories = <String, _AudioDirectory>{
      '/': _AudioDirectory(path: '/', name: '/', uri: rootUri),
    };
    final contentsByUri = <String, List<SafDocumentFile>>{};
    final visitedUris = <String>{rootUri};

    Future<void> visitDirectory(String uri, String parentPath) async {
      final children = await _safUtil.list(uri);
      contentsByUri[uri] = children;
      for (final child in children.where((item) => item.isDir)) {
        if (!visitedUris.add(child.uri)) continue;
        final path = parentPath == '/'
            ? '/${child.name}'
            : '$parentPath/${child.name}';
        directories[path] = _AudioDirectory(
          path: path,
          name: child.name,
          uri: child.uri,
        );
        await visitDirectory(child.uri, path);
      }
    }

    final rootChildren = await _safUtil.list(rootUri);
    contentsByUri[rootUri] = rootChildren;
    for (final child in rootChildren.where((item) => item.isDir)) {
      if (!visitedUris.add(child.uri)) continue;
      final path = '/${child.name}';
      directories[path] = _AudioDirectory(
        path: path,
        name: child.name,
        uri: child.uri,
      );
      await visitDirectory(child.uri, path);
    }

    var selectedPath = widget.settings.audioSubdirectoryPath;
    if (!directories.containsKey(selectedPath)) {
      _showSavedDirectoryError = true;
      selectedPath = '/';
      await widget.settings.setAudioSubdirectoryPath('/');
    }
    _loadedSubdirectoryPath = selectedPath;

    final selectedDirectory = directories[selectedPath]!;
    final files = contentsByUri[selectedDirectory.uri] ?? const [];
    final audioFiles = files
        .where(
          (file) => !file.isDir && file.name.toLowerCase().endsWith(_extension),
        )
        .map(
          (file) => AudioMetadataFile(
            uri: file.uri,
            name: file.name,
            length: file.length,
            lastModified: file.lastModified,
          ),
        )
        .toList();
    final tagsByUri = await _metadataIndex.synchronizeDirectory(
      directoryUri: selectedDirectory.uri,
      files: audioFiles,
      extractMetadata: widget.metadataExtractor ?? _extractMetadata,
    );
    final entries =
        audioFiles
            .map(
              (file) => _AudioEntry(
                uri: file.uri,
                name: file.name.substring(
                  0,
                  file.name.length - _extension.length,
                ),
                length: file.length,
                lastModified: file.lastModified,
                metadata: tagsByUri[file.uri] ?? const AudioMetadataTags(),
              ),
            )
            .toList()
          ..sort(
            (first, second) =>
                first.name.toLowerCase().compareTo(second.name.toLowerCase()),
          );

    final sortedDirectories = directories.values.toList()
      ..sort((first, second) {
        if (first.path == '/') return -1;
        if (second.path == '/') return 1;
        return first.path.toLowerCase().compareTo(second.path.toLowerCase());
      });
    return _AudioLibraryData(
      directories: sortedDirectories,
      entries: entries,
      selectedDirectory: selectedDirectory,
    );
  }

  Future<Map<String, AudioMetadataTags>> _extractMetadata(
    List<AudioMetadataFile> files,
  ) async {
    final temporaryRoot = await getTemporaryDirectory();
    final metadataDirectory = Directory('${temporaryRoot.path}/metadata_work');
    await metadataDirectory.create(recursive: true);
    final result = <String, AudioMetadataTags>{};

    for (final source in files) {
      final temporaryFile = File(
        '${metadataDirectory.path}/${source.uri.hashCode}_${source.length}_'
        '${source.lastModified}$_extension',
      );
      try {
        await _safStream.copyToLocalFile(source.uri, temporaryFile.path);
        final metadata = readMetadata(temporaryFile, getImage: false);
        result[source.uri] = AudioMetadataTags(
          title: metadata.title,
          album: metadata.album,
          artist: metadata.artist,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Audio metadata extraction failed for ${source.uri}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        result[source.uri] = const AudioMetadataTags();
      } finally {
        if (await temporaryFile.exists()) await temporaryFile.delete();
      }
    }

    return result;
  }

  Future<Directory> _cacheDirectory() async {
    final root = await getTemporaryDirectory();
    return Directory('${root.path}/audio_cache').create(recursive: true);
  }

  /// The player needs a file path, so the SAF file is copied into the cache.
  Future<String> _prepareLocalFile(_AudioEntry entry) async {
    final directory = await _cacheDirectory();
    final key = '${entry.uri.hashCode}_${entry.lastModified}_${entry.length}';
    final target = File('${directory.path}/${entry.name}_$key$_extension');
    if (!await target.exists()) {
      final partial = '${target.path}.part';
      await _safStream.copyToLocalFile(entry.uri, partial);
      await File(partial).rename(target.path);
    }
    return target.path;
  }

  Future<void> _clearCacheExcept(String keepPath) async {
    final directory = await _cacheDirectory();
    await for (final item in directory.list()) {
      if (item is File && item.path != keepPath) await item.delete();
    }
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
          if (!_isContinuousPlaying) _playingUri = null;
          _isPlaying = false;
        }
      });
    });
    return player;
  }

  Future<void> _togglePlayback(_AudioEntry entry) async {
    _searchFocusNode.unfocus();
    final player = _getPlayer();
    final generation = ++_playbackGeneration;
    _autoStopTimer?.cancel();
    if (_isContinuousPlaying && _playingUri != null) {
      _recordContinuousPlaybackEnd(_playingUri!);
    }
    setState(() => _isContinuousPlaying = false);
    try {
      if (_playingUri == entry.uri) {
        if (player.playing) {
          await player.pause();
        } else {
          _recordUserPlayback(entry);
          await player.play();
        }
        return;
      }

      setState(() {
        _playingUri = entry.uri;
        _isPlaying = false;
      });
      await player.stop();
      if (generation != _playbackGeneration) return;
      final path = await _prepareLocalFile(entry);
      if (generation != _playbackGeneration) return;
      await player.setFilePath(path);
      if (generation != _playbackGeneration) return;
      _recordUserPlayback(entry);
      unawaited(_clearCacheExcept(path));
      await player.play();
    } catch (error, stackTrace) {
      if (generation != _playbackGeneration) return;
      debugPrint('Audio playback failed for ${entry.uri}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _playingUri = null;
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
    _lastUserPlayedAssetPath = entry.uri;
    _lastUserPlaybackOrder = ++_playbackActivityOrder;
  }

  Future<void> _startContinuousPlayback() async {
    _searchFocusNode.unfocus();
    final generation = ++_playbackGeneration;
    final player = _getPlayer();
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(_continuousPlaybackLimit, _stopPlayback);
    setState(() {
      _isContinuousPlaying = true;
    });

    try {
      final allEntries = (await _audioLibraryFuture).entries;
      if (!_isCurrentContinuousPlayback(generation)) return;
      final query = _query.trim().toLowerCase();
      final entries = allEntries
          .where((entry) => entry.matches(query))
          .toList();
      if (entries.isEmpty) {
        _autoStopTimer?.cancel();
        setState(() => _isContinuousPlaying = false);
        return;
      }

      final lastPlayedOrder = _lastUserPlaybackOrder;
      final lastEndedOrder = _lastContinuousEndOrder;
      final lastPath = lastPlayedOrder > lastEndedOrder
          ? _lastUserPlayedAssetPath
          : _lastContinuousEndedAssetPath;
      final lastIndex = entries.indexWhere((entry) => entry.uri == lastPath);
      var index = lastIndex < 0 ? 0 : lastIndex;

      await player.stop();
      while (_isCurrentContinuousPlayback(generation)) {
        final entry = entries[index];
        // just_audio keeps `playing` true after completion, which makes the
        // next play() a no-op; stop() resets it so the new source is audible.
        await player.stop();
        if (!_isCurrentContinuousPlayback(generation)) return;
        final path = await _prepareLocalFile(entry);
        await player.setFilePath(path);
        unawaited(_clearCacheExcept(path));
        if (!_isCurrentContinuousPlayback(generation)) return;
        setState(() {
          _playingUri = entry.uri;
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

        _recordContinuousPlaybackEnd(entry.uri);
        await Future<void>.delayed(_continuousPlaybackInterval);
        if (!_isCurrentContinuousPlayback(generation)) return;
        index = (index + 1) % entries.length;
      }
    } catch (error, stackTrace) {
      if (!_isCurrentContinuousPlayback(generation)) return;
      _autoStopTimer?.cancel();
      debugPrint('Continuous audio playback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isContinuousPlaying = false;
        _playingUri = null;
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

  void _recordContinuousPlaybackEnd(String uri) {
    _lastContinuousEndedAssetPath = uri;
    _lastContinuousEndOrder = ++_playbackActivityOrder;
  }

  Future<void> _stopPlayback() async {
    ++_playbackGeneration;
    _autoStopTimer?.cancel();
    if (_isContinuousPlaying && _playingUri != null) {
      _recordContinuousPlaybackEnd(_playingUri!);
    }
    setState(() => _isContinuousPlaying = false);
    try {
      await _player?.stop();
      if (!mounted) return;
      setState(() {
        _playingUri = null;
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
        actions: [
          if (widget.settings.audioDirectoryUri != null)
            IconButton(
              tooltip: l10n.refresh,
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          if (widget.settings.audioDirectoryUri != null)
            PopupMenuButton<String>(
              tooltip: l10n.moreAudioActions,
              onSelected: (action) {
                if (action == 'rebuildMetadataIndex') {
                  unawaited(_rebuildMetadataIndex());
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'rebuildMetadataIndex',
                  child: Text(l10n.rebuildMetadataIndex),
                ),
              ],
            ),
        ],
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
                      child: FutureBuilder<_AudioLibraryData>(
                        future: _audioLibraryFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data!.directories.isEmpty) {
                            return Text(
                              l10n.audioLibraryTitle,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: const Color(0xFF18312F),
                                    fontWeight: FontWeight.w700,
                                  ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: snapshot.data!.selectedDirectory.path,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                items: snapshot.data!.directories
                                    .map(
                                      (directory) => DropdownMenuItem<String>(
                                        value: directory.path,
                                        child: Text(
                                          directory.path,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: const Color(0xFF18312F),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isContinuousPlaying
                                    ? null
                                    : (path) {
                                        if (path != null) {
                                          unawaited(_selectSubdirectory(path));
                                        }
                                      },
                              ),
                              if (_showSavedDirectoryError)
                                Text(
                                  l10n.savedSubdirectoryMissing,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: colors.error),
                                ),
                            ],
                          );
                        },
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
                      onPressed: !_isContinuousPlaying && _playingUri == null
                          ? null
                          : _stopPlayback,
                      icon: const Icon(Icons.stop),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: _setQuery,
                  onSubmitted: (value) =>
                      unawaited(widget.settings.addSearchHistory(value)),
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            onPressed: () {
                              _searchController.clear();
                              _setQuery('');
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
                if (_searchFocusNode.hasFocus &&
                    widget.settings.searchHistory.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: Column(
                      children: [
                        for (final word in widget.settings.searchHistory)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.history),
                            title: Text(word),
                            onTap: () {
                              _searchController.text = word;
                              _searchController.selection =
                                  TextSelection.collapsed(offset: word.length);
                              _setQuery(word);
                              unawaited(widget.settings.addSearchHistory(word));
                              _searchFocusNode.unfocus();
                            },
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Expanded(
                  child: widget.settings.audioDirectoryUri == null
                      ? _MessageState(
                          icon: Icons.folder_open,
                          title: l10n.noFolderTitle,
                          message: l10n.noFolderMessage,
                          action: FilledButton.icon(
                            onPressed: widget.settings.pickAudioDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: Text(l10n.settingsChooseAudioFolder),
                          ),
                        )
                      : FutureBuilder<_AudioLibraryData>(
                          future: _audioLibraryFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              debugPrint(
                                'Audio folder load error: ${snapshot.error}',
                              );
                              return _MessageState(
                                icon: Icons.warning_amber_rounded,
                                title: l10n.loadErrorTitle,
                                message: l10n.loadErrorMessage,
                                action: Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton.icon(
                                      onPressed: _reload,
                                      icon: const Icon(Icons.refresh),
                                      label: Text(l10n.retry),
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          widget.settings.pickAudioDirectory,
                                      icon: const Icon(Icons.folder_open),
                                      label: Text(
                                        l10n.settingsChooseAudioFolder,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final allNames = snapshot.data!.entries;
                            final query = _query.trim().toLowerCase();
                            final filteredNames = allNames
                                .where((entry) => entry.matches(query))
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
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                          height: 1,
                                          color: colors.outlineVariant,
                                        ),
                                    itemBuilder: (context, index) {
                                      final entry = filteredNames[index];
                                      final isCurrent =
                                          _playingUri == entry.uri;
                                      final isPlaying = isCurrent && _isPlaying;
                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
  const _AudioEntry({
    required this.uri,
    required this.name,
    required this.length,
    required this.lastModified,
    required this.metadata,
  });

  final String uri;
  final String name;
  final int length;
  final int lastModified;
  final AudioMetadataTags metadata;

  bool matches(String query) =>
      name.toLowerCase().contains(query) || metadata.matches(query);
}

class _AudioDirectory {
  const _AudioDirectory({
    required this.path,
    required this.name,
    required this.uri,
  });

  final String path;
  final String name;
  final String uri;
}

class _AudioLibraryData {
  const _AudioLibraryData({
    required this.directories,
    required this.entries,
    required this.selectedDirectory,
  });

  const _AudioLibraryData.empty()
    : directories = const [],
      entries = const [],
      selectedDirectory = const _AudioDirectory(path: '/', name: '/', uri: '');

  final List<_AudioDirectory> directories;
  final List<_AudioEntry> entries;
  final _AudioDirectory selectedDirectory;
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
