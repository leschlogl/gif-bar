# Roadmap: next steps

Written 2026-08-03 so this work can be picked back up in a fresh session
without re-deriving context. Read `CLAUDE.md` first (architecture + module
graph + current status), then `docs/PRD.md` (full spec) and
`docs/decisions/gif-handling.md` (rendition/cache/favorites/pagination
decisions already made) before starting any task below.

**Before touching code**, confirm the existing baseline still holds:
```sh
cd GIFBarKit && swift test        # 36/36 should pass
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

- **Done**: milestones 1 (project setup), 4–8 (Trending, Masonry, Search UI,
  Clipboard UI, Favorites) — all built against `Services.MockGifProvider`,
  not real network calls. Design system tokens/components exist (milestone 2
  is functionally done except `ErrorStateView`, see Task 3.8).
- **Not started**: milestone 3 (real Networking), most of milestone 9
  (snapshot tests, UI test scenarios — only unit tests exist so far),
  milestone 10 (performance polish), and a dedicated accessibility pass.
- The seam is already in place: `ViewModels`/`Views` only ever see the
  `Services.GifProviding` / `ClipboardCopying` protocols. Swapping
  `MockGifProvider` for a real `GiphyService` should require zero changes
  above the `Services` layer, by design.

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

## Milestone 10 — Performance polishing (after milestone 3 lands)

- Profile real scrolling with live images and the real image cache (not
  meaningful against the mock provider). Tune cache size limits, confirm no
  duplicate downloads under fast scrolling, check memory footprint with a
  large Trending/Search result set.

## Accessibility pass (ongoing, but worth a dedicated sweep)

`GIFCard` already has basic VoiceOver labels and keyboard navigation
(`.focusable()`, Enter/Space to select, a custom focus ring). Do a focused
pass across the toolbar (search field, tab bar, search-toggle button) and
toast, and verify with VoiceOver actually running — not background-agent
suitable, needs a real display and the user driving VoiceOver.
