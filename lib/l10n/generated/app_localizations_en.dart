// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Repeat After Me';

  @override
  String get audioLibraryTitle => 'Your audio library';

  @override
  String get playAudio => 'Play audio';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get continuousPlay => 'Play continuously';

  @override
  String get stopPlayback => 'Stop playback';

  @override
  String get audioPlaybackError => 'Could not play this audio file.';

  @override
  String get mainPage => 'Main page';

  @override
  String get settingsPage => 'Settings';

  @override
  String get about => 'About';

  @override
  String get settingsAudioFolder => 'Audio folder';

  @override
  String get settingsAudioFolderNotSet => 'Not set';

  @override
  String get settingsChooseAudioFolder => 'Choose folder';

  @override
  String get settingsClearAudioFolder => 'Clear folder';

  @override
  String get savedSubdirectoryMissing =>
      'The saved folder is unavailable. Showing /; choose a folder again.';

  @override
  String get settingsColorScheme => 'Color scheme';

  @override
  String get settingsCustom => 'Custom';

  @override
  String get settingsFollowSystem => 'Follow system';

  @override
  String get settingsSeedColor => 'Seed color';

  @override
  String get settingsColorVariant => 'Color variant';

  @override
  String get settingsChooseSeedColor => 'Choose seed color';

  @override
  String get settingsVariantFidelity => 'Fidelity';

  @override
  String get settingsVariantTonal => 'Tonal';

  @override
  String get settingsVariantNeutral => 'Neutral';

  @override
  String get settingsVariantMonochrome => 'Monochrome';

  @override
  String get settingsColorDodgerBlue => 'Dodger Blue';

  @override
  String get settingsColorTeal => 'Teal';

  @override
  String get settingsColorAmber => 'Amber';

  @override
  String get settingsColorOrange => 'Orange';

  @override
  String get settingsColorRose => 'Rose';

  @override
  String get settingsColorIndigo => 'Indigo';

  @override
  String get settingsColorGreen => 'Green';

  @override
  String get settingsColorPurple => 'Purple';

  @override
  String get searchHint => 'Filter by name, title, album, or artist';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get loadErrorTitle => 'Could not load audio files';

  @override
  String get loadErrorMessage => 'Check the audio folder and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get updateList => 'Update list';

  @override
  String get listActions => 'List actions';

  @override
  String get rebuildList => 'Rebuild list';

  @override
  String get rebuildListConfirmationMessage =>
      'Rebuilding the list can take a while. Usually, \"Update list\" is all you need. Do you want to continue?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmRebuild => 'Rebuild';

  @override
  String get noFolderTitle => 'No audio folder selected';

  @override
  String get noFolderMessage => 'Choose a folder that contains .m4a files.';

  @override
  String get emptyTitle => 'No audio files yet';

  @override
  String get emptyMessage => 'Add .m4a files directly to the selected folder.';

  @override
  String get noMatchesTitle => 'No matches found';

  @override
  String get noMatchesMessage => 'Try a different search.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }
}
