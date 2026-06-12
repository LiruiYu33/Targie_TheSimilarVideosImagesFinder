# Similar Video Finder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS 14+ app that scans a chosen folder, groups similar videos using metadata and Vision frame features, previews videos, and deletes a user-selected file only after an explicit choice.

**Architecture:** A SwiftPM package contains one executable app target and one test target. Pure scoring/grouping logic remains independent of AVFoundation so it can be tested quickly; platform services handle scanning, frame extraction, playback, Finder integration, and deletion. A release script builds the executable and assembles a double-clickable `.app` bundle in `dist/`.

**Tech Stack:** Swift 6, SwiftUI, AVKit, AVFoundation, Vision, AppKit, CryptoKit, Swift Testing/XCTest, SwiftPM.

---

## File Structure

- `Package.swift`: SwiftPM products, macOS deployment target, source resources, and tests.
- `Sources/SimilarVideoFinder/App/SimilarVideoFinderApp.swift`: app entry point and main window configuration.
- `Sources/SimilarVideoFinder/Models/VideoModels.swift`: video metadata, candidate relation, group, scan issue, and scan state value types.
- `Sources/SimilarVideoFinder/Support/Formatters.swift`: byte, duration, resolution, and percentage formatting.
- `Sources/SimilarVideoFinder/Services/SimilarityScoring.swift`: filename normalization, metadata scoring, weighted final score, and evidence labels.
- `Sources/SimilarVideoFinder/Services/SimilarityGrouper.swift`: threshold graph and connected-component grouping.
- `Sources/SimilarVideoFinder/Services/VideoScanner.swift`: recursive discovery and AVFoundation metadata/thumbnail loading.
- `Sources/SimilarVideoFinder/Services/FileHasher.swift`: cancellable SHA-256 file hashing.
- `Sources/SimilarVideoFinder/Services/FrameFeatureExtractor.swift`: timed frame extraction and Vision feature generation.
- `Sources/SimilarVideoFinder/Services/SimilarityPipeline.swift`: candidate creation, bounded frame analysis, progress, cancellation, and result construction.
- `Sources/SimilarVideoFinder/Services/DeletionService.swift`: Finder reveal, default-player open, recycle, and permanent deletion.
- `Sources/SimilarVideoFinder/Stores/ScanViewModel.swift`: main-actor UI state and workflow orchestration.
- `Sources/SimilarVideoFinder/Views/ContentView.swift`: three-column root composition.
- `Sources/SimilarVideoFinder/Views/SidebarView.swift`: folder selection, progress, threshold, issue summary, and group list.
- `Sources/SimilarVideoFinder/Views/GroupDetailView.swift`: group heading and video comparison grid.
- `Sources/SimilarVideoFinder/Views/VideoCardView.swift`: thumbnail and metadata card.
- `Sources/SimilarVideoFinder/Views/InspectorView.swift`: AVPlayer preview, metadata, Finder/default-player actions, and delete entry point.
- `Sources/SimilarVideoFinder/Views/DeleteConfirmationView.swift`: three-way deletion choice and permanent-delete second confirmation.
- `Tests/SimilarVideoFinderTests/SimilarityScoringTests.swift`: normalization and scoring tests.
- `Tests/SimilarVideoFinderTests/SimilarityGrouperTests.swift`: connected components and post-deletion grouping tests.
- `Tests/SimilarVideoFinderTests/ScanViewModelTests.swift`: cancellation and deletion state tests using injected fakes.
- `Tests/Fixtures/`: small generated video fixtures used only by integration tests.
- `script/build_app.sh`: release build and `.app` assembly.
- `script/build_and_run.sh`: build, assemble, and launch for the Codex Run action.
- `.codex/environments/environment.toml`: project-local run action.
- `.gitignore`: ignores `.build`, `dist`, `.swiftpm`, and `.superpowers` runtime state.

### Task 1: Scaffold the package and app bundle scripts

**Files:**
- Create: `Package.swift`
- Create: `Sources/SimilarVideoFinder/App/SimilarVideoFinderApp.swift`
- Create: `Sources/SimilarVideoFinder/Views/ContentView.swift`
- Create: `script/build_app.sh`
- Create: `script/build_and_run.sh`
- Create: `.codex/environments/environment.toml`
- Create: `.gitignore`

- [ ] **Step 1: Write a failing package smoke test**

Create `Tests/SimilarVideoFinderTests/AppSmokeTests.swift`:

```swift
import XCTest
@testable import SimilarVideoFinder

final class AppSmokeTests: XCTestCase {
    func testPackageLoads() {
        XCTAssertEqual(AppIdentity.displayName, "相似视频查找器")
    }
}
```

- [ ] **Step 2: Run the test and verify RED**

Run: `swift test --filter AppSmokeTests`

Expected: failure because `Package.swift` or `AppIdentity` does not exist.

- [ ] **Step 3: Add the minimal package and app identity**

Define a macOS 14 executable target named `SimilarVideoFinder`, its test target, and:

```swift
enum AppIdentity {
    static let displayName = "相似视频查找器"
    static let bundleIdentifier = "local.aaronyu.SimilarVideoFinder"
}
```

Create a `WindowGroup` app with a temporary `ContentView` and a default size near `1180 x 720`.

- [ ] **Step 4: Add `.app` assembly**

`script/build_app.sh` must run `swift build -c release`, create `dist/相似视频查找器.app/Contents/{MacOS,Resources}`, copy the release executable, write an `Info.plist` with `LSMinimumSystemVersion=14.0`, and mark the executable runnable. `script/build_and_run.sh` calls that script and opens the resulting bundle.

- [ ] **Step 5: Verify GREEN and bundle structure**

Run: `swift test --filter AppSmokeTests && ./script/build_app.sh && test -x 'dist/相似视频查找器.app/Contents/MacOS/SimilarVideoFinder'`

Expected: test passes and the executable exists inside the app bundle.

### Task 2: Define models and pure similarity scoring

**Files:**
- Create: `Sources/SimilarVideoFinder/Models/VideoModels.swift`
- Create: `Sources/SimilarVideoFinder/Services/SimilarityScoring.swift`
- Create: `Tests/SimilarVideoFinderTests/SimilarityScoringTests.swift`

- [ ] **Step 1: Write failing normalization and score tests**

Cover these exact behaviors:

```swift
@Test func stripsCopyAndExportNoise() {
    #expect(FilenameNormalizer.normalize("旅行 copy 2_export.mp4") == "旅行")
}

@Test func exactHashProducesCertainMatch() {
    let result = SimilarityScorer.score(.fixtureA, .fixtureB, hashesMatch: true, frameSimilarity: nil)
    #expect(result.score == 1.0)
    #expect(result.evidence.contains(.identicalContentHash))
}

@Test func metadataAloneCannotClaimHighVisualMatch() {
    let result = SimilarityScorer.score(.fixtureA, .fixtureB, hashesMatch: false, frameSimilarity: nil)
    #expect(result.score < 0.82)
}
```

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter SimilarityScoringTests`

Expected: compile failure for missing models/scorer.

- [ ] **Step 3: Implement minimal value models and scoring**

Define stable UUID-based `VideoItem`, `SimilarityEvidence`, `SimilarityRelation`, and `SimilarityGroup`. Normalize lowercase stems by removing punctuation and suffix noise such as `copy`, `副本`, `export`, and numeric duplicate suffixes. Exact hashes return `1.0`; otherwise combine frame `0.70`, duration `0.12`, dimensions `0.06`, size `0.06`, and name `0.06`, renormalizing only when frame evidence exists.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter SimilarityScoringTests`

Expected: all scoring tests pass.

### Task 3: Group threshold relations safely

**Files:**
- Create: `Sources/SimilarVideoFinder/Services/SimilarityGrouper.swift`
- Create: `Tests/SimilarVideoFinderTests/SimilarityGrouperTests.swift`

- [ ] **Step 1: Write failing grouping tests**

```swift
@Test func chainRelationsFormOneGroup() {
    let groups = SimilarityGrouper.groups(items: [.a, .b, .c], relations: [.ab(0.94), .bc(0.91)], threshold: 0.90)
    #expect(groups.count == 1)
    #expect(Set(groups[0].videos.map(\.id)) == Set([VideoItem.a.id, .b.id, .c.id]))
}

@Test func removingVideoDropsSingletonGroup() {
    let groups = SimilarityGrouper.groups(items: [.a], relations: [], threshold: 0.90)
    #expect(groups.isEmpty)
}
```

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter SimilarityGrouperTests`

Expected: missing `SimilarityGrouper` failure.

- [ ] **Step 3: Implement connected-component grouping**

Filter relations below threshold, build an undirected adjacency map, traverse each component once, discard singleton components, and sort groups by descending maximum relation score then descending reclaimable bytes.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter SimilarityGrouperTests`

Expected: all grouping tests pass.

### Task 4: Scan files and read video metadata

**Files:**
- Create: `Sources/SimilarVideoFinder/Services/VideoScanner.swift`
- Create: `Sources/SimilarVideoFinder/Support/Formatters.swift`
- Create: `Tests/SimilarVideoFinderTests/VideoScannerTests.swift`

- [ ] **Step 1: Write failing discovery tests**

Use a temporary directory containing nested `.mp4`, `.mov`, uppercase `.M4V`, and `.txt` files. Assert recursive discovery returns only the three supported videos in stable path order and reports unreadable entries as `ScanIssue` values rather than throwing away the full scan.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter VideoScannerTests`

Expected: missing scanner types.

- [ ] **Step 3: Implement discovery and AVFoundation metadata loading**

Use `FileManager.DirectoryEnumerator` with hidden/package skipping, supported extensions from `AVURLAsset.audiovisualTypes()` plus common fallbacks, async AVAsset property loading, preferred track transform for displayed dimensions, and an `AVAssetImageGenerator` midpoint thumbnail. Return per-file issues without aborting other files.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter VideoScannerTests`

Expected: discovery tests pass; AVFoundation fixture tests skip only when no fixture is present.

### Task 5: Hash and compare sampled video frames

**Files:**
- Create: `Sources/SimilarVideoFinder/Services/FileHasher.swift`
- Create: `Sources/SimilarVideoFinder/Services/FrameFeatureExtractor.swift`
- Create: `Tests/SimilarVideoFinderTests/FileHasherTests.swift`
- Create: `Tests/SimilarVideoFinderTests/FrameFeatureExtractorTests.swift`

- [ ] **Step 1: Write failing hash and aggregation tests**

Assert identical temporary files have the same SHA-256, changed bytes differ, cancellation throws `CancellationError`, and frame-distance aggregation ignores failed samples but returns `nil` when fewer than two valid comparisons exist.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter 'FileHasherTests|FrameFeatureExtractorTests'`

Expected: missing hasher/extractor failures.

- [ ] **Step 3: Implement bounded platform services**

Stream file bytes through `CryptoKit.SHA256` with cancellation checks. Sample normalized times `[0.08, 0.28, 0.50, 0.72, 0.92]` using `AVAssetImageGenerator`, generate `VNFeaturePrintObservation`, compare matching and adjacent samples, convert Vision distance to a clamped `0...1` similarity, and require at least two valid comparisons.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter 'FileHasherTests|FrameFeatureExtractorTests'`

Expected: all deterministic tests pass.

### Task 6: Orchestrate candidates, progress, cancellation, and errors

**Files:**
- Create: `Sources/SimilarVideoFinder/Services/SimilarityPipeline.swift`
- Create: `Sources/SimilarVideoFinder/Stores/ScanViewModel.swift`
- Create: `Tests/SimilarVideoFinderTests/ScanViewModelTests.swift`

- [ ] **Step 1: Write failing workflow tests with injected fakes**

Test that starting a scan transitions `idle -> scanning -> completed`, cancelling transitions to `cancelled` and publishes no partial groups, a bad file appears in issue summary while good files continue, and deleting one item removes a resulting singleton group.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter ScanViewModelTests`

Expected: missing pipeline/view-model protocol failures.

- [ ] **Step 3: Implement candidate generation and pipeline**

Create candidates when normalized names match strongly, duration differs by at most 12%, size differs by at most 35%, or dimensions have the same aspect ratio. Hash same-size candidates; run frame analysis only for unresolved candidates. Limit expensive analysis to two concurrent pairs, report stages and fractional progress, call `Task.checkCancellation()`, and emit final groups only after successful completion.

- [ ] **Step 4: Implement main-actor state orchestration**

`ScanViewModel` owns selected folder, threshold, groups, selected group/video, progress, issues, active task, and presented errors. Inject scanner, pipeline, and deletion service protocols so tests never touch user files.

- [ ] **Step 5: Verify GREEN**

Run: `swift test --filter ScanViewModelTests`

Expected: all workflow tests pass.

### Task 7: Implement safe deletion and macOS file actions

**Files:**
- Create: `Sources/SimilarVideoFinder/Services/DeletionService.swift`
- Create: `Tests/SimilarVideoFinderTests/DeletionServiceTests.swift`

- [ ] **Step 1: Write failing service tests**

Using temporary files, assert permanent deletion removes the file, a missing target returns a typed `fileMissing` error, and a failed operation leaves view-model groups unchanged. Keep recycle-bin behavior behind an injected `FileManaging` adapter so unit tests do not alter the real Trash.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter DeletionServiceTests`

Expected: missing deletion service failure.

- [ ] **Step 3: Implement platform actions**

Use `FileManager.trashItem(at:resultingItemURL:)` for recycle, `FileManager.removeItem(at:)` for permanent deletion, `NSWorkspace.shared.activateFileViewerSelecting` for Finder, and `NSWorkspace.shared.open` for the default player. Map Cocoa errors to concise Chinese user-facing messages.

- [ ] **Step 4: Verify GREEN**

Run: `swift test --filter DeletionServiceTests`

Expected: deterministic deletion tests pass without touching real user files.

### Task 8: Build the three-column SwiftUI interface

**Files:**
- Modify: `Sources/SimilarVideoFinder/Views/ContentView.swift`
- Create: `Sources/SimilarVideoFinder/Views/SidebarView.swift`
- Create: `Sources/SimilarVideoFinder/Views/GroupDetailView.swift`
- Create: `Sources/SimilarVideoFinder/Views/VideoCardView.swift`
- Create: `Sources/SimilarVideoFinder/Views/InspectorView.swift`
- Create: `Sources/SimilarVideoFinder/Views/DeleteConfirmationView.swift`

- [ ] **Step 1: Add failing state-level UI contract tests**

Extend `ScanViewModelTests` to assert folder selection enables scanning, no selection yields an empty inspector, selecting a group selects its first video, and delete confirmation state begins at `.choosingMethod` rather than a destructive default.

- [ ] **Step 2: Run tests and verify RED**

Run: `swift test --filter ScanViewModelTests`

Expected: missing selection/delete-prompt state.

- [ ] **Step 3: Implement the approved three-pane layout**

Use `NavigationSplitView` for native sidebar selection, a detail grid with adaptive cards, and a fixed-width inspector. Use semantic system colors/materials, `VideoPlayer` with an `AVPlayer`, toolbar folder/scan actions, progress with cancellation, a threshold slider, issue summary, keyboard Delete command routed through confirmation, and empty states for no folder/no results/no selection.

- [ ] **Step 4: Implement explicit deletion dialogs**

The first dialog shows filename and path and offers cancel, move to Trash, or permanent delete. Permanent delete opens a second destructive confirmation containing “无法恢复”; no destructive action receives default keyboard focus.

- [ ] **Step 5: Verify build and state tests**

Run: `swift test && swift build`

Expected: all tests pass and the app compiles with no errors.

### Task 9: Package, launch, and perform end-to-end verification

**Files:**
- Modify: `script/build_app.sh`
- Modify: `README.md` if usage or limitations need clarification.

- [ ] **Step 1: Build the release app**

Run: `./script/build_app.sh`

Expected: `dist/相似视频查找器.app` is recreated and contains a release executable and valid `Info.plist`.

- [ ] **Step 2: Validate bundle metadata**

Run: `plutil -lint 'dist/相似视频查找器.app/Contents/Info.plist' && codesign --verify --deep --strict 'dist/相似视频查找器.app'`

Expected: plist is valid; ad-hoc signing verification succeeds after the build script applies `codesign --force --deep --sign -`.

- [ ] **Step 3: Run all automated verification**

Run: `swift test && swift build -c release`

Expected: zero failing tests and successful release build.

- [ ] **Step 4: Launch and inspect the UI**

Run: `./script/build_and_run.sh`

Verify: main window opens; folder chooser works; scan/cancel states update; groups can be selected; the right-side player loads; Finder/default-player actions work.

- [ ] **Step 5: Exercise deletion safely with disposable fixtures**

Create disposable videos under `/private/tmp/similar-video-finder-qa`, scan only that folder, verify Trash choice and permanent-delete second confirmation, and confirm groups update only after successful deletion.

- [ ] **Step 6: Final requirements audit**

Re-read `docs/superpowers/specs/2026-06-12-similar-video-finder-design.md` and check every acceptance criterion against automated output or the manual QA notes. Report any intentional limitation rather than silently weakening the specification.
