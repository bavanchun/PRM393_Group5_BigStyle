---
phase: 1
title: "Shared VND currency formatter"
status: done
effort: "0.5d"
priority: P1
dependencies: []
---

# Phase 1: Shared VND currency formatter

## Overview
Replace every raw `'${x.toStringAsFixed(0)}đ'` price display with one shared `formatVnd()` helper so all prices render with thousands separators (`10.000đ`). Highest user-visible defect from `qa-260710-1827`: a 350.000đ item currently shows `350000đ` at every decision point of the purchase funnel.

## Requirements
- Functional: one function, `formatVnd(num) → '10.000đ'` (vi_VN grouping = `.`), used everywhere a VND amount is displayed — **including the two extra local formatters red-team found beyond the original census** (voucher list, admin dashboard grouping branch).
- Non-functional: no behavior change beyond formatting; DRY — delete ALL local grouping implementations (4 total, not 2).

## Architecture
**Decision:** standardize on **no-space suffix** `10.000đ` (Shopee/Tiki convention, already what `manager_product_list_screen._formatPrice` produces). This changes manager order cards from `40.000 đ` (current `NumberFormat.currency` output, space before đ) to `40.000đ` — accepted, unifies all coexisting styles into 1.

New file `FE/lib/utils/currency_format.dart` (dir exists, holds `slug.dart`):
```dart
import 'package:intl/intl.dart';

final NumberFormat _vndGrouping = NumberFormat('#,###', 'vi_VN');

/// App-wide VND display format: whole-đồng amounts with dot grouping,
/// no space before the đ suffix (e.g. 350000 → "350.000đ").
String formatVnd(num amount) => '${_vndGrouping.format(amount)}đ';
```
`intl ^0.19.0` already in pubspec. Number patterns need no locale init (verified: existing manager code + tests already use `NumberFormat` with `vi_VN`).

**Documented exemption:** `admin_dashboard_screen.dart` `_formatCurrency` compact notation (`tỷ`/`triệu` for large revenue) is deliberate summarization and KEEPS its compact branches — but its plain grouping branch (`:298`) must delegate to `formatVnd` instead of regex grouping.

## Related Code Files
- Create: `FE/lib/utils/currency_format.dart`, `FE/test/utils/currency_format_test.dart`
- Modify (17 `toStringAsFixed(0)…đ` occurrences, verified by grep @ fab9a26):
  - `FE/lib/widgets/product_card.dart:140,148`
  - `FE/lib/blocs/product_detail/product_detail_state.dart:25,30` (inside getters `displayPrice`/`displayOriginalPrice`)
  - `FE/lib/screens/product_detail/product_detail_screen.dart:167` (share text), `:369,375`
  - `FE/lib/screens/cart/cart_screen.dart:224,334`
  - `FE/lib/screens/cart/cart_item_edit_screen.dart:217`
  - `FE/lib/screens/checkout/checkout_screen.dart:478` (button label `Đặt hàng (…)`)
  - `FE/lib/screens/checkout/widgets/checkout_price_summary.dart:65`
  - `FE/lib/screens/checkout/widgets/checkout_item_list.dart:57`
  - `FE/lib/screens/orders/orders_screen.dart:135`
  - `FE/lib/screens/orders/order_detail_screen.dart:132,328`
  - `FE/lib/screens/delivery/delivery_map_screen.dart:504`
- Modify (local-formatter consolidation — 4 implementations):
  - `FE/lib/screens/manager/manager_order_card.dart:11-17` — delete local `_currencyFormat` + `formatOrderCurrency`, replace its 4 usages (`manager_order_card.dart:96`, `manager_order_detail_screen.dart:223,293`, `manager_dashboard_widgets.dart:25`) with `formatVnd`; fix imports (dashboard widgets currently import the fn from manager_order_card)
  - `FE/lib/screens/manager/products/manager_product_list_screen.dart:37-40` — delete local `_formatPrice`, use `formatVnd`
  - `FE/lib/screens/manager/vouchers/manager_voucher_list_screen.dart:155-163` — delete local `_formatVnd` (name-collides with the new shared helper — the import swap resolves it), usage at `:152`
  - `FE/lib/screens/admin/admin_dashboard_screen.dart:298` — `_formatCurrency`'s plain-grouping branch delegates to `formatVnd`; compact `tỷ`/`triệu` branches unchanged (documented exemption above)

## Implementation Steps
1. Create `currency_format.dart` + unit tests.
2. Sweep the 17 customer-side occurrences → `formatVnd(...)`; add imports.
3. Consolidate the 4 local formatters (manager order card, manager product list, manager voucher list, admin dashboard grouping branch).
4. Guard sweep (red-team-hardened — old greps were blind to formatters that don't put `đ` on the same line):
   - `grep -rnE "toStringAsFixed\(0\)\}? ?đ" FE/lib` → 0
   - `grep -rn "NumberFormat" FE/lib --include="*.dart" | grep -v "utils/currency_format.dart"` → 0
   - `grep -rnE "String _format(Price|Vnd|Currency)" FE/lib` → only `admin_dashboard_screen.dart` `_formatCurrency` (compact wrapper, delegates grouping to formatVnd) may remain
5. `flutter analyze` + `flutter test`.
6. Emulator spot-check: customer home card, product detail, cart, checkout summary + manager voucher list ("Giảm 20.000đ") show separators.
7. Commit.

## Success Criteria
- [ ] `formatVnd(0)=='0đ'`, `formatVnd(10000)=='10.000đ'`, `formatVnd(350000)=='350.000đ'`, `formatVnd(1234567)=='1.234.567đ'` (unit tests)
- [ ] All 3 guard greps in step 4 pass
- [ ] analyze/tests green; emulator spot-check shows separators
- [ ] 1 commit

## Risk Assessment
- Decimal amounts round via `#,###` — all VND amounts are whole (`double` but integral); acceptable.
- Manager card visual delta (space removed) — deliberate, documented above.
- Voucher screen's deleted `_formatVnd` shares the shared helper's name — compile catches any missed swap.
- Shares `manager_dashboard_widgets.dart` with phase 3 (different hunks: `:25` here, `:33/:88-104` there); execute sequentially, never in parallel.
