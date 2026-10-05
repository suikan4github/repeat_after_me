import 'package:flutter/material.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._preferences)
    : _audioDirectoryUri = _preferences.getString(_audioDirectoryUriKey),
      _audioDirectoryName = _preferences.getString(_audioDirectoryNameKey),
      _audioSubdirectoryPath =
          _preferences.getString(_audioSubdirectoryPathKey) ?? '/',
      _searchQuery = _preferences.getString(_searchQueryKey) ?? '',
      _searchHistory = List.of(
        _preferences.getStringList(_searchHistoryKey) ?? const <String>[],
      ),
      _followSystemColors =
          _preferences.getBool(_followSystemColorsKey) ?? false,
      _seedColor = Color(
        _preferences.getInt(_seedColorKey) ?? _defaultSeedColorValue,
      ),
      _schemeVariant = DynamicSchemeVariant.values.firstWhere(
        (variant) => variant.name == _preferences.getString(_schemeVariantKey),
        orElse: () => DynamicSchemeVariant.tonalSpot,
      );

  static const _followSystemColorsKey = 'settings.followSystemColors';
  static const _seedColorKey = 'settings.seedColor';
  static const _schemeVariantKey = 'settings.schemeVariant';
  static const _audioDirectoryUriKey = 'settings.audioDirectoryUri';
  static const _audioDirectoryNameKey = 'settings.audioDirectoryName';
  static const _audioSubdirectoryPathKey = 'settings.audioSubdirectoryPath';
  static const _searchQueryKey = 'settings.searchQuery';
  static const _searchHistoryKey = 'settings.searchHistory';
  static const maxSearchHistory = 5;
  static const _defaultSeedColorValue = 0xFF1E90FF;

  final SharedPreferences _preferences;
  final _safUtil = SafUtil();
  String? _audioDirectoryUri;
  String? _audioDirectoryName;
  String _audioSubdirectoryPath;
  String _searchQuery;
  final List<String> _searchHistory;
  bool _followSystemColors;
  Color _seedColor;
  DynamicSchemeVariant _schemeVariant;

  /// SAF tree URI of the folder holding the audio files, or null if unset.
  String? get audioDirectoryUri => _audioDirectoryUri;
  String? get audioDirectoryName => _audioDirectoryName;
  String get audioSubdirectoryPath => _audioSubdirectoryPath;
  String get searchQuery => _searchQuery;

  /// Recent search words, newest first.
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  bool get followSystemColors => _followSystemColors;
  Color get seedColor => _seedColor;
  DynamicSchemeVariant get schemeVariant => _schemeVariant;

  static Future<AppSettings> load() async {
    return AppSettings._(await SharedPreferences.getInstance());
  }

  Future<void> pickAudioDirectory() async {
    final directory = await _safUtil.pickDirectory(
      writePermission: false,
      persistablePermission: true,
    );
    if (directory == null) return;

    final previousUri = _audioDirectoryUri;
    _audioDirectoryUri = directory.uri;
    _audioDirectoryName = directory.name;
    _audioSubdirectoryPath = '/';
    notifyListeners();
    await _preferences.setString(_audioDirectoryUriKey, directory.uri);
    await _preferences.setString(_audioDirectoryNameKey, directory.name);
    await _preferences.setString(_audioSubdirectoryPathKey, '/');
    if (previousUri != null && previousUri != directory.uri) {
      await _releasePermission(previousUri);
    }
  }

  Future<void> clearAudioDirectory() async {
    final previousUri = _audioDirectoryUri;
    if (previousUri == null) return;
    _audioDirectoryUri = null;
    _audioDirectoryName = null;
    _audioSubdirectoryPath = '/';
    notifyListeners();
    await _preferences.remove(_audioDirectoryUriKey);
    await _preferences.remove(_audioDirectoryNameKey);
    await _preferences.setString(_audioSubdirectoryPathKey, '/');
    await _releasePermission(previousUri);
  }

  Future<void> setAudioSubdirectoryPath(String value) async {
    final path = value.isEmpty ? '/' : value;
    if (_audioSubdirectoryPath == path) return;
    _audioSubdirectoryPath = path;
    notifyListeners();
    await _preferences.setString(_audioSubdirectoryPathKey, path);
  }

  Future<void> setSearchQuery(String value) async {
    if (_searchQuery == value) return;
    _searchQuery = value;
    await _preferences.setString(_searchQueryKey, value);
  }

  Future<void> addSearchHistory(String value) async {
    final word = value.trim();
    if (word.isEmpty) return;
    _searchHistory
      ..remove(word)
      ..insert(0, word);
    if (_searchHistory.length > maxSearchHistory) {
      _searchHistory.removeRange(maxSearchHistory, _searchHistory.length);
    }
    await _preferences.setStringList(_searchHistoryKey, _searchHistory);
  }

  Future<void> _releasePermission(String uri) async {
    try {
      await _safUtil.releasePersistedPermission(uri);
    } catch (error) {
      debugPrint('Releasing folder permission failed: $error');
    }
  }

  Future<void> setFollowSystemColors(bool value) async {
    if (_followSystemColors == value) return;
    _followSystemColors = value;
    notifyListeners();
    await _preferences.setBool(_followSystemColorsKey, value);
  }

  Future<void> setSeedColor(Color value) async {
    if (_seedColor == value) return;
    _seedColor = value;
    notifyListeners();
    await _preferences.setInt(_seedColorKey, value.toARGB32());
  }

  Future<void> setSchemeVariant(DynamicSchemeVariant value) async {
    if (_schemeVariant == value) return;
    _schemeVariant = value;
    notifyListeners();
    await _preferences.setString(_schemeVariantKey, value.name);
  }

  ThemeData theme({
    required Brightness brightness,
    ColorScheme? systemColorScheme,
  }) {
    final colorScheme = _followSystemColors && systemColorScheme != null
        ? systemColorScheme
        : ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: brightness,
            dynamicSchemeVariant: _schemeVariant,
          );
    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
