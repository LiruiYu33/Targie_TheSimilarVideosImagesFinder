# Bilingual Branding Design

## Goal

Rename the project directory to `Targie_TheSimilarVideoFinder`, provide English and Simplified Chinese documentation, and allow the macOS app to switch languages immediately while remembering the last choice.

## Product Behavior

- The first launch uses English.
- A toolbar language menu offers `English` and `简体中文`.
- Switching language updates all application-controlled visible text without restarting.
- The selected language persists with `UserDefaults` and is restored on later launches.
- File names, paths, system error details, and user media are never translated.
- Duplicate-name normalization continues to recognize English and Chinese duplicate suffixes.

## Localization Architecture

- Add an `AppLanguage` value with English and Simplified Chinese cases.
- Add a typed `L10n` string table in Swift so dynamic strings and interpolated counts remain explicit and testable.
- Store the language raw value through `@AppStorage`, defaulting to English.
- Pass the selected language through SwiftUI environment so every view and model-derived label resolves through the same language.
- Convert service errors and scan/evidence labels from stored user-facing strings to language-aware rendering.

## Documentation And Naming

- `README.md` is the English default and links to `README_ZH.md`.
- `README_ZH.md` is Simplified Chinese and links back to `README.md`.
- The built app is named `Targie The Similar Video Finder.app`.
- The project directory is renamed only after tests and packaging succeed, from `寻找相似视频文件` to `Targie_TheSimilarVideoFinder`.

## Verification

- Unit tests verify English is the default, both languages resolve representative static and dynamic strings, and the selected raw value round-trips.
- Existing algorithm, scan, deletion, media, and startup tests continue to pass.
- The rebuilt app launches and remains running with no new crash report.
- Both README files contain reciprocal language links and correct English app paths.
