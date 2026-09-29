# Stylo

A personal wardrobe app built with Flutter. Add photos of your clothes, organize them into categories, and assemble outfits on an adjustable mannequin.

## Features

- A wardrobe stored locally with Hive.
- Photo import and optional background removal.
- An outfit studio with adjustable garment anchors and separate shoe placement.
- Avatar preferences, themes, and outfit history.
- Optional weather suggestions, enabled by the user.

The fitting room is a visual preview, not a measurement or a guarantee of garment fit. On web, clearing browser data can remove the wardrobe; there is no automatic cloud backup. The weather feature sends coordinates to Open-Meteo after location permission is granted.

## Run locally

Install Flutter with Dart 3.10 or newer compatible with `pubspec.yaml`, then run:

```sh
flutter pub get
flutter run -d chrome
```

For Android, connect a device and use `flutter run`. Native builds need the platform SDK. iOS builds require macOS and Xcode.

## Checks

```sh
flutter analyze
flutter test
flutter build web
```

## Project layout

| Folder | Purpose |
| --- | --- |
| `lib/models`, `lib/providers` | Wardrobe data and state |
| `lib/services` | Storage, photo processing, fitting, weather |
| `lib/ui`, `lib/screens` | Screens and reusable UI |
| `assets` | Garment illustrations, mannequin assets, avatar viewer |
| `web` | Web shell and local processing runtime |
| `test` | Widget and garment fitting tests |
| `docs` | Feature notes and device testing history |

## Status and assets

Personal prototype under development. Platform support and photo-processing quality must be checked on target devices. Historical notes in `docs` describe earlier test sessions, not a guarantee for every device.

Third-party assets and runtimes retain their notices in `assets/avatar` and `web/vendor/onnx`. Generated files such as `clothing_item.g.dart` remain generated code; do not edit them manually.
