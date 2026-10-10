# Repeat After Me

An audio phrase library for language study. The app lists the names of `.m4a` files in a folder you choose on an Android device and lets you search them.

## Features

The app provides the following features:

- Lists audio filenames without their `.m4a` extension
- Lets you browse nested folders from the selected audio folder
- Filters by filename or the title, album, or artist of `m4a` files as you type
- In search filters, `?` matches any single character and `*` matches any string, including an empty one
- Plays an audio file when you tap its list item; tap it again to pause
- Plays the list continuously with the repeat button next to the title, and stops with the stop button
- Continuous playback stops automatically 15 minutes after it starts
- Uses Japanese when the system language is Japanese, and English otherwise
- Supports a custom seed color, color scheme variant, or system colors

## Adding Audio Files

Copy `.m4a` files into any folder on the device, for example over USB. In the app, open Settings and choose that folder under "Audio folder". The choice is kept after the app restarts.

Use the directory dropdown beside "Your audio library" to browse the selected folder and its subfolders. The selected folder is shown as `/` and subfolders as paths. Only `.m4a` files directly inside the currently selected folder are listed. The app displays `hello.m4a` as `hello`. Use the reload button on the main page after adding files.

Search matches filenames as well as the title, album, and artist information embedded in `m4a` files. This metadata is indexed in the app's private storage and reanalyzed only when a file change is detected. Use the audio actions menu to rebuild the selected folder's index if tags were edited without an updated file timestamp.

Android 11 and later do not allow selecting the storage root or the Download folder itself, so create a subfolder such as `Music/repeat_after_me` and choose that.

## Development

Run these commands in an environment with the Flutter SDK installed. In VS Code, using the Dev Container sets up the development environment automatically.

Run tests:

```sh
flutter test
```
## Screenshots

Here are some screenshots of the app.

![](images/combined.png)
**App Screenshot**

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
