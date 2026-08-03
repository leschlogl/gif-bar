# GIF handling: rendition selection, clipboard, caching, favorites, pagination

Design decisions for how GIFBar picks image renditions, uses the cache, stores
favorites, and pages through Giphy results. Captured ahead of the Networking
(milestone 3), Masonry (5), and Favorites (8) milestones so the design is
settled before that code is written — see `docs/PRD.md` for the milestone
order. This doc **supersedes** the Favorites storage shape described in the
PRD (see "Favorites store IDs only" below).

## Giphy renditions available

Every GIF object from the Giphy API returns an `images` dictionary with many
renditions of the same GIF, e.g. `fixed_width`, `fixed_width_downsampled`,
`fixed_width_small`, `downsized`, `original`, plus `_still` (static preview)
variants. Each rendition has its own `url`, `width`, `height`, and `size`
(bytes). Renditions are cheap to switch between — they're just different URLs
— but each one is a separate download, so picking the right one per use case
matters for bandwidth.

## Rendition selection for the masonry grid

The grid should request the **smallest rendition that still looks sharp at
the cell's rendered size**, not `original`. `original` files are frequently
several MB; grid cells render at well under 300pt wide.

Algorithm (lives in `Networking` or `Services`, e.g.
`GifRenditionPicker.rendition(for:targetWidth:scale:)`):

1. Compute the target pixel width: `cellWidth (points) * NSScreen scale factor`
   (2x/3x on Retina).
2. Choose from the `fixed_width*` family, since those preserve aspect ratio
   at a fixed width — exactly what a masonry column needs:
   - `fixed_width_small` (~100px) if target ≤ ~110px
   - `fixed_width` (~200px) if target ≤ ~220px
   - `fixed_width_downsampled` (~200px, reduced frame rate/quality, smaller
     file) when bandwidth matters more than animation smoothness — prefer
     this over plain `fixed_width` when prefetching many cells ahead of
     scroll position
   - Never fall through to `original` for grid thumbnails, even if the
     computed target width exceeds 220px — cap at `fixed_width` quality.
3. Use the rendition's own reported `width`/`height` to preserve aspect ratio
   in layout, rather than the GIF's `original` dimensions.

## Clipboard always uses `original`

Both clipboard operations bypass the grid rendition entirely and use
`images.original`:

- **Copy URL** copies `images.original.url`.
- **Copy Binary** (context menu and double-click) downloads
  `images.original.url` and writes the binary GIF data to `NSPasteboard`,
  preserving animation.

Rationale: the grid rendition is downsampled for bandwidth; anything the user
explicitly shares (pasted into Slack/Messages/etc.) should be the real,
full-quality GIF.

## Cache reuse

The image loading pipeline (PRD's "Image Loading" section) caches by
**rendition URL**, since each rendition is a distinct URL:

- Memory + disk cache keyed by URL.
- Request deduplication keyed by URL — if a cell re-appears (scroll back)
  while its rendition is already in flight, reuse the in-flight task rather
  than starting a second download.
- Copying a GIF's binary is a cache read/write like any other: if the
  `original` was already fetched for that GIF (e.g. copied twice, or
  previously favorited and opened), reuse the cached bytes instead of
  re-downloading.
- Prefetching during scroll fetches the grid rendition (`fixed_width` /
  `fixed_width_downsampled`) for cells just below the viewport — never
  prefetch `original`.

## Favorites store IDs only

Persistence stores an **ordered list of favorited GIF IDs** — not the
denormalized `title`/`previewURL`/`originalURL`/`width`/`height` fields the
PRD originally described. When the Favorites tab is opened, GIFBar batch
loads current details via `GET /v1/gifs?ids=...` (Giphy allows fetching up to
50 GIFs per call) and renders through the normal grid rendition + cache
pipeline.

Rationale: avoids stale metadata (a GIF's URLs can change) and keeps
persistence trivial (`[String]` of IDs, not a growing local copy of GIF
metadata). Trade-off: opening Favorites requires network access; if that's
ever a problem, the fix is to cache the last-fetched batch response, not to
go back to storing full metadata locally.

Order is preserved as favorited (most-recently-favorited first, or insertion
order — pick one when Persistence is implemented and document it here).

## Pagination & prefetch

Every list-producing endpoint (Trending, Search, and the Favorites
`ids`-batch lookup) is paginated using Giphy's `offset`/`limit` and reads
`pagination.total_count` from the response to know when there's no more data.

For smooth infinite scroll: trigger the next page fetch when the user
scrolls within N items (e.g. last 10) of the currently-loaded end of the
list, so the next page is already loading — ideally already arrived — by the
time they reach the bottom, rather than waiting for them to hit the end and
then showing a spinner.
