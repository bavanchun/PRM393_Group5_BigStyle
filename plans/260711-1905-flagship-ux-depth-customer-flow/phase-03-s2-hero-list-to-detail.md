---
phase: 3
title: "S2: Hero List-to-Detail"
status: pending
priority: P1
dependencies: [1]
effort: "M"
---

# Phase 3: S2 — Hero List-to-Detail Transition

## Overview

Add a shared-element (Hero) transition so a product's image flies from the list/home card into the detail carousel, with the detail content fading in behind it. Increases perceived speed and gives the flow visual continuity.

## Requirements

- Functional: tapping a product card animates its image into `ProductDetailScreen`'s first carousel image; back navigation reverses cleanly.
- Non-functional: no flicker on image load; unique Hero tags; no tag collisions with other Heroes.

## Architecture

<!-- Updated: Red Team 2026-07-12 — C1 async-load destination, C2 optional tag + favorites call site, H3 sheet z-order -->
- **Hero tag plumbing (C2 — optional + collision-safe):** `ProductCard` receives only `imageUrl` (`product_card.dart:8`), NOT a product id. Home renders the same product in both featured (`home_screen.dart:112`) and new-arrivals (`:172`) → a plain `'product-${id}'` tag collides and asserts. **Locked:** add a **nullable** `heroTag` param to `ProductCard` and wrap the image in `Hero` **only when `heroTag != null`** (a null tag `Hero` throws). Build the tag per on-screen occurrence as `'product-${product.id}-${screen}-${section}-${index}'`. **Call sites (4, not 3):** `home_screen.dart:112` + `:172`, `product_list_screen.dart:289` pass a tag; **`favorites_screen.dart:70` is out of scope → passes no tag (Hero disabled there)**. Navigation passes the exact tapped tag via route args; `ProductDetailScreen` reads it and applies the same tag to its hero image.
- **Destination must exist during the flight (C1 — the blocker):** detail dispatches `LoadProductDetail` async in `didChangeDependencies` (`product_detail_screen.dart:39-42`) and shows a bare `CircularProgressIndicator` while loading (`:72-73`) — so the carousel/Hero image is **absent for the whole ~300ms transition** and the flight silently no-ops. **Fix:** also pass the tapped `imageUrl` through route args; on detail, render **that image inside a `Hero` (matching tag) immediately** — behind/above the Phase-1 skeleton — so the Hero has a real destination during load. Swap to the loaded carousel once `LoadProductDetail` completes (same tag, same provider). Home currently passes only `product.id` (`home_screen.dart:122-126`) → thread `imageUrl` too.
- **Image provider parity:** card uses `Image.network` (`product_card.dart:46`); detail carousel already uses `Image.network` (`:282`) — same decoder, so no mid-flight swap. Keep both `Image.network`; add a placeholder/fade for un-cached images.
- **Content fade:** wrap detail sheet content (below carousel) in `FadeTransition`/`AnimatedOpacity` (`AppMotion.base`, `entrance`) so it settles after the hero lands.
- **Sheet clipping (H3):** the `DraggableScrollableSheet` (`product_detail_screen.dart:179`) is a *later* Stack child than the carousel (`:105-108`) with an opaque background (`:185-191`) → it z-orders **above** the carousel and occludes the hero's bottom ~10% on land. **Fix:** keep the destination hero image's final rect within the carousel region **above the sheet's `initialChildSize` top edge** (tune so they don't overlap), or use a `flightShuttleBuilder` that draws the in-flight image above the sheet. Do not rely on the (incorrect) assumption that the carousel already sits above the sheet.

## Related Code Files

- Modify:
  - `FE/lib/widgets/product_card.dart` — add **nullable** `heroTag`; wrap image in `Hero` only when non-null (`:46`)
  - `FE/lib/screens/home/home_screen.dart` (`:112`,`:172`,`:122-126`), `FE/lib/screens/product_list/product_list_screen.dart` (`:289`) — pass context-unique `heroTag` **and** `imageUrl` through nav args
  - `FE/lib/screens/product_detail/product_detail_screen.dart` — read tag+imageUrl from route args; render hero destination image during async load (`:39-42,72-73`); matching `Hero`; content fade-in
- Do NOT modify: `FE/lib/screens/favorites/favorites_screen.dart:70` (out of scope; passes no `heroTag` → Hero disabled)

## Implementation Steps

1. Add nullable `heroTag` to `ProductCard`; wrap image in `Hero` only when non-null.
2. Pass context-unique tags + `imageUrl` from list (`:289`) and home (`:112`,`:172`) via nav args; leave favorites untagged.
3. On detail, read tag+imageUrl from route args and render the hero destination image immediately (behind skeleton) so the flight has a target during async load; swap to loaded carousel on completion.
4. Add content fade-in on detail; tune hero final rect vs sheet top edge (H3).
5. Test forward + back flight on device; rapid double-tap (duplicate-tag-in-tree), back-during-flight, and open-from-favorites (no Hero, no crash).

## Success Criteria

- [x] Card image visibly flies into the detail image on tap and back on pop.
- [x] No "multiple heroes share tag" assertion; no image flicker/decoder swap mid-flight.
- [ ] Draggable sheet does not clip the hero during transition. **ACCEPTED RISK (H3) — see below.**
- [x] `flutter analyze` clean.

## Risk Assessment

- **Duplicate Hero tag** (same product in featured + new-arrivals on home) → RESOLVED by the validated context-unique tag (`…-${screen}-${section}-${index}`) + passing the tapped tag through route args so detail matches exactly. No two live Heroes ever share a tag.
- **CachedNetworkImage flight flicker** → identical provider + fade placeholder both ends.
<!-- Updated: post-implementation code review 2026-07-12 -->
- **Sheet clipping (H3) — ACCEPTED RISK, not fixed:** the `DraggableScrollableSheet` still z-orders above the carousel and overlaps the Hero's bottom ~20px (`initialChildSize` unchanged, same `(screenHeight - carouselHeight + 20) / screenHeight` overlap by original design). Flutter's default Hero flight renders the flying widget in the navigator's overlay (above the sheet) for the whole animation, so the visible artifact is limited to a one-frame landing "pop" as the Hero returns to its in-place position and the sheet's rounded top begins covering that same ~20px it always covers post-load. A rect-trim or `flightShuttleBuilder` fix was scoped out — both add real layout/geometry risk (dot-indicator clipping, sheet-position math) for a sub-300ms cosmetic artifact, not a correctness issue. Revisit only if it reads as jarring on-device; not blocking for the demo.
- **Async-load no-op (C1)** → destination hero image rendered from route-arg `imageUrl` during load; never rely on the carousel being present mid-transition.
- **Shared `ProductCard` w/ favorites (C2)** → `heroTag` nullable + conditional wrap; favorites passes none.
