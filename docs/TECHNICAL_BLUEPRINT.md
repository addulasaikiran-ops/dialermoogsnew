# Moog's Phone — Technical Blueprint

**Version:** 1.0  
**Chosen stack:** Flutter + Dart, with Kotlin Android platform integration  
**Target:** Android 11+ baseline for first-device testing; final minSdk to be confirmed after API review  
**Architecture:** Feature-first Flutter app + native Android Telecom/Contacts bridge

## 1. Architecture overview

Flutter owns the presentation layer and app navigation. Kotlin owns Android capabilities that require platform APIs or lifecycle integration.

```
Flutter UI (Dart)
  ├── Favorites / Recents / Contacts / Keypad
  ├── Contact details and poster editor
  ├── Settings and theme system
  └── Call UI state presentation
          │ MethodChannel / EventChannel
          ▼
Android host (Kotlin)
  ├── TelecomManager + InCallService
  ├── RoleManager / default dialer eligibility
  ├── ContactsContract provider
  ├── CallLog provider
  ├── PhoneAccountHandle / dual SIM
  ├── Audio routing / Bluetooth / ringtones
  ├── Notifications / full-screen call presentation
  └── Local file picker for vCard backup
          │
          ▼
Android OS, SIM/carrier, contacts accounts, launcher
```

The Flutter layer must not pretend to control a call independently. Kotlin/Telecom is the source of truth for call state; Flutter subscribes to native events and renders the current state.

## 2. Android calling requirements

### 2.1 Default dialer role
- Implement an activity that satisfies Android's default dialer requirements.
- Provide the appropriate intent filters and a valid InCallService declaration.
- Request the dialer role through RoleManager on supported Android versions; handle older supported APIs with the appropriate compatibility path.
- Explain why the role is needed and allow the user to decline.
- Never assume the role was granted; check current role state and provide a clear setup screen.

### 2.2 InCallService
- Implement a Kotlin InCallService and manage Call callbacks and lifecycle safely.
- Publish call state, caller handle, display name, call capabilities, disconnect cause and available audio routes to Flutter.
- Support multiple calls and state transitions, including ringing, dialing, active, holding, disconnected and conference/unknown states where supported.
- Answer, reject, disconnect, hold, unhold, mute, play DTMF and select audio route through supported Telecom APIs.
- Do not create a fake call timer; derive duration from real call state timestamps.
- Handle service recreation, process death and Flutter activity recreation.

### 2.3 Incoming call presentation
- Use Telecom's call UI flow and notification APIs.
- Full-screen intent is conditional on Android policy, notification permission/channel configuration and lock-screen state. Provide a heads-up/notification fallback.
- Keep answer/reject actions available and reliable even if Flutter UI is not foregrounded.
- Test behavior on MIUI, including battery restrictions and autostart/background settings.

### 2.4 Outgoing calls
- Place calls using supported Telecom intents/APIs after validating the phone number and requested account.
- Use PhoneAccountHandle for SIM selection where exposed.
- The call UI must follow the actual Telecom call state, not the return of the launch intent.
- Handle emergency numbers through Android/system behavior; do not intercept or customize emergency calling in a way that could impede it.

### 2.5 Notifications and mini-call
- Ongoing-call notification is part of the reliable baseline.
- Floating mini-call window is optional and deferred until core calling is stable. It may require overlay permission and can be restricted by MIUI; never make it mandatory.
- Prefer notification tap-to-return over overlay if device restrictions or accessibility concerns arise.

## 3. Contacts and call history

### 3.1 Contacts
- Use ContactsContract through Kotlin.
- Support read, insert, update and delete with explicit permission handling and confirmation for destructive actions.
- Preserve account association and raw-contact/data-row relationships.
- Query efficiently; use paging or incremental loading for large address books.
- Observe provider changes where appropriate and refresh Flutter state.
- Use stable contact IDs/lookup keys rather than relying on display names or phone numbers as unique identifiers.
- Contact photos should be loaded efficiently and cached with bounded memory.

### 3.2 Call log
- Use CallLog provider when access is granted through the default-dialer role / Android permissions applicable to the OS.
- Query only needed columns and paginate.
- Group calls for presentation without mutating system records.
- Deletion must call supported provider APIs and confirm bulk deletion.
- Call history availability and fields are OS/OEM-dependent; show graceful empty/permission states.

### 3.3 T9 search
- Normalize phone numbers and contact-name transliteration/mapping for the English keypad.
- Rank exact number matches, prefix matches and name-to-digit matches.
- Keep matching local; no external caller lookup.

## 4. Local persistence

Use a small local database (e.g. Drift/SQLite in Flutter) for app-owned data only:
- Theme preference.
- Favorite ordering if not represented by native contact starred state.
- Contact poster configuration and references to locally selected images.
- User preferences and onboarding state.
- Optional local call insight aggregates only if they cannot be derived efficiently from CallLog.

Do not duplicate the entire contacts database or call log into app storage unless a documented platform limitation requires a cache.

### Backup
- Local export/import using vCard (.vcf) for contacts, with a user-selected destination via Android's document picker.
- Warn that exporting contacts creates a sensitive file and let the user choose where it is stored.
- Import should preview changes and avoid accidental duplicate creation.
- No network calls, cloud backup or app-initiated Google sync.

## 5. Flutter app structure

Suggested layout:

```
lib/
  app/
    app.dart
    router.dart
    theme/
      app_theme.dart
      color_tokens.dart
      typography.dart
  core/
    platform/
      phone_platform.dart
      contacts_platform.dart
      call_log_platform.dart
    models/
    permissions/
    storage/
    widgets/
  features/
    keypad/
    recents/
    favorites/
    contacts/
    contact_details/
    contact_poster/
    calling/
      call_state.dart
      call_controller.dart
      incoming_call_page.dart
      outgoing_call_page.dart
      active_call_page.dart
    settings/
  main.dart

android/app/src/main/kotlin/.../
  MainActivity.kt
  dialer/
    MoogInCallService.kt
    TelecomController.kt
    CallStateRepository.kt
    DialerRoleManager.kt
  contacts/
    ContactsRepository.kt
  calllog/
    CallLogRepository.kt
  audio/
    AudioRouteController.kt
  notifications/
    CallNotificationManager.kt
  backup/
    VCardBackupManager.kt
```

Keep platform channels behind Dart interfaces so UI widgets do not call MethodChannel directly. Use EventChannel (or an equivalent event stream) for call-state updates.

## 6. Design system

### Color tokens
- Midnight background: deep navy, not pure black by default.
- Pearl background: soft cool white.
- Liquid silver: neutral metallic surfaces/highlights.
- Ice blue: primary accent and focus state.
- Alert red: missed-call receiver accent and destructive call actions.
- Text colors must meet contrast requirements in both themes.

### Rendering strategy
- Build glass effects from layered translucent fills, borders, gradients and restrained blur.
- Avoid large, continuously animated backdrop blurs on the Redmi 9 Activ.
- Provide a low-effects mode automatically if frame timing or device capability indicates the effect is too expensive; expose a simple performance fallback only if needed.
- Keep motion short and purposeful. Respect system animation settings.
- Avoid animating large photo layers while scrolling.

### Logo assets
- Create a clean vector master of the M-shaped receiver.
- Export launcher icon foreground/background and splash assets at Android-required sizes.
- Provide normal silver and missed-call red-accent variants.
- Do not use the promo mockup as the final launcher asset without producing a clean, legible icon master.

## 7. Permissions and privacy

Request permissions only when a user invokes a feature:
- READ_CONTACTS / WRITE_CONTACTS.
- CALL_PHONE where required for initiating calls.
- READ_CALL_LOG / WRITE_CALL_LOG only where applicable and permitted.
- POST_NOTIFICATIONS for Android versions requiring runtime notification permission.
- BLUETOOTH_CONNECT for supported Bluetooth route controls on relevant Android versions.
- READ_PHONE_STATE / phone-account access only where required for SIM/call behavior.
- READ_MEDIA_IMAGES or photo picker/document picker access for poster photos as appropriate.
- No INTERNET permission unless a reviewed dependency unexpectedly requires it; remove it from the final manifest if unused.
- No overlay permission for the first release.

All permission denials must have a usable fallback and a settings explanation. Never repeatedly prompt after permanent denial.

## 8. Build and compatibility

- Flutter stable channel and compatible Android Gradle Plugin/Kotlin versions must be pinned once scaffolded.
- Use Android App Bundle/APK build configuration with a documented release signing process.
- Choose minSdk after checking the APIs needed for default dialer and target device compatibility. Android 11 is the first-device target, not automatically the final minimum.
- Choose ABI splits only after inspecting the Redmi 9 Activ ABI; provide a universal APK if practical.
- Do not commit signing keys, passwords or local.properties.
- Configure lint, formatting and unit tests from the start.

## 9. Testing strategy

### Unit tests
- T9 number/name matching.
- Call-state reducer/state machine.
- Recents grouping and filters.
- Theme selection.
- Backup import validation and duplicate detection.

### Widget tests
- Four-tab navigation and default Keypad tab.
- Keypad input/delete/call action states.
- Recents filters.
- Contact list search and A–Z index.
- Contact detail actions.
- Light/dark/system themes.

### Android integration tests
- Default dialer role request and revoke.
- InCallService ringing/answer/reject/disconnect.
- Outgoing call and dual-SIM selection.
- Mute/speaker/hold/DTMF/audio route.
- Contacts CRUD and account preservation.
- Call log query and deletion.
- Notifications and lock-screen behavior.
- Permission denial/revocation.
- Process death and service/activity recreation.

### Device matrix
1. Redmi 9 Activ, Android 11, 4 GB RAM — primary acceptance device.
2. At least one newer Android version/device.
3. At least one device with a different OEM skin.
4. Test with network disabled to verify offline behavior.

## 10. Delivery phases

### Phase 0 — Foundation
- Create Flutter project scaffold and Android native integration skeleton.
- Add architecture, lint, test setup and CI.
- Build app shell with four tabs, theme system and custom design tokens.
- Add original logo assets when vector master is ready.

### Phase 1 — Contacts and local UI
- Contacts provider read/search/CRUD.
- Favorites and contact details.
- Keypad and local T9 matching.
- Basic local poster editor.

### Phase 2 — Real dialer
- Default dialer role.
- InCallService.
- Incoming/outgoing/active call screens.
- Call controls, call notification and call history.

### Phase 3 — Advanced capabilities
- Dual SIM.
- Blocking.
- Ringtones.
- Local vCard backup/restore.
- Call insights.
- Poster enhancements.

### Phase 4 — Hardening and APK
- Redmi MIUI testing and performance tuning.
- Permissions, privacy, accessibility and failure states.
- Signed universal/device-appropriate APKs.
- Release notes and install/update instructions.

## 11. Release blockers

Do not call the app release-ready until:
- Real incoming/outgoing calls work through Telecom.
- Default dialer role can be granted and revoked safely.
- Call audio controls work.
- Contacts CRUD works without corrupting account associations.
- App functions offline.
- No ads, analytics, tracking or unreviewed network dependencies exist.
- The Redmi 9 Activ test pass is complete.
- Release signing key is securely backed up.
