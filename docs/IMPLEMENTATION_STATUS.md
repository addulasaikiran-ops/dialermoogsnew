# Implementation status

Last reviewed: 2026-11-24

## Implemented in the current main branch

- Flutter application shell with Pearl Light and Midnight Dark themes.
- Four-tab navigation: Favorites, Recents, Contacts and Keypad; Keypad is the initial tab.
- Liquid Glass surfaces, animated Aurora backdrop, Moog logo, reduced-motion and reduce-effects support.
- Dialer keypad interactions, SIM-slot selection UI and outgoing-call handoff through Android Telecom.
- Android default-dialer role request flow and native InCallService call lifecycle bridge.
- Incoming and active call UI, answer/decline/end, mute, speaker, hold and in-call DTMF controls.
- Contacts and call-history read views through Android providers, subject to runtime permissions.
- Local favorites persistence.
- Widget tests for navigation, keypad entry, long-press behavior, slide-to-answer, themes, semantics and larger text.

## Not implemented or not yet device-validated

- Contact creation/edit/delete, contact photos/posters and call-screen contact-photo lookup.
- Full T9 contact matching and suggestions.
- Recents filtering, individual deletion and clear-all.
- Blocking, ringtone picker, local vCard backup/restore and call insights.
- Bluetooth audio routing and wired-headset route selection.
- Simultaneous-call UX and real-device verification of call switching/holding.
- Dual-SIM selection across carrier and MIUI variants.
- Incoming/outgoing SIM-call validation, lock-screen behavior and notification behavior on Redmi 9 Activ.
- Dynamic launcher icon, optional overlay window and 3D portrait effects remain best-effort.
- Call recording remains deferred pending explicit product/legal review.

## Build and verification

- Flutter quality checks run dependency resolution, formatting, static analysis and widget tests.
- Android Kotlin compilation is verified separately with JDK 17 and Gradle 8.7. CI generates a temporary Gradle wrapper and compiles `:app:compileDebugKotlin`; it does not upload or publish an APK artifact.
- Run `bash tool/prepare_assets.sh` before `flutter pub get` in a fresh checkout. The script stages the Manrope variable font and required image directory from Google Fonts.
- For a complete local Android build, install Flutter, Android SDK and JDK 17, then run `flutter pub get` and `flutter build apk --debug`.

## Product constraints

- Offline-first; no app-owned backend, analytics, ads or tracking.
- Android Contacts and Call Log providers are accessed only after runtime permission.
- Call recording remains deferred; no covert recording.
- Overlay, dynamic launcher icon and 3D portrait effects remain optional/best-effort.
