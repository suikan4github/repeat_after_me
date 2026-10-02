# Repeat After Me

語学学習用の音声フレーズ一覧アプリです。`assets/audio/` にある `.m4a` ファイル名を一覧表示し、検索できます。

## 機能

- 音声ファイル名から拡張子を除いて一覧表示
- 名前のインクリメンタル検索
- システム言語が日本語の場合は日本語、それ以外は英語で表示
- シードカラー、カラーバリエーション、システム配色の設定
- 外観設定を端末に保存し、次回起動時に復元

## 音声ファイルの追加

`.m4a` ファイルを `assets/audio/` に追加してください。例:

```text
assets/audio/
├── hello.m4a
└── good_morning.m4a
```

アプリには `hello`、`good_morning` として表示されます。追加後に Flutter の実行またはビルドをやり直してください。

## 開発

Flutter SDK をインストールした環境で実行します。

```sh
flutter pub get
flutter run
```

テスト:

```sh
flutter test
```

Web ビルド:

```sh
flutter build web
```

生成物は `build/web/` に出力されます。
