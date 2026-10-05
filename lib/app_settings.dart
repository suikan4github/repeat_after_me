import 'package:flutter/material.dart';
import 'package:saf_util/saf_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._preferences)
    : _audioDirectoryUri = _preferences.getString(_audioDirectoryUriKey),
      _audioDirectoryName = _preferences.getString(_audioDirectoryNameKey),
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
  static const _defaultSeedColorValue = 0xFF1E90FF;

  final SharedPreferences _preferences;
  final _safUtil = SafUtil();
  String? _audioDirectoryUri;
  String? _audioDirectoryName;
  bool _followSystemColors;
  Color _seedColor;
  DynamicSchemeVariant _schemeVariant;

  /// SAF tree URI of the folder holding the audio files, or null if unset.
  String? get audioDirectoryUri => _audioDirectoryUri;
  String? get audioDirectoryName => _audioDirectoryName;
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
    notifyListeners();
    await _preferences.setString(_audioDirectoryUriKey, directory.uri);
    await _preferences.setString(_audioDirectoryNameKey, directory.name);
    if (previousUri != null && previousUri != directory.uri) {
      await _releasePermission(previousUri);
    }
  }

  Future<void> clearAudioDirectory() async {
    final previousUri = _audioDirectoryUri;
    if (previousUri == null) return;
    _audioDirectoryUri = null;
    _audioDirectoryName = null;
    notifyListeners();
    await _preferences.remove(_audioDirectoryUriKey);
    await _preferences.remove(_audioDirectoryNameKey);
    await _releasePermission(previousUri);
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
