# Repeat After Me

An audio phrase library for language study. The app lists the names of `.m4a` files in `assets/audio/` and lets you search them.

## Features

- Lists audio filenames without their `.m4a` extension
- Filters names incrementally as you type
- Uses Japanese when the system language is Japanese, and English otherwise
- Supports a custom seed color, color scheme variant, or system colors
- Saves appearance settings on the device and restores them on the next launch

## Adding Audio Files

Add `.m4a` files to `assets/audio/`. For example:

```text
assets/audio/
├── hello.m4a
└── good_morning.m4a
```

The app displays these files as `hello` and `good_morning`. Restart the Flutter app or rebuild it after adding files.

## Development

Run these commands in an environment with the Flutter SDK installed:

```sh
flutter pub get
flutter run
```

Run tests:

```sh
flutter test
```

Build for the web:

```sh
flutter build web
```

Build output is written to `build/web/`.
