# Moog's Phone — Product Requirements Document

**Status:** Requirements baseline v1.0  
**Product name:** Moog's Phone  
**Platform:** Android only  
**First test device:** Xiaomi Redmi 9 Activ, Android 11, 4 GB RAM  
**Distribution:** Direct APK (testing and release builds)  
**Business model:** Free, no ads, no subscriptions

## 1. Product vision

Moog's Phone is a premium Android phone and contacts app with an iOS 26-inspired Liquid Glass visual language. It should feel polished, responsive and distinctive while remaining a genuine Android dialer—not a visual mockup or web wrapper.

The first real-device target is the user's Redmi 9 Activ. The app should be designed for broad Android compatibility, but performance and calling behavior must be validated on that device before wider release.

## 2. Product principles

1. **Native Android calling first.** Use Android Telecom and the default-dialer role for real calls.
2. **Offline-first and privacy-focused.** Core features must not depend on internet access. No ads, analytics SDKs, tracking SDKs or app-owned cloud services.
3. **Premium, but performant.** Use restrained blur, gradients and layered surfaces; provide fallbacks for devices that cannot render expensive effects smoothly.
4. **Use the phone's contacts.** Read and write the Android Contacts Provider rather than maintaining a separate, disconnected address book.
5. **Be honest about platform limits.** Features controlled by Android, launchers, carriers or manufacturers must be treated as conditional and tested on-device.

## 3. Visual identity

- **App label:** Moog's Phone
- **Logo concept:** Original, stylish M-shaped telephone receiver symbol; not a DM monogram and not a generic handset glyph.
- **Finish:** Liquid-silver / polished chrome.
- **Accent:** Ice blue.
- **Dark palette:** Midnight / deep navy with silver and ice-blue highlights.
- **Light palette:** Pearl white with silver and ice-blue highlights.
- **Missed-call treatment:** Silver M with a glowing red receiver accent. Launcher-specific icon changes are best-effort because launcher behavior varies.
- **Splash animation:** Smooth glass-to-metal transition. It must be short, skippable by reduced-motion/system conditions, and must not delay access to the keypad.
- **Design direction:** iOS 26-inspired Liquid Glass, but with original assets and Android-native behavior. Do not copy Apple's proprietary assets or imply Apple affiliation.

## 4. Navigation and screens

Bottom navigation, in this order:
1. Favorites
2. Recents
3. Contacts
4. Keypad

The app opens to **Keypad** by default.

Required screens:
- Phone / floating-glass keypad
- Recents / call history
- Favorites
- Contacts list
- Contact details
- Incoming call
- Outgoing call
- Active call
- Settings

Settings is opened separately, not as a bottom tab.

### 4.1 Keypad
- Large floating translucent number buttons with depth/reflection treatment.
- Contact/T9 matching while typing.
- Call action and delete/backspace.
- Long-press 0 for +.
- Gentle haptic feedback and subtle keypad sound, respecting Android system settings.
- Keep input, touch targets and call action accessible on small screens.

### 4.2 Recents
- All, Missed, Incoming and Outgoing filters.
- Contact photo/name/number, timestamp and duration where available.
- Group repeated calls from the same number/contact.
- Call details and quick call/message actions.
- Swipe actions where accessible and discoverable.
- Retain history until the user deletes it; no automatic 30/90-day cleanup.
- Individual deletion and clear-all with confirmation.
- Use Android CallLog as the source of truth where permissions/role allow. The system may limit fields or retention.

### 4.3 Favorites
- Liquid Glass contact cards with circular photos, names and quick-call actions.
- Add/remove favorites.
- Favorites should be represented using native contact data where practical; app-only presentation preferences may be stored locally.

### 4.4 Contacts
- Read existing device contacts and create/edit/delete contacts using Android Contacts Provider.
- Changes made in Moog's Phone should appear in other apps that use the same Android contact database.
- Search, alphabetical list and A–Z fast-scroll index.
- Pinned favorites and clear grouping.
- Support multiple phone numbers, email addresses, company, address, notes, birthday/important dates and contact photos when provided by the Android provider.
- Respect contact account ownership and permissions; do not silently move contacts between accounts.
- Message shortcut opens the user's existing SMS app. No built-in SMS/RCS client.

### 4.5 Contact details and posters
- Large contact photo/poster, contact name and prominent Call/Message actions.
- Display phone numbers, email, company, address, notes, dates and recent calls where available.
- Edit, share, favorite and block actions where supported.
- Simple poster editor: choose photo, background and name styling; preview and save.
- Optional depth effect is an enhancement only if it can be implemented efficiently; do not make it a release blocker.
- Contact poster is app presentation data unless a compatible Android contact-photo field is explicitly updated with user consent.

### 4.6 Incoming, outgoing and active calls
- Use Android Telecom APIs and the required default Phone app role.
- Implement the required InCallService behavior and Android call lifecycle.
- Custom Liquid Glass incoming, outgoing and active call UIs.
- Incoming screen: caller identity, poster/photo where available, answer and decline actions.
- Outgoing screen: contact poster/photo, calling/connecting state, end-call action.
- Active screen: caller identity, elapsed call duration, mute, keypad, speaker, hold and audio-route/Bluetooth controls when available; prominent end-call action.
- Start the timer when the call is actually active, not when the user taps Call.
- Follow Android's call presentation rules: full-screen UI, heads-up/compact presentation and lock-screen behavior depend on OS state, notification policy and device configuration.
- Ongoing-call notification with return-to-call action and appropriate controls.
- Optional floating mini-call window is a later enhancement and must be permission-based, non-obstructive and tested on MIUI. Do not require overlay permission for core calling.
- Respect system call audio routing, Bluetooth, wired headsets, carrier behavior and dual-SIM state.

## 5. Advanced features requested

- T9 smart search.
- Saved-contact caller identification (offline; no online reputation lookup).
- Number blocking / personal block list where Android's supported APIs and default-dialer privileges permit.
- Dual-SIM support with SIM selection and sensible preferred-SIM behavior.
- Local contact backup and restore (user-initiated export/import, preferably vCard .vcf).
- Custom ringtone selection using Android-supported ringtone APIs.
- Call statistics/insights derived locally from available call-log data.
- Call recording was requested, but it is **not guaranteed**: Android versions, device manufacturers, carrier behavior and local law may prohibit or restrict it. Do not implement covert recording. Any future implementation requires a separate legal/privacy review, clear user-visible consent and device-specific feasibility testing.
- Spam identification service was explicitly declined. Basic user-managed blocking is separate from spam-detection services.

## 6. Settings and customization

- Light / Dark / Follow system theme.
- Basic settings only; no large theme marketplace or extensive visual customization.
- Haptics and sound preferences, respecting system settings.
- Call preferences and preferred SIM.
- Contact display preferences.
- Privacy and permission explanations.
- Local backup and restore.
- No app lock.
- English-only interface for the initial release.

## 7. Offline, privacy and data handling

- Core app functions must work without an internet connection.
- No app-owned backend, account system, cloud sync, ads, analytics or tracking.
- Store app-specific preferences and poster metadata locally.
- Use Android Contacts Provider and CallLog rather than duplicating system data unnecessarily.
- User-requested local backup/restore only.
- The earlier preference for Google backup/sync is superseded by the later decision that the app must be completely offline. The app will not initiate Google/cloud backup or sync.
- Important nuance: Android contacts can belong to Google or other accounts. The Android operating system or account provider may sync those records according to the user's device settings, independently of Moog's Phone. The app itself must not initiate network sync.
- Explain permissions at the point of use and request only those required for a feature.

## 8. Performance and accessibility

- First target: Redmi 9 Activ, Android 11, 4 GB RAM.
- Aim for smooth 60 Hz interaction where the device can sustain it; do not promise a fixed frame rate.
- Keep startup fast and avoid long splash delays.
- Use blur and backdrop effects selectively; provide lower-cost fallbacks.
- Avoid persistent background services unless required by Android calling behavior.
- Support system font scaling, adequate contrast, accessible labels and large touch targets.
- Respect system animation/reduced-motion settings where practical.
- Test memory, battery, heat, incoming-call reliability and behavior after process death.

## 9. Distribution and release

- Android only.
- Provide a directly installable APK for testing and distribution.
- Produce a broadly compatible release APK and device-appropriate testing builds when useful.
- Sign release builds with a stable signing key; document safe key backup. Updates must use the same signing identity.
- Do not claim a universal APK is optimized for every device; validate ABI and minimum SDK choices before release.
- No Play Store release is required for the initial plan.

## 10. Acceptance criteria for the first usable release

1. The app can request and obtain Android's default Phone app role on supported devices.
2. Incoming and outgoing cellular calls can be answered, declined, placed and ended reliably.
3. Active call controls operate on the real Telecom call state.
4. Contacts can be listed, searched, created and edited through Android Contacts Provider.
5. Recents reflect available system call-log data and support the selected filters.
6. Favorites and the four-tab navigation work; Keypad is the initial tab.
7. Light, dark and system themes work.
8. Core features work with mobile data and Wi-Fi disabled.
9. No ads, analytics or tracking SDKs are present.
10. The app installs and is usable on the Redmi 9 Activ running Android 11.
11. Permission denial and revocation are handled gracefully.
12. App can hand control back to the previous default dialer if the user changes the default app.

## 11. Explicitly deferred / conditional

- Call recording: deferred pending legal and technical feasibility review.
- Floating mini-call overlay: optional later phase; not required for first release.
- 3D portrait/depth effects: optional enhancement.
- Dynamic launcher icon color: best-effort; launcher-dependent.
- Google/cloud backup and app-initiated sync: excluded to preserve offline-only requirement.
- Spam identification: not wanted.
- Built-in SMS/RCS: not wanted.
- Voicemail screen: not selected.

## 12. Open validation items

These are engineering checks, not unresolved product preferences:
- Confirm Redmi 9 Activ firmware/MIUI version and exact Android API level.
- Validate default-dialer role and InCallService behavior on the device.
- Validate call-log and contacts permission behavior after role grant.
- Confirm device ABI and supported Flutter/Android build toolchain.
- Test dual-SIM account selection and call audio routing.
- Verify launcher behavior for missed-call icon/badges.
- Verify ringtone and block-number APIs on the target device.
