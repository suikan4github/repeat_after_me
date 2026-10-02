import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioLibraryPage extends StatefulWidget {
  const AudioLibraryPage({super.key});

  @override
  State<AudioLibraryPage> createState() => _AudioLibraryPageState();
}

class _AudioLibraryPageState extends State<AudioLibraryPage> {
  static const _assetDirectory = 'assets/audio/';
  final _searchController = TextEditingController();
  late Future<List<String>> _audioNamesFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _audioNamesFuture = _loadAudioNames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<String>> _loadAudioNames() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final names = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith(_assetDirectory) &&
              path.toLowerCase().endsWith('.m4a'),
        )
        .map((path) => path.split('/').last)
        .map((filename) => filename.substring(0, filename.length - 4))
        .toList()
      ..sort((first, second) =>
          first.toLowerCase().compareTo(second.toLowerCase()));
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Repeat After Me',
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
                  'Your audio library',
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
                    hintText: 'Search names',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
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
                  child: FutureBuilder<List<String>>(
                    future: _audioNamesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return _MessageState(
                          icon: Icons.warning_amber_rounded,
                          title: 'Could not load audio files',
                          message: 'Check the audio assets and try again.',
                          action: TextButton.icon(
                            onPressed: () => setState(
                              () => _audioNamesFuture = _loadAudioNames(),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        );
                      }

                      final allNames = snapshot.data ?? const <String>[];
                      final query = _query.trim().toLowerCase();
                      final filteredNames = allNames
                          .where((name) => name.toLowerCase().contains(query))
                          .toList();

                      if (filteredNames.isEmpty) {
                        return _MessageState(
                          icon: query.isEmpty
                              ? Icons.library_music_outlined
                              : Icons.search_off,
                          title: query.isEmpty
                              ? 'No audio files yet'
                              : 'No matches found',
                          message: query.isEmpty
                              ? 'Add .m4a files to assets/audio/.'
                              : 'Try a different search.',
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${filteredNames.length} ${filteredNames.length == 1 ? 'ITEM' : 'ITEMS'}',
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
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCEFEB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.graphic_eq,
                                        color: colors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        filteredNames[index],
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: const Color(0xFF18312F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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