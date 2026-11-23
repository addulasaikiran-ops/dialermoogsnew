# Call lifecycle implementation

## Native-to-Flutter flow

1. Android Telecom binds `MoogsInCallService` for the default dialer.
2. `onCallAdded` registers the platform `Call`, installs a `Call.Callback`, and publishes the first snapshot.
3. Call-state/details callbacks publish snapshots through the `com.moogs.phone/call_events` EventChannel.
4. Flutter subscribes to the event stream and renders the incoming or active call screen from the real Telecom state.
5. If the app UI is not foregrounded, the service posts a high-importance call notification with a full-screen Activity intent for ringing calls and a content intent for ongoing calls.
6. Flutter sends actions over `com.moogs.phone/telecom`; Kotlin delegates to Telecom's `Call` and `InCallService` APIs.

## Implemented controls

- Answer: `Call.answer(STATE_AUDIO_ONLY)`
- Reject: `Call.reject(false, null)`
- End: `Call.disconnect()`
- Mute: `InCallService.setMuted()`
- Speaker / earpiece: `InCallService.setAudioRoute()`
- Hold / resume: `Call.hold()` and `Call.unhold()`
- DTMF: `Call.playDtmfTone()` and `Call.stopDtmfTone()`

The UI displays the caller display name when Telecom provides one, otherwise the phone number. The connected timer uses Telecom's connection timestamp.

## Platform limitations and next work

- Android 13+ requires notification permission for call notifications. The app requests it on first launch; users can deny it.
- Android 14+ may restrict full-screen intent access based on system policy. In that case Android may show a heads-up/notification presentation instead of launching full screen.
- OEM power management and lock-screen policy can affect presentation; validate on the Redmi 9 Activ/MIUI firmware.
- The current bridge models one current call. Multi-call conferencing/swap and Bluetooth endpoint selection need a later extension.
- The current call screen uses a generic avatar. Contact lookup and contact poster rendering are not yet connected.
- No build, emulator test, SIM test, or physical-device test was run in this session. Do not treat the source as release-ready until built and exercised on a device with SIM service.
