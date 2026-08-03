# GiphyBar

A native macOS menu bar app for browsing, searching, favoriting, and sharing GIFs via the Giphy API. Built with Swift 6, SwiftUI, and Combine, targeting macOS 26 only. See `Giphy_MenuBar_macOS26_PRD.md` for the full product/technical spec.

## Requirements

- macOS 26+
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A [Giphy API key](https://developers.giphy.com)

## Setup

```sh
git clone <repo-url> && cd giphy-bar
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
# edit Config/Secrets.xcconfig and set GIPHY_API_KEY
xcodegen generate
open GiphyBar.xcodeproj
```

`GiphyBar.xcodeproj` is generated from `project.yml` and is gitignored — regenerate it with `xcodegen generate` any time `project.yml` changes.

## Project structure

```
project.yml              XcodeGen project spec — edit this, not the .xcodeproj
Config/                   Shared build settings (xcconfig)
App/                      Thin app shell: entry point, Info.plist, entitlements, assets
GiphyBarKit/              Local Swift package holding all business logic, split into
                          independently testable modules:
  Sources/
    Utilities             Cross-cutting helpers with no other internal dependencies
    Models                Plain data types shared across modules
    DesignSystem          Colors, typography, spacing, reusable SwiftUI components
    Networking             APIClient, Endpoint, request/response handling
    Persistence            Local favorites storage
    Services               GiphyService and friends — orchestrate Networking + Persistence
    ViewModels             MVVM view models, depend on Services
    Views                  SwiftUI views, depend on ViewModels + DesignSystem
  Tests/                  Unit tests per module
GiphyBarUITests/          XCUITest target driving the built app
```

The app target depends on `GiphyBarKit`'s module libraries rather than containing business logic directly, so views, view models, networking, and persistence can each be built and tested in isolation.

## Building & testing

```sh
# Fast unit tests, no simulator/app launch needed
cd GiphyBarKit && swift test

# Full app build
xcodebuild -project GiphyBar.xcodeproj -scheme GiphyBar build

# UI tests
xcodebuild -project GiphyBar.xcodeproj -scheme GiphyBar test
```
