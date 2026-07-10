---
phase: 3
title: "Order-Linked Delivery Map"
status: completed
priority: P2
dependencies: []
effort: "M"
---

# Phase 3: Order-Linked Delivery Map

## Overview
Turn the standalone store-locator map into an order-delivery view: from a `shipping` order's detail, open the map routing shop → the order's stored shipping coordinates. Keep existing store-locator entry (profile) working unchanged.

## Requirements
- Functional: order detail (status `shipping`) shows "Xem lộ trình giao hàng" button → map with shop marker, destination = order's `shipping_address.latitude/longitude`, route polyline, distance/ETA; orders without coords → button hidden.
- Non-functional: no Google Directions key → existing straight-line + haversine fallback (in `_calculateRoute`, `delivery_map_screen.dart:~169-170`); no new deps.

## Architecture
- **No geocoding needed:** `OrderModel` already stores `latitude`/`longitude` (`FE/lib/models/order_model.dart:84-85`) written at checkout (`checkout_screen.dart:438-439,529-530`). Coords may be null when user typed address manually — hide CTA then.
- **Screen params:** `DeliveryMapScreen({LatLng? destination, String? destinationLabel, String? title})` — null → current behavior (customer GPS ↔ shop store-locator mode); non-null → delivery mode: origin = `_shopLocation` (existing const, L24), destination = order coords, marker label = order address text, skip customer-GPS requirement (don't block on location permission).
- **Routing:** existing `_calculateRoute` (note: actual symbol — there is no `_getRoute`) builds Directions URL origin=shop → destination=`_customerLocation`; delivery mode replaces the **destination source** (order coords instead of device GPS), direction is already correct. Fallback (straight line + haversine) already handles missing key.
- **CRITICAL — all three `_customerLocation` producers must respect delivery mode** (red-team): (1) `_initLocation` GPS path, (2) its catch-fallback hardcoding `LatLng(10.7728, 106.7018)` (~L59) — in delivery mode a GPS failure must NOT silently route to downtown-HCMC fallback masquerading as the customer address, (3) the recenter FAB's second `Geolocator.getCurrentPosition` (~L318) — disable or retarget recenter to the order destination in delivery mode. Delivery mode sets `_customerLocation = widget.destination` unconditionally and never calls Geolocator.
- **Router:** `/delivery-map` case (`app_router.dart:55-56`) reads optional `settings.arguments as Map?` → constructs params. Existing caller `profile_screen.dart:130` passes none → unchanged.
- **Order detail CTA:** in `order_detail_screen.dart`, when `status == shipping && order.latitude != null && order.longitude != null` show button below status timeline.

## Related Code Files
- Modify: `FE/lib/screens/delivery/delivery_map_screen.dart` (params + dual mode), `FE/lib/config/routes/app_router.dart` (args), `FE/lib/screens/orders/order_detail_screen.dart` (CTA)
- Tests: `FE/test/` — unit test for args-parsing helper (extract small pure function mapping route args → screen params), widget test for CTA visibility (shipping+coords vs pending / no coords)

## Implementation Steps (TDD)
1. **Tests first:** CTA visibility matrix (shipping+coords → visible; shipping w/o coords, delivered, pending → hidden); args-mapper unit test. Red.
2. Add params + delivery mode to `DeliveryMapScreen`: guard ALL THREE `_customerLocation` producers (initState `_initLocation`, catch-fallback, recenter FAB ~L318); camera bounds fit shop↔destination.
3. Router args plumbing; order-detail CTA.
4. `flutter analyze`, full tests. On-device route render deferred to Phase 5.

## Success Criteria
- [ ] Store-locator mode unchanged (profile entry works as before).
- [ ] Shipping order with coords opens map: shop + destination markers, polyline (or straight-line fallback), distance shown.
- [ ] CTA hidden when coords absent or status ≠ shipping.
- [ ] analyze 0, tests green.

## Risk Assessment
- Coords null for manually-typed addresses — handled by hiding CTA; do NOT add forward-geocoding (YAGNI; none exists in codebase).
- Google Maps API key may be absent in demo env — fallback path already ships; verify visually in Phase 5.
- `delivery_map_screen.dart` is 566 lines; adding mode may push past modularization threshold — extract route-fetch/polyline helpers into `FE/lib/screens/delivery/delivery-route-helpers.dart` only if edits make the file unwieldy (follow existing naming in that dir).
