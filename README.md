# Repeat After Me

An audio phrase library for language study. The app lists the names of `.m4a` files in `assets/audio/` and lets you search them.

## Features

- Lists audio filenames without their `.m4a` extension
- Filters names incrementally as you type
- Plays an audio file when its list item is selected; select it again to pause
- Plays the list continuously with the repeat button next to the title, and stops with the stop button: it starts from the most recently played item (or the first one), plays top to bottom with a 1-second gap after each item, and loops back to the top; item play buttons are disabled meanwhile
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

Build output is written to `build/web/`. Audio playback on the web depends on the browser's M4A/AAC support.

## Screenshots

Here are some screenshots of the app.

![](images/combined.png)
**App Screenshot**

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
