# Targie

[简体中文](README_ZH.md)

> **macOS only.** Targie is a native macOS 14+ application. There is no Windows or Linux build, and none is planned.

Targie finds similar videos in a selected folder by combining file metadata, content hashes, and sampled frame analysis.

> Repository name `Targie_TheSimilarVideoFinder` describes the current scope; the app may grow beyond videos (e.g. similar-image comparison) in the future. The product is always referred to as **Targie**.

## Features

- Recursively scans a folder for common video formats.
- Combines file name, size, duration, resolution, SHA-256, and Vision frame features.
- Groups similar videos for side-by-side review.
- Previews the selected video inside the app.
- Opens videos in the default player or reveals them in Finder.
- Requires an explicit choice between moving a file to Trash and permanent deletion.
- Supports English and Simplified Chinese with instant switching and remembered preference.

## Build (macOS only)

```bash
swift test
./script/build_app.sh
```

The generated application is located at:

```text
dist/Targie.app
```

For development, build and launch with:

```bash
./script/build_and_run.sh
```

The app is ad-hoc signed for local use. Distribution through the internet or the App Store requires a Developer ID, notarization, and the appropriate packaging workflow.
