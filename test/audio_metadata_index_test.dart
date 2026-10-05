import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:repeat_after_me/audio_metadata_index.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late String databasePath;
  late AudioMetadataIndex index;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'audio-metadata-index-test',
    );
    databasePath = '${temporaryDirectory.path}/metadata.sqlite';
    index = AudioMetadataIndex(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
    );
  });

  tearDown(() async {
    await index.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'reuses unchanged tags and re-extracts changed or removed files',
    () async {
      const original = AudioMetadataFile(
        uri: 'content://audio/track.m4a',
        name: 'track.m4a',
        length: 100,
        lastModified: 10,
      );
      var extractionCount = 0;

      Future<Map<String, AudioMetadataTags>> extract(
        List<AudioMetadataFile> files,
      ) async {
        extractionCount += files.length;
        return {
          for (final file in files)
            file.uri: AudioMetadataTags(
              title: 'Title $extractionCount',
              album: 'Album',
              artist: 'Artist',
            ),
        };
      }

      var indexed = await index.synchronizeDirectory(
        directoryUri: 'content://audio',
        files: const [original],
        extractMetadata: extract,
      );
      expect(indexed[original.uri]?.title, 'Title 1');

      indexed = await index.synchronizeDirectory(
        directoryUri: 'content://audio',
        files: const [original],
        extractMetadata: (_) async => throw StateError('should reuse metadata'),
      );
      expect(indexed[original.uri]?.title, 'Title 1');
      expect(extractionCount, 1);

      const changed = AudioMetadataFile(
        uri: 'content://audio/track.m4a',
        name: 'track.m4a',
        length: 120,
        lastModified: 11,
      );
      indexed = await index.synchronizeDirectory(
        directoryUri: 'content://audio',
        files: const [changed],
        extractMetadata: extract,
      );
      expect(indexed[changed.uri]?.title, 'Title 2');
      expect(extractionCount, 2);

      await index.synchronizeDirectory(
        directoryUri: 'content://audio',
        files: const [],
        extractMetadata: (_) async => const {},
      );
      indexed = await index.synchronizeDirectory(
        directoryUri: 'content://audio',
        files: const [changed],
        extractMetadata: extract,
      );
      expect(indexed[changed.uri]?.title, 'Title 3');
      expect(extractionCount, 3);
    },
  );

  test('re-extracts cached tags when the extractor version changes', () async {
    const file = AudioMetadataFile(
      uri: 'content://audio/track.m4a',
      name: 'track.m4a',
      length: 100,
      lastModified: 10,
    );
    await index.synchronizeDirectory(
      directoryUri: 'content://audio',
      files: const [file],
      extractMetadata: (_) async => {
        file.uri: const AudioMetadataTags(title: 'Old title'),
      },
    );
    await index.close();

    index = AudioMetadataIndex(
      databaseFactory: databaseFactoryFfi,
      databasePath: databasePath,
      extractorVersion: AudioMetadataIndex.currentExtractorVersion + 1,
    );
    final updated = await index.synchronizeDirectory(
      directoryUri: 'content://audio',
      files: const [file],
      extractMetadata: (_) async => {
        file.uri: const AudioMetadataTags(title: 'New title'),
      },
    );

    expect(updated[file.uri]?.title, 'New title');
  });
}
