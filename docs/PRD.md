# Giphy Menu Bar for macOS

## Product & Technical Specification (PRD)

## Overview

Build a **native macOS menu bar application** using **Swift 6**,
**SwiftUI**, and **Combine**.

The application lives exclusively in the macOS menu bar (status bar) and
provides a fast, native way to browse, search, favorite, and share GIFs
using the **public Giphy REST API**.

This project is intended to demonstrate **senior-level macOS
engineering**, modern SwiftUI architecture, excellent testing practices,
and a polished Apple-quality user experience.

------------------------------------------------------------------------

# Platform

-   Target **macOS 26 only**
-   Swift 6
-   SwiftUI
-   Combine
-   Latest stable Xcode

Do **not** support older macOS versions.

Always prefer the newest APIs introduced in macOS 26 whenever possible.

------------------------------------------------------------------------

# Design Philosophy

The application should feel like a first-party Apple application.

Whenever multiple implementation choices exist:

-   Prefer native SwiftUI APIs.
-   Prefer Apple's recommended architecture.
-   Follow Apple's Human Interface Guidelines.
-   Match the behavior of Apple's own macOS applications.
-   Favor simplicity over unnecessary abstraction.
-   Favor maintainability over cleverness.

Avoid web-inspired UI patterns or cross-platform compromises.

The application should feel lightweight, responsive, polished, and
unmistakably native.

------------------------------------------------------------------------

# Goals

Users should be able to:

-   Browse Trending GIFs
-   Search GIFs
-   Favorite GIFs locally
-   Copy a GIF URL
-   Copy the GIF binary to the clipboard
-   Paste directly into applications such as Slack, WhatsApp, Discord,
    and Messages

------------------------------------------------------------------------

# Architecture

Use MVVM with clear separation of concerns.

Suggested modules:

-   App
-   DesignSystem
-   Models
-   Networking
-   Services
-   Persistence
-   ViewModels
-   Views
-   Utilities

Business logic must never exist inside SwiftUI Views.

Everything should be protocol-oriented and dependency injected.

Avoid singletons unless there is a compelling reason.

------------------------------------------------------------------------

# UI

## Menu Bar

-   The app lives exclusively in the macOS menu bar.
-   Clicking the status item opens a popover.
-   The popover remembers its previous size.
-   Suggested default size: 500 × 700.

## Toolbar

Contains:

-   Search field
-   Trending button
-   Favorites button

## Trending

On launch call:

GET /v1/gifs/trending

Display results in a Pinterest-style masonry layout.

Requirements:

-   Infinite scrolling
-   Lazy loading
-   Smooth scrolling
-   Loading placeholders
-   Empty state
-   Error state

## Search

Requirements:

-   300 ms debounce
-   removeDuplicates
-   Cancel previous request
-   Empty query returns Trending

Endpoint:

GET /v1/gifs/search

Support pagination.

## Masonry Layout

Requirements:

-   Variable cell heights
-   Preserve aspect ratio
-   Efficient virtualization
-   Excellent scrolling performance

## GIF Card

Displays:

-   Animated GIF
-   Favorite overlay
-   Hover animation
-   Context menu

Context menu:

-   Copy GIF URL
-   Copy GIF Binary
-   Favorite / Unfavorite

Double-click copies the GIF binary immediately.

------------------------------------------------------------------------

# Clipboard

Support:

## Copy URL

Copy the original GIF URL to NSPasteboard.

## Copy Binary

Download the original GIF and copy the binary data to NSPasteboard while
preserving animation so it can be pasted directly into supported
applications.

------------------------------------------------------------------------

# Favorites

Store favorites locally.

Persist:

-   id
-   title
-   previewURL
-   originalURL
-   width
-   height

No cloud sync.

Favorites survive relaunch.

------------------------------------------------------------------------

# Networking

Do **not** use the official Giphy SDK.

Implement the entire networking layer manually.

Suggested types:

-   APIClient
-   Endpoint
-   RequestBuilder
-   ResponseDecoder
-   NetworkError
-   GiphyService

Responsibilities:

-   Authentication
-   Pagination
-   JSON decoding
-   Error handling
-   GIF downloading

------------------------------------------------------------------------

# Image Loading

Implement an image loading pipeline with:

-   Memory cache
-   Optional disk cache
-   Request deduplication
-   Cancellation
-   Prefetching

Avoid downloading the same GIF multiple times.

------------------------------------------------------------------------

# Design System

Create a lightweight internal design system.

Centralize:

-   Colors
-   Typography
-   Spacing
-   Corner radius
-   Shadows
-   Animation durations
-   Icon sizes
-   Layout constants

Reusable components include:

-   SearchBar
-   GIFCard
-   LoadingPlaceholder
-   EmptyStateView
-   ErrorStateView
-   ToolbarButton

------------------------------------------------------------------------

# Testing

## Unit Tests

Cover:

-   Networking
-   Search pipeline
-   Pagination
-   ViewModels
-   Favorites persistence

## Snapshot Tests

Include snapshot tests for:

-   GIF card
-   Trending screen
-   Search screen
-   Loading state
-   Empty state
-   Error state
-   Favorites screen

## UI Tests

Cover:

-   Launch
-   Trending
-   Search
-   Infinite scrolling
-   Favorite
-   Remove favorite
-   Copy URL
-   Copy binary
-   Persistence after relaunch

Use dependency injection and mocks throughout the test suite.

------------------------------------------------------------------------

# Accessibility

Support:

-   VoiceOver
-   Keyboard navigation
-   Focus management
-   Accessibility labels and hints

------------------------------------------------------------------------

# Code Quality

Prioritize:

-   Readability
-   Maintainability
-   Small focused types
-   SOLID
-   Protocol-oriented design
-   Dependency Injection
-   Modern SwiftUI
-   Modern Combine

Avoid:

-   Massive Views
-   Massive ViewModels
-   Tight coupling
-   Global mutable state

------------------------------------------------------------------------

# Architecture Philosophy

This project is intended to demonstrate senior-level macOS engineering.

Before implementing each feature, prefer designing a clean, extensible
architecture rather than writing the minimum amount of code required.

Avoid shortcuts that would make future features harder to implement.

When introducing a new type, protocol, service, or abstraction, briefly
explain:

-   Why it exists
-   What responsibility it owns
-   Why it improves the architecture

Every architectural decision should have a clear purpose.

The codebase should remain cohesive, idiomatic, and aligned with Apple's
latest recommendations for SwiftUI applications.

Favor clarity, correctness, maintainability, and testability over
cleverness or unnecessary complexity.

------------------------------------------------------------------------

# Implementation Strategy

Implement the project incrementally.

Complete one milestone before moving to the next.

1.  Project setup
2.  Design System
3.  Networking layer
4.  Trending screen
5.  Masonry layout
6.  Search
7.  Clipboard support
8.  Favorites
9.  Testing
10. Performance polishing

Each milestone must compile successfully before moving on.

------------------------------------------------------------------------

# Overall Goal

The finished project should feel like a polished Apple application and
serve as a reference implementation of modern macOS 26 development using
SwiftUI and Combine.
