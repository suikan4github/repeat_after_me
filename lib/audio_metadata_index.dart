import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AudioMetadataFile {
  const AudioMetadataFile({
    required this.uri,
    required this.name,
    required this.length,
    required this.lastModified,
  });

  final String uri;
  final String name;
  final int length;
  final int lastModified;
}

class AudioMetadataTags {
  const AudioMetadataTags({this.title, this.album, this.artist});

  final String? title;
  final String? album;
  final String? artist;

  bool matches(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return true;
    return [
      title,
      album,
      artist,
    ].any(
      (value) => value != null && matchesSearchQuery(value, normalizedQuery),
    );
  }
}

bool matchesSearchQuery(String value, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  if (!normalizedQuery.contains('*') && !normalizedQuery.contains('?')) {
    return value.toLowerCase().contains(normalizedQuery);
  }

  final pattern = normalizedQuery.runes.map((rune) {
    final character = String.fromCharCode(rune);
    return switch (character) {
      '*' => r'[\s\S]*',
      '?' => r'[\s\S]',
      _ => RegExp.escape(character),
    };
  }).join();
  return RegExp(pattern, unicode: true).hasMatch(value.toLowerCase());
}

typedef AudioMetadataExtractor =
    Future<Map<String, AudioMetadataTags>> Function(
      List<AudioMetadataFile> files,
    );

class AudioMetadataIndex {
  AudioMetadataIndex({
    DatabaseFactory? databaseFactory,
    String? databasePath,
    this.extractorVersion = currentExtractorVersion,
  }) : _databaseFactory = databaseFactory,
       _databasePath = databasePath;

  static const schemaVersion = 1;
  static const currentExtractorVersion = 1;
  static const _tableName = 'audio_metadata';

  final DatabaseFactory? _databaseFactory;
  final String? _databasePath;
  final int extractorVersion;
  Future<Database>? _databaseFuture;

  Future<Map<String, AudioMetadataTags>> synchronizeDirectory({
    required String directoryUri,
    required List<AudioMetadataFile> files,
    required AudioMetadataExtractor extractMetadata,
  }) async {
    final database = await _database();
    final existingRows = await database.query(
      _tableName,
      where: 'directory_uri = ?',
      whereArgs: [directoryUri],
    );
    final existingByUri = {
      for (final row in existingRows) row['file_uri']! as String: row,
    };
    final currentUris = files.map((file) => file.uri).toSet();
    final filesToExtract = files.where((file) {
      final row = existingByUri[file.uri];
      return row == null ||
          row['file_size'] != file.length ||
          row['last_modified'] != file.lastModified ||
          row['extractor_version'] != extractorVersion;
    }).toList();
    final filesToExtractByUri = {for (final file in filesToExtract) file.uri};
    final extracted = filesToExtract.isEmpty
        ? const <String, AudioMetadataTags>{}
        : await extractMetadata(filesToExtract);
    final tagsByUri = <String, AudioMetadataTags>{};

    await database.transaction((transaction) async {
      for (final file in files) {
        final tags =
            extracted[file.uri] ??
            (filesToExtractByUri.contains(file.uri)
                ? const AudioMetadataTags()
                : _tagsFromRow(existingByUri[file.uri]));
        tagsByUri[file.uri] = tags;
        await transaction.insert(_tableName, {
          'directory_uri': directoryUri,
          'file_uri': file.uri,
          'file_size': file.length,
          'last_modified': file.lastModified,
          'extractor_version': extractorVersion,
          'title': tags.title,
          'album': tags.album,
          'artist': tags.artist,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final oldUri in existingByUri.keys.where(
        (uri) => !currentUris.contains(uri),
      )) {
        await transaction.delete(
          _tableName,
          where: 'directory_uri = ? AND file_uri = ?',
          whereArgs: [directoryUri, oldUri],
        );
      }
    });

    return tagsByUri;
  }

  Future<void> invalidateDirectory(String directoryUri) async {
    final database = await _database();
    await database.delete(
      _tableName,
      where: 'directory_uri = ?',
      whereArgs: [directoryUri],
    );
  }

  Future<void> close() async {
    final databaseFuture = _databaseFuture;
    if (databaseFuture == null) return;
    await (await databaseFuture).close();
    _databaseFuture = null;
  }

  Future<Database> _database() => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final databasePath =
        _databasePath ??
        '${(await getApplicationSupportDirectory()).path}/audio_metadata.sqlite';
    return (_databaseFactory ?? databaseFactory).openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (database, version) async {
          await database.execute('''
            CREATE TABLE $_tableName (
              directory_uri TEXT NOT NULL,
              file_uri TEXT NOT NULL PRIMARY KEY,
              file_size INTEGER NOT NULL,
              last_modified INTEGER NOT NULL,
              extractor_version INTEGER NOT NULL,
              title TEXT,
              album TEXT,
              artist TEXT
            )
          ''');
          await database.execute(
            'CREATE INDEX audio_metadata_directory_uri_idx '
            'ON $_tableName(directory_uri)',
          );
        },
      ),
    );
  }

  AudioMetadataTags _tagsFromRow(Map<String, Object?>? row) =>
      AudioMetadataTags(
        title: row?['title'] as String?,
        album: row?['album'] as String?,
        artist: row?['artist'] as String?,
      );
}
