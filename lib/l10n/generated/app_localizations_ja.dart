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
  String get playAudio => '音声を再生';

  @override
  String get pauseAudio => '音声を一時停止';

  @override
  String get continuousPlay => '連続再生';

  @override
  String get stopPlayback => '再生を停止';

  @override
  String get audioPlaybackError => 'この音声ファイルを再生できません。';

  @override
  String get mainPage => 'メインページ';

  @override
  String get settingsPage => '設定';

  @override
  String get about => 'バージョン情報';

  @override
  String get settingsColorScheme => '配色';

  @override
  String get settingsCustom => 'カスタム';

  @override
  String get settingsFollowSystem => 'システムに合わせる';

  @override
  String get settingsSeedColor => 'シードカラー';

  @override
  String get settingsColorVariant => 'カラーバリエーション';

  @override
  String get settingsChooseSeedColor => 'シードカラーを選択';

  @override
  String get settingsVariantFidelity => '忠実';

  @override
  String get settingsVariantTonal => 'トーン';

  @override
  String get settingsVariantNeutral => 'ニュートラル';

  @override
  String get settingsVariantMonochrome => 'モノクロ';

  @override
  String get settingsColorDodgerBlue => 'ドジャーブルー';

  @override
  String get settingsColorTeal => 'ティール';

  @override
  String get settingsColorAmber => 'アンバー';

  @override
  String get settingsColorOrange => 'オレンジ';

  @override
  String get settingsColorRose => 'ローズ';

  @override
  String get settingsColorIndigo => 'インディゴ';

  @override
  String get settingsColorGreen => 'グリーン';

  @override
  String get settingsColorPurple => 'パープル';

  @override
  String get searchHint => '絞り込み検索';

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
