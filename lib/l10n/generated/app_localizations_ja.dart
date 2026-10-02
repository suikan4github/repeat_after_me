// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'リピート・アフター・ミー';

  @override
  String get audioLibraryTitle => '音声ライブラリ';

  @override
  String get searchHint => '名前を検索';

  @override
  String get clearSearch => '検索をクリア';

  @override
  String get loadErrorTitle => '音声ファイルを読み込めません';

  @override
  String get loadErrorMessage => '音声アセットを確認して、もう一度お試しください。';

  @override
  String get retry => '再試行';

  @override
  String get emptyTitle => '音声ファイルはまだありません';

  @override
  String get emptyMessage => 'assets/audio/ に .m4a ファイルを追加してください。';

  @override
  String get noMatchesTitle => '一致する項目がありません';

  @override
  String get noMatchesMessage => '別のキーワードで検索してください。';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
    );
    return '$_temp0';
  }
}
