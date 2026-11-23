# Implementation status

## Slice 1 — Android/Flutter foundation

Branch: `feature/android-dialer-foundation`

### Added
- Flutter/Dart application entry point and a responsive starter keypad.
- Pearl Light and Midnight Dark Material 3 themes with system theme selection.
- Android Gradle Kotlin DSL project configuration.
- Android dialer intent filters and an `InCallService` declaration.
- Native Kotlin method channel for requesting the default-dialer role and placing an outgoing call through `TelecomManager`.
- Native call registry receiving Telecom call-added/call-removed callbacks.
- Minimal Moog's Phone launcher mark.
- Initial widget tests.

### Not complete yet
This is a source foundation, not a releasable dialer APK. The native `InCallService` currently tracks the active `Call` only; Flutter incoming/active call screens and answer, reject, hold, mute, DTMF, audio-route and disconnect controls are not yet connected. Runtime permission flows, contacts and call-log providers, dual-SIM selection, local persistence, backup/restore, blocking, ringtone selection and device-specific MIUI validation remain future slices.

### Build prerequisites
- Flutter SDK installed.
- Android SDK and JDK 17.
- Run `flutter pub get`, then `flutter test` and `flutter build apk --debug`.

The repository does not include a Gradle wrapper binary or a built APK in this slice. Build and test on a development machine before installing on the Redmi 9 Activ.

## Product constraints carried forward
- Offline-first; no app-owned backend, analytics, ads or tracking.
- Android Contacts and Call Log providers are accessed only after runtime permission and role requirements are satisfied.
- Call recording remains deferred pending explicit product/legal review.
- Overlay, dynamic launcher icon and 3D portrait effects remain best-effort/optional.
