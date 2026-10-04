import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._preferences)
    : _followSystemColors =
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
  static const _defaultSeedColorValue = 0xFF1E90FF;

  final SharedPreferences _preferences;
  bool _followSystemColors;
  Color _seedColor;
  DynamicSchemeVariant _schemeVariant;

  bool get followSystemColors => _followSystemColors;
  Color get seedColor => _seedColor;
  DynamicSchemeVariant get schemeVariant => _schemeVariant;

  static Future<AppSettings> load() async {
    return AppSettings._(await SharedPreferences.getInstance());
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
