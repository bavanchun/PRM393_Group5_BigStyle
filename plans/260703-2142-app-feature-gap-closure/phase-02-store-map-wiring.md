---
phase: 2
title: Store Map Wiring
status: completed
priority: P3
dependencies: []
---

# Phase 2: Store Map Wiring

## Overview
Connect the already-built `DeliveryMapScreen` (Google Map + live location +
Directions route) to the app: profile "Cửa hàng" opens it instead of a
placeholder sheet, and its "Chỉ đường" button actually launches external Google
Maps.

## Requirements
- Functional: profile → "Cửa hàng" → real map screen; "Chỉ đường" opens Google
  Maps app/web with directions to the shop.
- Non-functional: graceful fallback if no maps app (open in browser).

## Architecture
Route `/delivery-map` already registered and imported in `app_router.dart`, but
nothing navigates to it. Swap the placeholder `showModalBottomSheet` in
`profile_screen.dart` for `Navigator.pushNamed('/delivery-map')`. The "Chỉ đường"
handler currently only shows a snackbar; replace with `url_launcher` (new dep)
launching the Google Maps directions URL to the hardcoded shop coords.

## Related Code Files
- Modify: `FE/pubspec.yaml` — add `url_launcher: ^6.3.0` (verify latest compatible).
- Modify: `FE/lib/screens/profile/profile_screen.dart`
  - "Cửa hàng" menu item (lines ~124-129): change `onTap` to
    `Navigator.pushNamed(context, '/delivery-map')`.
  - Delete now-unused `_showMap()` (lines ~197-243) and its placeholder.
- Modify: `FE/lib/screens/delivery/delivery_map_screen.dart`
  - `_openGoogleMaps()` (lines ~283-290): replace snackbar with
    `launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${_shopLocation.latitude},${_shopLocation.longitude}'), mode: LaunchMode.externalApplication)`.
  - Import `package:url_launcher/url_launcher.dart`.
- No change: `config/routes/app_router.dart` (route already present).

## Implementation Steps
1. Add `url_launcher` to pubspec; `flutter pub get`.
2. iOS: add `LSApplicationQueriesSchemes` (`comgooglemaps`, `https`) to
   `Info.plist` if launching the native app scheme is desired; the `https://`
   maps URL works without it (browser/Maps handles it). Keep to the `https` URL
   for KISS.
3. Rewire the "Cửa hàng" `onTap` to push `/delivery-map`.
4. Replace `_openGoogleMaps` body with `launchUrl`; wrap in try/catch → snackbar
   on failure.
5. Remove the dead `_showMap` placeholder.

## Success Criteria
- [x] Profile "Cửa hàng" opens the real map (marker, route, distance/ETA render).
      <!-- device-verified: blank-map root cause (missing Android Maps SDK key) fixed and tiles+marker confirmed live after keyed rebuild (commit 666a7e6); shop card + route fallback verified live earlier -->
- [ ] "Chỉ đường" opens Google Maps (app or browser) with directions. <!-- launchUrl + fallback code exists (delivery_map_screen.dart:325); external handoff never observed on device — not device-verified; deferred to device pass (plans/260712-1644 Phase 1) -->
- [x] No dead placeholder sheet remains. <!-- evidence: commit 2152eac deletes _showMap() from profile_screen.dart; confirmed absent in current file -->
- [x] `flutter analyze` clean; builds on Android (and iOS if available). <!-- analyze re-verified 2026-07-12; Android debug builds proven by repeated emulator smokes; iOS never attempted -->

## Risk Assessment
- `url_launcher` platform config: `canLaunchUrl` may return false without proper
  query schemes on iOS. Mitigation: use the `https://www.google.com/maps` URL
  (universally launchable) + `LaunchMode.externalApplication`.
- Shop coords are hardcoded (`10.7758,106.7048`) — acceptable for single-store
  demo; note as known limitation.
