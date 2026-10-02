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
  String get mainPage => 'Main page';

  @override
  String get searchHint => 'Search names';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get loadErrorTitle => 'Could not load audio files';

  @override
  String get loadErrorMessage => 'Check the audio assets and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get emptyTitle => 'No audio files yet';

  @override
  String get emptyMessage => 'Add .m4a files to assets/audio/.';

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
