# Random Wiki

[简体中文](README.md) | **English**

A shared repository for the Flutter app and a separate Random Wiki website.

## Projects

- [flutter/](flutter/README.en.md): the existing Flutter app, including source code, tests, platform projects, assets, and development documentation.
- [web/](web/README.md): an independent Next.js reader with random articles, on-this-day events, travel guides, local favorites and history, fifteen languages, and theme settings.

The existing Flutter Web platform files are under `flutter/web/`. They are separate from the new website in the top-level `web/` directory.

Both projects share the Git repository and license at the repository root. Source code, dependencies, and build configuration belong in each project directory.

## Run the Flutter app

From the repository root:

```bash
cd flutter
./dev.sh
```

Alternatively, run `flutter pub get` and `flutter run` inside `flutter/`.

See the [Flutter README](flutter/README.en.md) for downloads and screenshots, and the [development guide](flutter/DEVELOPMENT.md) for development and release instructions.

## Run the website

```bash
cd web
pnpm install --frozen-lockfile
./dev.sh
```

Open `http://127.0.0.1:3100`. Public Wikimedia content is fetched directly in the browser. Favorites and history are stored locally. No server or Cloudflare Functions are required. The production build exports static assets to `web/out/`.

## License

[MIT](LICENSE)
