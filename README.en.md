# Random Wiki

[简体中文](README.md) | **English**

A swipeable random Wikipedia reader for Android. Not affiliated with the Wikimedia Foundation.

## Download

- [Download APK (recommended, 64-bit phones)](https://github.com/maxilong258/random-wiki/releases/latest/download/random-wiki-arm64-v8a.apk)
- [All versions and ABIs](https://github.com/maxilong258/random-wiki/releases)

Release assets include the version in the filename, for example `random-wiki-1.0.4-arm64-v8a.apk`:

- **arm64-v8a**: almost all current phones
- **armeabi-v7a**: older 32-bit phones
- **x86_64**: desktop emulators

Allow installation from unknown sources if Android asks. If the app is on Google Play, you can also search for **Random Wiki**.

## Screenshots

<p>
  <img src="store/screenshots/01-home.png" width="180" alt="Home" />
  <img src="store/screenshots/02-article.png" width="180" alt="Article" />
  <img src="store/screenshots/03-history.png" width="180" alt="History" />
  <img src="store/screenshots/04-settings.png" width="180" alt="Settings" />
</p>

## Features

- Swipe up and down for a random article
- Chinese / English content and UI
- Favorites and reading history
- Light, dark, or follow system
- Open the original Wikipedia page

## Content

Article text and images come from [Wikipedia](https://www.wikipedia.org/), licensed under [CC BY-SA](https://creativecommons.org/licenses/by-sa/4.0/). The app shows the source language, for example `Wikipedia · EN`.

## Run from source

Install [Flutter](https://flutter.dev/docs/get-started/install) first.

```bash
git clone https://github.com/maxilong258/random-wiki.git
cd random-wiki
flutter pub get
flutter run
```

## License

[MIT](LICENSE)
