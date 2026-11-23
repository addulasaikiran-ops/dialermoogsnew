package com.moogs.phone

import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.VideoProfile

class MoogsInCallService : InCallService() {
    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        MoogsCallRegistry.attach(call, this)
    }

    override fun onCallRemoved(call: Call) {
        MoogsCallRegistry.detach(call)
        super.onCallRemoved(call)
    }

    override fun onCallAudioStateChanged(audioState: CallAudioState) {
        super.onCallAudioStateChanged(audioState)
        MoogsCallRegistry.publish()
    }
}

internal object MoogsCallRegistry {
    @Volatile private var service: MoogsInCallService? = null
    @Volatile var currentCall: Call? = null
        private set
    @Volatile var muted: Boolean = false
        private set
    @Volatile var speaker: Boolean = false
        private set
    @Volatile var audioAvailable: Boolean = false
        private set
    @Volatile var eventSink: ((Map<String, Any?>) -> Unit)? = null

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) = publish()
        override fun onDetailsChanged(call: Call, details: Call.Details) = publish()
        override fun onPostDialWait(call: Call, remainingPostDialSequence: String) = publish()
    }

    fun attach(call: Call, inCallService: MoogsInCallService) {
        service = inCallService
        currentCall?.unregisterCallback(callback)
        currentCall = call
        call.registerCallback(callback)
        publish()
    }

    fun detach(call: Call) {
        call.unregisterCallback(callback)
        if (currentCall === call) {
            currentCall = null
            publish()
        }
    }

    fun setMuted(value: Boolean) {
        muted = value
        service?.setMuted(value)
        publish()
    }

    fun setSpeaker(value: Boolean) {
        speaker = value
        service?.setAudioRoute(
            if (value) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE
        )
        publish()
    }

    fun answer() {
        currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY)
    }

    fun reject() {
        currentCall?.reject(false, null)
    }

    fun disconnect() {
        currentCall?.disconnect()
    }

    fun hold(value: Boolean) {
        val call = currentCall ?: return
        if (value) call.hold() else call.unhold()
    }

    fun playDtmf(digit: String) {
        if (digit.length == 1 && (digit[0].isDigit() || digit[0] == '*' || digit[0] == '#')) {
            currentCall?.playDtmfTone(digit[0])
        }
    }

    fun stopDtmf() {
        currentCall?.stopDtmfTone()
    }

    fun snapshot(): Map<String, Any?> {
        val call = currentCall
        val details = call?.details
        val handle = details?.handle
        val state = call?.state ?: Call.STATE_DISCONNECTED
        val audio = service?.callAudioState
        muted = service?.let { audio?.isMuted ?: muted } ?: muted
        speaker = audio?.route == CallAudioState.ROUTE_SPEAKER
        audioAvailable = audio?.supportedRouteMask?.and(
            CallAudioState.ROUTE_SPEAKER or CallAudioState.ROUTE_EARPIECE
        ) != 0
        return mapOf(
            "hasCall" to (call != null),
            "number" to (handle?.schemeSpecificPart ?: ""),
            "displayName" to (details?.callerDisplayName ?: ""),
            "direction" to when (details?.callDirection) {
                Call.Details.DIRECTION_INCOMING -> "incoming"
                Call.Details.DIRECTION_OUTGOING -> "outgoing"
                else -> "unknown"
            },
            "state" to stateName(state),
            "muted" to muted,
            "speaker" to speaker,
            "canHold" to (call?.details?.can(Call.Details.CAPABILITY_SUPPORT_HOLD) == true),
            "isHeld" to (state == Call.STATE_HOLDING),
            "connectTimeMillis" to (details?.connectTimeMillis ?: 0L),
            "video" to (details?.videoState != VideoProfile.STATE_AUDIO_ONLY)
        )
    }

    fun publish() {
        eventSink?.invoke(snapshot())
    }

    private fun stateName(state: Int): String = when (state) {
        Call.STATE_NEW -> "new"
        Call.STATE_CONNECTING -> "connecting"
        Call.STATE_SELECT_PHONE_ACCOUNT -> "selectingAccount"
        Call.STATE_DIALING -> "dialing"
        Call.STATE_RINGING -> "ringing"
        Call.STATE_ACTIVE -> "active"
        Call.STATE_HOLDING -> "holding"
        Call.STATE_DISCONNECTING -> "disconnecting"
        Call.STATE_DISCONNECTED -> "disconnected"
        else -> "unknown"
    }
}
