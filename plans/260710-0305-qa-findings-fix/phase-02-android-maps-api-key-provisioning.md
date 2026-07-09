---
phase: 2
title: "Android Maps API Key Provisioning"
status: completed
priority: P1
dependencies: []
effort: "2.5h"
---

# Phase 2: Android Maps API Key Provisioning

<!-- Updated: Red Team Session 2026-07-10 — two-key strategy, KTS pinned, empty-key runtime check, missing-key warning -->

## Overview

Fix QA finding High: native Google map viewport is blank because
`AndroidManifest.xml` has no `com.google.android.geo.API_KEY`. Provision via a
build-time manifest placeholder read from `local.properties`/env.

Red-team corrections applied:
- **Two-key strategy is mandatory.** `.env` is bundled into the APK as a Flutter asset (`FE/pubspec.yaml:41`), so the dotenv `GOOGLE_MAPS_API_KEY` used for the Directions REST call (`FE/lib/config/app_config.dart:8-9`, consumed in `FE/lib/screens/delivery/delivery_map_screen.dart`) is client-extractable by unzipping any APK — and Google rejects Android-app-restricted (package+SHA-1) keys for the Directions Web Service. One shared key either leaks unrestricted or silently breaks Directions with `REQUEST_DENIED`.
- Only `FE/android/app/build.gradle.kts` exists (Kotlin DSL — no groovy file); exact KTS snippet included below.
- Empty-key builds produce a NEW runtime state (meta-data present but empty) that differs from today's missing-meta-data blank map and can crash MapView on some Play Services versions — must be runtime-verified, and missing keys must warn at build time.

## Requirements

- Functional: `google_maps_flutter` renders tiles, shop marker, and route polyline on the Store/Delivery screen; Directions REST keeps working.
- Non-functional: Android SDK key absent from git AND from the APK's Flutter assets; keyless builds compile, warn at build time, and do not crash at runtime; no new Gradle plugin.

## Architecture

Two keys, two channels:

| Key | Restriction | Storage | Exposure model |
|---|---|---|---|
| Android Maps SDK key | Package name + SHA-1 (debug + release), API: Maps SDK for Android | `FE/android/local.properties` (gitignored, `FE/android/.gitignore:6`) or `GOOGLE_MAPS_API_KEY` env var → gradle `manifestPlaceholders` → manifest meta-data | Compiled into APK but unusable outside the signed package |
| Directions REST key | API restriction: Directions API only + daily quota cap + billing alert | `.env` (current mechanism unchanged) | Accepted as client-visible (bundled asset); quota cap bounds abuse. Proxying via a Supabase Edge Function noted as future hardening, out of scope (YAGNI for course project) |

`build.gradle.kts` — as implemented (requires `import java.util.Properties` at file
top; a bare `java.util.Properties()` inline reference fails Kotlin script
compilation inside the `defaultConfig` block with "Unresolved reference: util"):

```kotlin
val mapsApiKey: String = run {
    val props = Properties()
    val localProps = rootProject.file("local.properties")
    if (localProps.exists()) {
        localProps.inputStream().use { props.load(it) }
    }
    props.getProperty("GOOGLE_MAPS_API_KEY")
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""
}
if (mapsApiKey.isEmpty()) {
    logger.warn(
        "GOOGLE_MAPS_API_KEY not set in android/local.properties or " +
            "env — native map will not render on this build."
    )
}
manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
```
<!-- Updated: Implementation — snippet corrected to match FE/android/app/build.gradle.kts (Kotlin script needs the top-level import; inline java.util.Properties() does not resolve inside defaultConfig) -->

Manifest (inside `<application>`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}" />
```

## Related Code Files

- Modify: `FE/android/app/src/main/AndroidManifest.xml`
- Modify: `FE/android/app/build.gradle.kts` (Kotlin DSL — pinned; groovy variant does not exist)
- Modify: `FE/.env.example` (document the split: dotenv key = Directions REST only; SDK key goes in `android/local.properties` as `GOOGLE_MAPS_API_KEY=`)
- Modify: `docs/deployment-guide.md` or README section — key setup for teammates (red-team: `local.properties` is machine-local and tooling-rewritten; without docs, fresh clones silently regress to blank maps)

## Implementation Steps

1. Add the KTS key-loading block + warn + `manifestPlaceholders` (snippet above).
2. Add the manifest meta-data entry.
3. Document two-key setup in `.env.example` + deployment doc (both machines/teammates and CI).
4. External (user): Google Cloud — enable Maps SDK for Android; create SDK key restricted to package + debug/release SHA-1; create/restrict the Directions key (API restriction + quota cap + billing alert). Decide which GCP project (open question from QA report).
5. **Keyless runtime check:** build WITHOUT a key, install, open Store/Delivery screen → must not crash (blank map acceptable). If MapView crashes on empty value, gate the meta-data value to a documented dummy (`"MISSING_KEY"`) instead of empty string and re-verify.
6. With key in `local.properties`: `flutter build apk --debug`; **uninstall then reinstall** (key baked at install). Verify tiles + marker + polyline; verify Directions route still renders (separate key path). If tiles missing, check `adb logcat | grep -i "Authorization failure"` (SHA-1 mismatch signature).
7. Confirm no key value in `git diff`/tracked files AND the SDK key is not in `.env` (APK-asset channel).

## Success Criteria

- [x] Build succeeds with and without a key; keyless build logs the gradle warning (`GOOGLE_MAPS_API_KEY not set ...`, verified via `./gradlew assembleDebug`).
- [x] Keyless APK: Store/Delivery screen opens without crash — verified live on emulator (blank map, shop card + route fallback render, no logcat crash).
- [x] Keyed APK (after reinstall): map tiles + marker render — verified live (GCP project `gmailapi-438621`, Maps SDK for Android enabled via `gcloud services enable maps-android-backend.googleapis.com`, key created + restricted to package `com.bigstyle.bigstyle_app` + the shared debug-keystore SHA-1 via `gcloud services api-keys create`/`update`, billing was already enabled on the project). Directions REST (in-app 0.5km fallback + shop card) unaffected — separate key, untouched. "Chỉ đường" hands off to the external Google Maps app for turn-by-turn (existing behavior, unrelated to the in-app MapView bug this phase fixes).
- [x] SDK key absent from tracked files and from `.env`/APK assets; `git grep` clean.
- [x] Teammate setup documented (README.md + .env.example, two-key split explained).

## Risk Assessment

- SHA-1 restriction mismatch → blank tiles; diagnose via logcat "Authorization failure".
- Externally blocked until user supplies keys → steps 1-3 committable now; runtime checks pending.
- Rollback: remove meta-data + gradle block; no data impact.
