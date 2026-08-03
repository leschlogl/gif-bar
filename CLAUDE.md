# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GIFBar is a native macOS menu bar app (Swift 6, SwiftUI, Combine) for browsing, searching, favoriting, and sharing GIFs via the public Giphy REST API. It targets **macOS 26 only** — do not add compatibility shims for older macOS versions, and prefer the newest macOS 26 APIs over older equivalents. The full product/technical spec lives in `docs/PRD.md`; read it before implementing a new feature area.

## Commands

Setup (once per clone):
```sh
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig   # then set GIPHY_API_KEY
xcodegen generate
```

`project.yml` is the source of truth for the Xcode project — **never hand-edit `GIFBar.xcodeproj`**; edit `project.yml` and run `xcodegen generate` again. The `.xcodeproj` is gitignored.

```sh
# Unit tests — fast, no app/simulator launch. Run these while iterating on GIFBarKit.
cd GIFBarKit && swift test
swift test --filter ServicesTests            # single test target
swift test --filter ServicesTests/testFoo    # single test method

# Full app build
xcodebuild -project GIFBar.xcodeproj -scheme GIFBar build

# UI tests (launches the built app)
xcodebuild -project GIFBar.xcodeproj -scheme GIFBar test
```

## Architecture

The `GIFBar` Xcode target (`App/`) is a thin shell: just the `@main` `App` struct (`MenuBarExtra`, `.window` style — this is the SwiftUI-native stand-in for a popover), `Info.plist`, entitlements, and assets. **All business logic lives in the local Swift package `GIFBarKit`**, split into one library target per module under `GIFBarKit/Sources/`, each with its own test target under `GIFBarKit/Tests/`. The app target links every module's product directly (see `project.yml`).

Dependency direction between modules (a module may only depend on what's listed):
```
Utilities   — no internal deps
Models      — Utilities
DesignSystem — Utilities
Networking  — Models, Utilities
Persistence — Models, Utilities
Services    — Networking, Persistence, Models
ViewModels  — Services, Models, Utilities
Views       — ViewModels, DesignSystem, Models
```
Respect this graph — e.g. `Views` must never import `Networking` or `Services` directly, and `Models` must stay free of networking/persistence/UI concerns. Business logic (networking, persistence, GIF processing) must never live inside a SwiftUI `View`; it belongs in `Services`/`ViewModels`. Favor protocol-oriented types with dependency injection over singletons.

Networking is hand-rolled against the Giphy REST API — the official Giphy SDK is intentionally not used. Expect `APIClient`, `Endpoint`, request building, and response decoding to live in `Networking`, with `Services` (e.g. a `GiphyService`) orchestrating `Networking` + `Persistence`.

`Config/Secrets.xcconfig` (gitignored) holds `GIPHY_API_KEY`, which is injected into `Info.plist` as `$(GIPHY_API_KEY)` at build time and read from `Bundle.main` at runtime — never hardcode the key in source.

The PRD (`docs/PRD.md`) defines an incremental build order (project setup → design system → networking → trending → masonry layout → search → clipboard → favorites → testing → performance polish); each milestone should compile cleanly before starting the next.

## Design decisions

`docs/decisions/` holds decisions made ahead of their implementing milestone, so they're settled before the code is written. Read the relevant one before touching that area:

- `docs/decisions/gif-handling.md` — which Giphy rendition to request for grid thumbnails vs. clipboard (always `original` for copy/paste), cache-by-URL reuse rules, why Favorites persists GIF IDs only (not full metadata — this supersedes the PRD's Favorites section), and the pagination/prefetch trigger for infinite scroll.
