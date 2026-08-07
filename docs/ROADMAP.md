# Roadmap: next steps

Written 2026-08-03 so this work can be picked back up in a fresh session
without re-deriving context. Read `CLAUDE.md` first (architecture + module
graph + current status), then `docs/PRD.md` (full spec) and
`docs/decisions/gif-handling.md` (rendition/cache/favorites/pagination
decisions already made) before starting any task below.

**Before touching code**, confirm the existing baseline still holds:
```sh
cd GIFBarKit && swift test        # 75/75 should pass
cd .. && xcodebuild -project GIFBar.xcodeproj -scheme GIFBar build   # should be clean, 0 warnings
```

**Standing constraint**: this development environment has no attached
display (screen recording is denied, the accessibility tree reports zero
windows for a running app). No task here can be visually verified from
inside a session running in this kind of environment — the user needs to
open the project in Xcode and run it locally to eyeball anything UI-related.
Say so explicitly when a task needs that instead of claiming a visual check
that didn't happen.

## Current status

- **Done**: milestones 1 (project setup), 2 (design system, including
  `ErrorStateView`), 3 (real Networking — see below), 4–8 (Trending,
  Masonry, Search UI, Clipboard UI, Favorites).
- **Milestone 3 (Networking) — fully done and verified live against the real
  Giphy API**, including Task 3.4b. Concretely: `Networking` has
  `NetworkError`, `Endpoint`, `RequestBuilder`, `APIClient` (wraps
  `URLSession` via the `APIRequesting` protocol), the Giphy DTOs + decoder
  (`GifDTO`/`ImagesDTO`/`RenditionDTO`/`GiphyListResponse`, handling Giphy's
  string-encoded width/height), `GifRenditionPicker`, and `ImageCache`
  (memory + disk, keyed by URL, in-flight request dedup via `ImageLoading`).
  `Models.Gif` gained optional `previewURL`/`originalURL` fields (`nil` for
  mock data — source-compatible, `MockGifProvider` untouched).
  `Services.GiphyService: GifProviding` is the real implementation (chunks
  `fetch(ids:)` into ≤50-id batches, reorders to match the request, matching
  `MockGifProvider`'s contract). `ClipboardService` uses `gif.originalURL`
  for both operations and downloads real bytes via `ImageLoading` for Copy
  Binary. `GifBarViewModel` has an `isErrorState` flag (set by `reload()`
  failures only — `loadNextPage()` failures leave existing gifs on screen and
  just stop paging, rather than replacing the grid with `ErrorStateView`) and
  a `retryLoad()` action wired into `GifGridView`. `App/GIFBarApp.swift`'s
  composition root now builds a real `APIClient`/`GiphyService`/`ImageCache`
  instead of `MockGifProvider` — the `ImageCache` instance is shared between
  `ClipboardService` and `GifBarViewModel.loadImageData` (used by
  `AnimatedGIFView`) for cache reuse. `AnimatedGIFView` (Task 3.4b) decodes
  GIF frames via `ImageIO`/`CGImageSource` and plays them back manually in
  `GIFCard`, replacing `StripedPlaceholder` whenever `gif.previewURL` is
  non-nil; `ViewModels` exposes this via `GifBarViewModel.loadImageData(for:)`
  since `Views` can't import `Networking` directly (`Services.ImageDataLoading`
  is a same-shaped protocol redeclared for this, with `Networking.ImageCache`
  conforming via a retroactive extension — same trick as
  `PasteboardWriting`/`APIRequesting`). Confirmed working live: trending
  loads, GIFs render and animate.
  **Two real, pre-existing bugs were found and fixed while verifying this
  end-to-end** (not caught by `swift test`/`xcodebuild` alone, since neither
  actually launches the app):
  1. `project.yml` used `settings.configs.<Config>.xcconfig` to point at the
     `Config/*.xcconfig` files — that's the wrong XcodeGen key and silently
     set a literal, meaningless build setting named `xcconfig` instead of
     attaching the file as the target's base configuration. Every setting
     from `Base.xcconfig`/`Debug.xcconfig`/`Release.xcconfig` (including
     `GIPHY_API_KEY`, `PRODUCT_BUNDLE_IDENTIFIER`, `ENABLE_HARDENED_RUNTIME`)
     was never actually applied. Fixed by using the top-level `configFiles:`
     key instead.
  2. `App/Info.plist` never declared `CFBundleIdentifier`/`CFBundleExecutable`
     — harmless for `swift build`/`xcodebuild build`, but fatal at actual
     launch: macOS's App Sandbox initializer needs a bundle identifier to
     construct the container path, so the process trapped in
     `_libsecinit_appsandbox` before any app code ran. Fixed by adding both
     keys (`$(PRODUCT_BUNDLE_IDENTIFIER)` / `$(EXECUTABLE_NAME)`).

  Given neither bug was visible from `swift test`/`xcodebuild build`/reading
  the code — only from actually launching the built app — treat "builds
  clean" and "actually runs" as separate claims for any future milestone
  that touches `project.yml`, `Info.plist`, or entitlements.
- **Milestone 9.1 (snapshot tests) — done.** Added `pointfreeco/swift-snapshot-testing`
  as `GIFBarKit`'s first external SPM dependency (`Package.resolved` is now tracked,
  no longer gitignored). The library has no macOS `SwiftUI.View` → image strategy (only
  iOS/tvOS) — `Tests/{DesignSystemTests,ViewsTests}/SnapshotHelpers.swift` wraps views in
  `NSHostingView` and snapshots that as an `NSView` instead; duplicated per test target
  since SPM test targets can't share sources without a dedicated support target for a
  few lines of code. Covered: `GIFCard` (unselected/favorited/selected), `EmptyStateView`,
  `ErrorStateView`, `LoadingSkeletonGrid`, and full-screen `RootView` in three states
  (trending loaded, search-no-results, favorites-empty) driven via
  `GifBarViewModel.preview()`. Text-token colors (`DesignTokens.Color.textPrimary` etc.)
  are tuned for the app's dark popover background, so state-view tests render over an
  approximated dark background rather than the host's default white.
- **Milestone 9.2 (UI tests) — drafted, not yet run.** Replaced the single smoke test in
  `GIFBarUITests.swift` with 8 scenarios (trending load, search filter, infinite scroll,
  favorite/unfavorite + Favorites tab, copy URL, copy binary, persistence across relaunch).
  Added `.accessibilityIdentifier` to `GIFCard`/favorite button/search field/clear button/
  favorites toggle/settings menu button, since the existing `.accessibilityLabel`s weren't
  reliable query targets (several change dynamically, e.g. Favorites toggle's "Show
  Favorites"/"Showing Favorites", or embed the GIF's live title). **Found and fixed a real
  pre-existing bug while wiring this up**: `Config/Base.xcconfig` sets `PRODUCT_NAME =
  GIFBar` project-wide via `project.yml`'s top-level `configFiles:`, which `GIFBarUITests`
  silently inherited too — both targets tried to produce `GIFBar.swiftmodule`, so
  `xcodebuild ... test`/`build-for-testing` failed outright. Nobody had hit this before
  since only `swift test` (GIFBarKit) and `xcodebuild build` (app only, no test bundle)
  had actually been run. Fixed by overriding `PRODUCT_NAME: $(TARGET_NAME)` on the
  `GIFBarUITests` target in `project.yml`. The test bundle now builds cleanly
  (`build-for-testing` succeeds) but **could not be executed from this environment** —
  beyond the standing no-display constraint, this sandboxed CLI session also hits a
  code-signing/process-injection restriction (`mapping process and mapped file have
  different Team IDs`) that blocks `xcodebuild test` from actually launching the UI test
  runner. The user needs to run these locally (with a real `GIPHY_API_KEY`) to find out
  whether the scenarios themselves pass.
- **Milestone 9.3 (Networking edge-case backfill) — already satisfied, no action taken.**
  Checked `NetworkingTests`/`ServicesTests` against this bullet's intent (retry/timeout/
  malformed-JSON handling): HTTP status errors, malformed JSON, transport failures,
  concurrent-request dedup, disk-cache hit/write-through, failed-fetch-doesn't-cache,
  id-batch chunking >50, result reordering/dropping-unknown-ids, and empty-input
  short-circuiting are all already covered from the original milestone 3 work. Nothing
  meaningful left to backfill here. (Noted in passing, not acted on: `NetworkError
  .missingAPIKey` is declared but never thrown anywhere — dead code, left alone since it
  wasn't in scope.)
- **CI/CD — done** (see the dedicated section below). The repo went public
  2026-08-07 and both workflows landed and were verified green the same day.
- **Not started**: milestone 10 (performance polish) and a dedicated accessibility pass —
  both need a live display and the user driving the app/VoiceOver, not feasible from this
  environment.

## Milestone 3 — Networking (next up)

### Task 3.1 — Networking primitives
**What**: `NetworkError` (enum), `Endpoint` (protocol/struct describing path +
query items), `RequestBuilder` (assembles `URLRequest`, injects the
`api_key` query param from `Bundle.main.infoDictionary["GiphyAPIKey"]`), and
`APIClient` (wraps `URLSession`, protocol-oriented so it can be faked in
tests — mirror the `PasteboardWriting`-style protocol-wrapping-a-system-type
pattern already used in `Services`).
**Lives in**: `GIFBarKit/Sources/Networking/` (currently an empty
placeholder — delete `Networking.swift`'s `public enum Networking {}` marker
once real content lands, same pattern used for every other module this
session).
**Depends on**: nothing — fully self-contained.
**Background-agent suitable**: yes. Pure networking code, unit-testable by
stubbing `URLProtocol` (no live network calls in tests), no UI, no
dependency on other unbuilt pieces.
**Acceptance**: `swift test --filter NetworkingTests` passes; `APIClient`
has no force-unwraps on network/decoding failure paths.

### Task 3.2 — Giphy DTOs, response decoding, and the `Gif` model change
**What**: Decode Giphy's actual JSON response shape (a GIF object's `images`
dictionary with `fixed_width`, `fixed_width_downsampled`, `original`, etc.
— see `docs/decisions/gif-handling.md` for the full rendition list) into
`Models.Gif`.
**Design decision to make (recommended approach below, but confirm/reconsider
before implementing)**: `Models.Gif` currently only has
`id`/`title`/`width`/`height` — enough for mock-driven layout, not enough to
actually load a thumbnail. Recommended: add two **optional** fields,
`previewURL: URL?` and `originalURL: URL?`, populated by the real decoder
using `GifRenditionPicker` (Task 3.3) for `previewURL` and `images.original`
for `originalURL`. Optional (not required) so `MockGifProvider` keeps
compiling unchanged and returns `nil` for both — `GIFCard` already falls
back to `StripedPlaceholder` today, so make that fallback conditional on
`gif.previewURL == nil` rather than always-on, and nothing else needs to
change. This avoids introducing a second `Gif`-like type or touching
`ViewModels`/`Views` signatures.
**Depends on**: Task 3.1 (for the raw response fetching this decodes) —
though the decoder itself can be written and unit-tested against fixture
JSON in parallel, independent of `APIClient`.
**Background-agent suitable**: yes for the decoder + DTO + fixture-based
tests. The `Gif` model change is small but touches a shared type — flag it
in the PR/commit description since it's a cross-module change (`Models` is
depended on by everything).

### Task 3.3 — `GifRenditionPicker`
**What**: Implement the exact algorithm already specified in
`docs/decisions/gif-handling.md` ("Rendition selection for the masonry
grid") — `rendition(for:targetWidth:scale:)` choosing between
`fixed_width_small`/`fixed_width`/`fixed_width_downsampled`, never
`original`.
**Lives in**: `Networking` (per the decision doc).
**Depends on**: nothing (pure function once the DTO shape from Task 3.2 exists
to pick from — can be stubbed with a minimal local type and merged with 3.2's
real DTO once both land).
**Background-agent suitable**: yes. Pure logic, fully unit-testable with
table-driven tests over the threshold boundaries (~110px, ~220px) called out
in the decision doc.

### Task 3.4 — Image loading pipeline
Two distinct pieces — split them:

**3.4a — Cache/dedup/cancellation/prefetch infrastructure.** Memory + disk
cache keyed by rendition URL, in-flight request de-duplication, cancellation
support. Lives in `Networking` or a new `Services`-level `ImageLoading`
type — your call at implementation time, but keep it behind a protocol like
everything else so it's fakeable in `ViewModels`/`Views` tests.
**Background-agent suitable**: yes — this is infrastructure code with clear
unit-testable behavior (dedup: two concurrent requests for the same URL
should share one download; cache: a second request for a cached URL
shouldn't hit the network at all).

**3.4b — `AnimatedGIFView`, the actual on-screen rendering.** Replace
`StripedPlaceholder` in `GIFCard` with a real animated thumbnail once
`gif.previewURL` is non-nil. No third-party GIF library is implied by the
PRD (only the *official Giphy SDK* is explicitly disallowed) — decode frames
with `ImageIO`/`CGImageSource` and drive playback manually; this is real
visual/animation work.
**Not background-agent suitable on its own** — needs iterative visual
verification the user must do locally (see the standing constraint above).
Reasonable split: have an agent draft the `CGImageSource`-based frame
decoding + a basic `NSViewRepresentable`/`TimelineView`-driven player as a
starting point, then do the visual tuning pass interactively with the user
watching real output.

### Task 3.5 — `GiphyService: GifProviding`
**What**: The real implementation of the protocol `MockGifProvider`
currently satisfies — `trending`/`search`/`fetch(ids:)` calling through
`APIClient` + the Task 3.2 decoder.
**Depends on**: Tasks 3.1, 3.2, 3.3.
**Background-agent suitable**: yes, once 3.1–3.3 exist (or as one combined
agent run covering 3.1–3.3 and 3.5 together, since they're tightly coupled
and don't need separate human checkpoints in between).
**Acceptance**: `ServicesTests`-style tests against `APIClient` faked via a
stubbed `URLProtocol`, mirroring the existing `MockGifProviderTests`
structure for parity.

### Task 3.6 — Rewire `ClipboardService` off its mock conventions
**What**: `copyURL` currently synthesizes `https://giphy.com/gifs/<id>`;
`copyBinary` writes a placeholder 1×1 GIF. Both need to use the real
`gif.originalURL` (Task 3.2) and, for binary copy, actually download the
bytes via `APIClient`/the image cache (Task 3.4a) rather than the current
hardcoded value.
**Depends on**: Tasks 3.2, 3.4a, 3.5.
**Background-agent suitable**: yes — `ClipboardServiceTests` already has the
fake-pasteboard pattern to extend, no UI involved.

### Task 3.7 — Swap the composition root, final integration
**What**: In `App/GIFBarApp.swift`, replace `MockGifProvider()` with the real
`GiphyService`. Requires a real Giphy API key in `Config/Secrets.xcconfig`
(gitignored — the user has to supply their own; it's currently a placeholder
value).
**Depends on**: everything above.
**Not background-agent suitable** — this is the point where real network
behavior first runs, and needs the user to actually launch the app locally
(with their real API key) and confirm it works, since this environment can't
render or click through the UI. Keep this step small and do it last,
foreground, with the user present.

### Task 3.8 — Error state UI
**What**: PRD's Design System section calls for an `ErrorStateView`
(currently not built — the only PRD-listed design-system component missing).
Add it to `DesignSystem` (same pattern as `EmptyStateView`: icon/title/
subtitle/retry-action params), then wire `GifBarViewModel`'s existing
silent-failure catch blocks (`reload()`/`loadNextPage()` currently just clear
`gifs`/set `hasMore = false` on error) to surface it instead. This becomes
relevant the moment real networking can actually fail — do it alongside or
right after Task 3.5, not before (no point building error UI for a mock
provider that can't fail).
**Background-agent suitable**: yes for the `DesignSystem` component and the
`GifBarViewModel` wiring/tests (`isErrorState`-style derived flag, mirroring
`isSearchEmpty`/`isFavoritesEmpty`). Visual confirmation still needs the user.

## Suggested order for the next session

1. **Parallel background agents**: Task 3.1, Task 3.3, and the decoder half
   of Task 3.2 (fixture-based, no `APIClient` dependency yet) — no
   interdependency between these three.
2. Task 3.4a (image cache infra) — can also run in parallel with the above.
3. Task 3.5 once 3.1–3.3 land.
4. Task 3.6 once 3.5 lands.
5. Task 3.8 in parallel with 3.6 (both only need 3.2/3.5, not each other).
6. Task 3.7 — foreground, with the user, last.
7. Task 3.4b (`AnimatedGIFView`) — foreground/interactive visual pass,
   whenever convenient relative to the above (it only needs 3.2's
   `previewURL` field to exist, not the full real network path).

## Milestone 9 — Testing (after milestone 3 lands)

- **9.1**: Add a snapshot-testing dependency (none exists yet —
  `pointfreeco/swift-snapshot-testing` is the de facto standard for SwiftUI;
  confirm with the user before adding a new SPM dependency, since none has
  been introduced so far and this project has deliberately avoided external
  deps beyond the Giphy API itself). Then snapshot tests for `GIFCard`,
  Trending/Search screens, loading/empty/error states, Favorites screen —
  background-agent suitable once the dependency and one reference snapshot
  are established as a pattern.
- **9.2**: Real `GIFBarUITests` scenarios (launch, search, infinite scroll,
  favorite/unfavorite, copy URL, copy binary, persistence after relaunch) —
  the target already exists with one smoke test. XCUITest scenarios can be
  drafted by an agent but need the user to run them locally, since UI tests
  launch and drive the actual app.
- **9.3**: Backfill unit test coverage for whatever Networking edge cases
  turn up during milestone 3 (retry/timeout/malformed-JSON handling, etc.).

## Milestone 10 — Performance polishing

**Done from code (2026-08-07), no display needed**: `Networking.ImageCache`'s
memory tier (`NSCache`) had no `totalCostLimit` — it only evicted under actual
system memory pressure, a late reactive backstop rather than a budget. Now
capped at 150MB (`ImageCache.defaultMemoryCacheLimitBytes`), with `cost:`
passed as each entry's real byte count. Verified with a real test
(`testMemoryCacheEvictsOnceTotalCostLimitIsExceeded`), not just trusted —
sets a limit smaller than one entry and confirms `NSCache` actually evicts
it. Confirmed *not* a bug: `FileManagerDiskImageCache` writes to
`~/Library/Caches`, which macOS already reclaims under disk pressure by
platform convention — left alone. "No duplicate downloads under fast
scrolling" was already covered by existing `ImageCacheTests`
(`testConcurrentRequestsForSameURLShareOneDownload`).

Looked at but *not* changed, flagged only: `Views.MasonryGrid` calls
`MasonryBalancer.distribute` (a full O(n) rebalance across every loaded item)
on every `body` re-evaluation — including ones that don't add/remove items,
like selecting a card. At realistic list sizes for this app (a menu-bar GIF
picker, not an infinite social feed) this is sub-millisecond trivial work;
flagging rather than fixing since a memoization pass isn't justified without
profiling evidence it's actually a problem.

**Still needs the user, live, with a real display**:
- Profile real scrolling with live images and the real image cache (not
  meaningful against the mock provider) via Instruments' Time Profiler —
  particularly with `AnimatedGIFView`'s per-cell animation loops (each
  visible card runs its own independent `Task.sleep`-driven frame loop).
- Check actual memory footprint (Activity Monitor or Instruments' Allocations)
  with a large Trending/Search result set loaded, to see whether the new
  150MB cache cap is well-tuned in practice or needs adjusting.

## Accessibility pass

**Done from code (2026-08-07), no display needed**:
- Giphy's `alt_text` field (a screen-reader-specific description, distinct
  from and often more descriptive than `title`) wasn't being decoded at all.
  `GifDTO.altText` now decodes it, `toModel()` normalizes blank/whitespace-only
  values to `nil` (Giphy returns `""` far more often than omitting the field),
  and `GIFCard` prefers it over `"<title> GIF"` for its `accessibilityLabel`.
- `LoadingPlaceholder`'s shimmer was a perpetual `repeatForever` animation
  with no check against `accessibilityReduceMotion` — now shows a static
  highlight instead of a sliding one when Reduce Motion is on.
- `ToastOverlay`'s toasts ("GIF Copied", "Added to Favorites", etc.) were
  purely visual and self-dismissing, giving VoiceOver users no feedback that
  copy/favorite actions succeeded — now posts an
  `AccessibilityNotification.Announcement` when the toast changes.
- Computed actual WCAG contrast ratios for `DesignTokens.Color`'s text
  tokens against the popover background: `textPrimary` 15.6:1, `textSecondary`
  5.9:1 (both comfortably pass AA). `textTertiary` (used only for the large
  decorative icon in `EmptyStateView`/`ErrorStateView`) is 2.8:1, under the
  3:1 AA minimum for non-text UI components — **not changed**, since it's a
  visual design token value and a deliberate call for the user to make, not
  a silent fix. `0x77777C` would clear 3.8:1 if wanted.
- Confirmed Dynamic Type isn't supported anywhere (`DesignTokens.Font` is all
  fixed-size `.system(size:)`) — **not changed**, likely an intentional
  constraint given the popover's fixed 380×580 non-resizable size; flagging
  only.

**Still needs the user, live, with VoiceOver actually running** — this is
the important part, not background-agent-suitable:
- **The biggest open question**: does `GIFCard`'s `.accessibilityLabel("\(gif.title)
  GIF")` on the outer `ZStack` actually merge the card into one VoiceOver
  stop, or does VoiceOver see the inner `selectableBody` Button and the
  `favoriteButton` as two separate stops (ignoring the outer label)? This
  determines whether tabbing through a loaded grid is N stops or 2N stops —
  worth checking with VoiceOver running before trusting the label is doing
  anything. (Deliberately not "fixed" blind — restructuring accessibility
  grouping without verifying current behavior first risks making it worse.)
- VoiceOver sweep across the toolbar (search field, clear button, favorites
  toggle, settings `•••` menu — including whether the programmatically-shown
  `NSMenu` in `SettingsMenu` is reachable/navigable via VoiceOver at all,
  since it's not a native SwiftUI `Menu`) and the toast's actual spoken
  announcement.
- Keyboard focus order through the grid and toolbar — confirm it matches
  visual/logical order, particularly since `GIFCard` uses `.focusable()` +
  `.onKeyPress` rather than a native control.

## CI/CD (GitHub Actions) — done

`gif-bar` went public 2026-08-07; `.github/workflows/ci.yml` and `release.yml`
landed the same day, both verified green on GitHub's actual infrastructure
(not just locally), matching the bar this section originally set.

- **CI** (`ci.yml`, on push to `main`/PRs): two parallel jobs on `macos-26`
  (matches local Xcode 26.6 toolchain exactly). `unit-tests` runs `swift test
  --skip SnapshotTests` directly against `GIFBarKit` — snapshot suites are
  excluded here, not disabled: they were recorded on a Retina display (2x
  backing scale) and this headless runner has no attached display, so
  `NSHostingView` snapshots come back at a different pixel scale entirely, a
  gap no amount of `precision`/`perceptualPrecision` tolerance closes (tried
  0.98, still failed outright — confirmed a scale/dimension mismatch, not a
  hinting/antialiasing one). They remain a real local-dev safety net via
  plain `swift test`. `app-build` installs XcodeGen via Homebrew, copies
  `Config/Secrets.xcconfig.example` as a placeholder (compiling only needs
  the file to exist — no network call happens during build or test), runs
  `xcodegen generate`, then a full `xcodebuild build`.
- **Release** (`release.yml`, on `v*.*.*` tag push or manual dispatch): builds
  the Release configuration, zips the `.app` via `ditto`, and publishes it as
  a GitHub Release via `gh release create` (no third-party action needed —
  `gh` and `GITHUB_TOKEN` are already available on the runner). Manual
  dispatch runs the build as a smoke test but stops before publishing (no tag
  to name a release after). Bakes a real `GIPHY_API_KEY` into the shipped
  binary from a `GIPHY_API_KEY` repo secret — the user's explicit choice over
  shipping a non-functional placeholder — so the downloaded app works out of
  the box; trade-off is the key is extractable from the binary
  (strings/otool), so it should be one they're fine having public/
  rate-limited. **Not yet set up**: the `GIPHY_API_KEY` repo secret itself
  (`gh secret set GIPHY_API_KEY --repo leschlogl/gif-bar`) — until that
  exists, a tag push will fail at the "Set up secrets" step. Still ad-hoc
  signed, no Developer ID/notarization (needs an Apple Developer account —
  separate from the CI/CD work itself, genuinely deferred, not blocking).

Two real bugs were found and fixed getting the first CI run green (both are
CI-only flakes — `swift test` alone never surfaced either locally):
1. `GIFBarUITests` silently inherited `PRODUCT_NAME = GIFBar` from
   `Config/Base.xcconfig` (applied project-wide via `project.yml`'s top-level
   `configFiles:`), colliding with the app target's own module — fixed by
   overriding `PRODUCT_NAME: $(TARGET_NAME)` on that target. Caught while
   drafting milestone 9.2's UI tests, not by CI itself, but same root cause
   class.
2. `GifBarViewModelTests.testStalePaginationFetchDoesNotCorruptResultsAfterNewSearch`'s
   `waitForDebounce()` helper only budgeted 50ms of margin past the 300ms
   Combine debounce for the subsequent reload's async hops to finish — fine
   on a local machine, too tight under CI's more contended scheduler. Bumped
   to 600ms.
