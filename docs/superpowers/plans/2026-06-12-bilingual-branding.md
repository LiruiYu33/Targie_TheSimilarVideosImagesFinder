# Bilingual Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add persistent runtime English/Simplified Chinese switching, split documentation by language, rename the app bundle, and rename the project directory.

**Architecture:** A typed `AppLanguage` and `L10n` table own application strings. `@AppStorage` at the root view persists the language and injects it through SwiftUI environment; views render through `L10n`, while models expose semantic values instead of fixed Chinese labels.

**Tech Stack:** Swift 6, SwiftUI, AppStorage/UserDefaults, XCTest, SwiftPM, bash.

---

### Task 1: Add language model and string table

**Files:**
- Create: `Sources/SimilarVideoFinder/Support/Localization.swift`
- Create: `Tests/SimilarVideoFinderTests/LocalizationTests.swift`

- [ ] Write tests asserting `.english` is the default, language raw values round-trip, and representative static/dynamic strings differ correctly.
- [ ] Run `swift test --filter LocalizationTests` and verify failure because localization types are absent.
- [ ] Implement `AppLanguage`, environment key, and typed `L10n` accessors.
- [ ] Re-run the focused tests and verify they pass.

### Task 2: Localize the full UI and errors

**Files:**
- Modify: `Sources/SimilarVideoFinder/App/SimilarVideoFinderApp.swift`
- Modify: `Sources/SimilarVideoFinder/Models/VideoModels.swift`
- Modify: `Sources/SimilarVideoFinder/Services/DeletionService.swift`
- Modify: `Sources/SimilarVideoFinder/Services/VideoScanner.swift`
- Modify: `Sources/SimilarVideoFinder/Stores/ScanViewModel.swift`
- Modify: `Sources/SimilarVideoFinder/Support/Formatters.swift`
- Modify: `Sources/SimilarVideoFinder/Views/*.swift`
- Modify: `Tests/SimilarVideoFinderTests/AppSmokeTests.swift`

- [ ] Add failing tests for English display name and semantic error values.
- [ ] Replace hard-coded UI strings with language-aware `L10n` calls.
- [ ] Add the toolbar language picker backed by `@AppStorage`, defaulting to English.
- [ ] Ensure scan stages, evidence, unknown values, errors, file panel title, delete dialogs, and dynamic counts all switch language.
- [ ] Run the complete test suite.

### Task 3: Split documentation and rename build product

**Files:**
- Rewrite: `README.md`
- Create: `README_ZH.md`
- Modify: `script/build_app.sh`
- Modify: `script/build_and_run.sh`

- [ ] Write English README content and reciprocal language links.
- [ ] Write Simplified Chinese README content and reciprocal language links.
- [ ] Change generated bundle name to `Targie The Similar Video Finder.app` while keeping executable/product identity stable.
- [ ] Build and launch the renamed app; verify the process remains running and no crash report appears.

### Task 4: Rename the project directory

**Files:**
- Move: `/Users/aaronyu/Desktop/寻找相似视频文件` to `/Users/aaronyu/Desktop/Targie_TheSimilarVideoFinder`

- [ ] Stop the running app and local brainstorming server.
- [ ] Confirm the target directory does not exist.
- [ ] Rename the directory from its parent directory.
- [ ] Re-run `swift test` and `./script/build_app.sh` from the new path.
- [ ] Report the final project and app paths.
