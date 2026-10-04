# Repeat After Me

An audio phrase library for language study. The app lists the names of `.m4a` files in `assets/audio/` and plays them when you tap them. You can also filter the list by name.

## Features

The app provides the following features:

- Lists audio filenames without their `.m4a` extension
- Filters names incrementally as you type
- Plays an audio file when you tap its list item; tap it again to pause
- Plays the list continuously with the repeat button next to the title, and stops with the stop button: it starts from the most recently played item and plays from top to bottom. After the last item, it returns to the first.
- Continuous playback stops automatically 15 minutes after it starts
- Uses Japanese when the system language is Japanese, and English otherwise
- Supports a custom seed color, color scheme variant, or system colors

## Adding Audio Files

The audio folder is empty by default. Add `.m4a` files to `assets/audio/`.

For example:

```text
assets/audio/
├── hello.m4a
└── good_morning.m4a
```

The app displays these files as `hello` and `good_morning`. Rebuild the app after adding files.

## Development

Run these commands in an environment with the Flutter SDK installed. In VS Code, using the Dev Container sets up the development environment automatically.

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
