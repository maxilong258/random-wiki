# Random Wiki

[简体中文](README.md) | **English**

A shared repository for the Flutter app and a separate Random Wiki website.

## Projects

- [flutter/](flutter/README.en.md): the existing Flutter app, including source code, tests, platform projects, assets, and development documentation.
- [web/](web/README.md): reserved for the independent website; implementation has not started.

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

## License

[MIT](LICENSE)
