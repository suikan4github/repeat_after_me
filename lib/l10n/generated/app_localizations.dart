import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Repeat After Me'**
  String get appTitle;

  /// No description provided for @audioLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your audio library'**
  String get audioLibraryTitle;

  /// No description provided for @playAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get playAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In en, this message translates to:
  /// **'Pause audio'**
  String get pauseAudio;

  /// No description provided for @continuousPlay.
  ///
  /// In en, this message translates to:
  /// **'Play continuously'**
  String get continuousPlay;

  /// No description provided for @stopPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stop playback'**
  String get stopPlayback;

  /// No description provided for @audioPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'Could not play this audio file.'**
  String get audioPlaybackError;

  /// No description provided for @mainPage.
  ///
  /// In en, this message translates to:
  /// **'Main page'**
  String get mainPage;

  /// No description provided for @settingsPage.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPage;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @settingsAudioFolder.
  ///
  /// In en, this message translates to:
  /// **'Audio folder'**
  String get settingsAudioFolder;

  /// No description provided for @settingsAudioFolderNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsAudioFolderNotSet;

  /// No description provided for @settingsChooseAudioFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get settingsChooseAudioFolder;

  /// No description provided for @settingsClearAudioFolder.
  ///
  /// In en, this message translates to:
  /// **'Clear folder'**
  String get settingsClearAudioFolder;

  /// No description provided for @settingsColorScheme.
  ///
  /// In en, this message translates to:
  /// **'Color scheme'**
  String get settingsColorScheme;

  /// No description provided for @settingsCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsCustom;

  /// No description provided for @settingsFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get settingsFollowSystem;

  /// No description provided for @settingsSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Seed color'**
  String get settingsSeedColor;

  /// No description provided for @settingsColorVariant.
  ///
  /// In en, this message translates to:
  /// **'Color variant'**
  String get settingsColorVariant;

  /// No description provided for @settingsChooseSeedColor.
  ///
  /// In en, this message translates to:
  /// **'Choose seed color'**
  String get settingsChooseSeedColor;

  /// No description provided for @settingsVariantFidelity.
  ///
  /// In en, this message translates to:
  /// **'Fidelity'**
  String get settingsVariantFidelity;

  /// No description provided for @settingsVariantTonal.
  ///
  /// In en, this message translates to:
  /// **'Tonal'**
  String get settingsVariantTonal;

  /// No description provided for @settingsVariantNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get settingsVariantNeutral;

  /// No description provided for @settingsVariantMonochrome.
  ///
  /// In en, this message translates to:
  /// **'Monochrome'**
  String get settingsVariantMonochrome;

  /// No description provided for @settingsColorDodgerBlue.
  ///
  /// In en, this message translates to:
  /// **'Dodger Blue'**
  String get settingsColorDodgerBlue;

  /// No description provided for @settingsColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get settingsColorTeal;

  /// No description provided for @settingsColorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get settingsColorAmber;

  /// No description provided for @settingsColorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get settingsColorOrange;

  /// No description provided for @settingsColorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get settingsColorRose;

  /// No description provided for @settingsColorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get settingsColorIndigo;

  /// No description provided for @settingsColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get settingsColorGreen;

  /// No description provided for @settingsColorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get settingsColorPurple;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @loadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load audio files'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Check the audio folder and try again.'**
  String get loadErrorMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get refresh;

  /// No description provided for @noFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'No audio folder selected'**
  String get noFolderTitle;

  /// No description provided for @noFolderMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder that contains .m4a files.'**
  String get noFolderMessage;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No audio files yet'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add .m4a files directly to the selected folder.'**
  String get emptyMessage;

  /// No description provided for @noMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesTitle;

  /// No description provided for @noMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different search.'**
  String get noMatchesMessage;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items} one{1 item} other{{count} items}}'**
  String itemCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
