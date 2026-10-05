import 'package:flutter/material.dart';
import 'package:repeat_after_me/app_settings.dart';
import 'package:repeat_after_me/audio_library_page.dart';
import 'package:repeat_after_me/l10n/generated/app_localizations.dart';
import 'package:repeat_after_me/widgets/app_navigation_drawer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  static const _seedColors = <Color>[
    Color(0xFF1E90FF),
    Color(0xFF008577),
    Color(0xFFFFC107),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      drawer: AppNavigationDrawer(
        selectedDestination: AppDestination.settings,
        onDestinationSelected: (destination) {
          if (destination == AppDestination.main) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => AudioLibraryPage(settings: settings),
              ),
            );
          }
        },
      ),
      appBar: AppBar(title: Text(l10n.settingsPage)),
      body: Align(
        alignment: const Alignment(0, -0.4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                  context,
                  Icons.folder_outlined,
                  l10n.settingsAudioFolder,
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => _audioFolderTile(context, l10n),
                ),
                const SizedBox(height: 24),
                _sectionHeader(
                  context,
                  Icons.wallpaper_outlined,
                  l10n.settingsColorScheme,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.settingsCustom),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.settingsFollowSystem),
                    ),
                  ],
                  selected: {settings.followSystemColors},
                  onSelectionChanged: (selection) {
                    settings.setFollowSystemColors(selection.first);
                  },
                ),
                if (!settings.followSystemColors) ...[
                  const SizedBox(height: 24),
                  _sectionHeader(
                    context,
                    Icons.color_lens_outlined,
                    l10n.settingsSeedColor,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showSeedColorPicker(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: settings.seedColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(_seedColorName(l10n, settings.seedColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionHeader(
                    context,
                    Icons.mood_outlined,
                    l10n.settingsColorVariant,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<DynamicSchemeVariant>(
                      segments: [
                        ButtonSegment(
                          value: DynamicSchemeVariant.fidelity,
                          label: Text(l10n.settingsVariantFidelity),
                        ),
                        ButtonSegment(
                          value: DynamicSchemeVariant.tonalSpot,
                          label: Text(l10n.settingsVariantTonal),
                        ),
                        ButtonSegment(
                          value: DynamicSchemeVariant.neutral,
                          label: Text(l10n.settingsVariantNeutral),
                        ),
                        ButtonSegment(
                          value: DynamicSchemeVariant.monochrome,
                          label: Text(l10n.settingsVariantMonochrome),
                        ),
                      ],
                      selected: {settings.schemeVariant},
                      onSelectionChanged: (selection) {
                        settings.setSchemeVariant(selection.first);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _audioFolderTile(BuildContext context, AppLocalizations l10n) {
    final name = settings.audioDirectoryName;
    return ListTile(
      onTap: settings.pickAudioDirectory,
      title: Text(name ?? l10n.settingsAudioFolderNotSet),
      subtitle: Text(l10n.settingsChooseAudioFolder),
      trailing: name == null
          ? null
          : IconButton(
              tooltip: l10n.settingsClearAudioFolder,
              onPressed: settings.clearAudioDirectory,
              icon: const Icon(Icons.close),
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _seedColorName(AppLocalizations l10n, Color color) {
    return switch (color.toARGB32()) {
      0xFF1E90FF => l10n.settingsColorDodgerBlue,
      0xFF008577 => l10n.settingsColorTeal,
      0xFFFFC107 => l10n.settingsColorAmber,
      0xFFFF5722 => l10n.settingsColorOrange,
      0xFFE91E63 => l10n.settingsColorRose,
      0xFF3F51B5 => l10n.settingsColorIndigo,
      0xFF4CAF50 => l10n.settingsColorGreen,
      0xFF9C27B0 => l10n.settingsColorPurple,
      _ => '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
    };
  }

  Future<void> _showSeedColorPicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsChooseSeedColor),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _seedColors.map((color) {
            final selected = color == settings.seedColor;
            return Tooltip(
              message: _seedColorName(l10n, color),
              child: InkWell(
                onTap: () => Navigator.of(context).pop(color),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
        ],
      ),
    );
    if (selectedColor != null) {
      await settings.setSeedColor(selectedColor);
    }
  }
}
