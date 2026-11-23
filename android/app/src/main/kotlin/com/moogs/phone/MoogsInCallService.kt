package com.moogs.phone

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.InCallService
import android.telecom.VideoProfile

class MoogsInCallService : InCallService() {
    override fun onCreate() {
        super.onCreate()
        ensureCallChannel()
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        MoogsCallRegistry.attach(call, this)
        updateCallNotification(call)
    }

    override fun onCallRemoved(call: Call) {
        MoogsCallRegistry.detach(call)
        cancelCallNotification()
        super.onCallRemoved(call)
    }

    override fun onCallAudioStateChanged(audioState: CallAudioState) {
        super.onCallAudioStateChanged(audioState)
        MoogsCallRegistry.publish()
    }

    internal fun updateCallNotification(call: Call) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.moogs.phone.OPEN_CALL"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            this, 7001, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val incoming = call.state == Call.STATE_RINGING
        val name = call.details?.callerDisplayName
            ?: call.details?.handle?.schemeSpecificPart
            ?: "Unknown caller"
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CALL_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.sym_action_call)
            .setContentTitle(if (incoming) "Incoming call" else "Ongoing call")
            .setContentText(name)
            .setCategory(Notification.CATEGORY_CALL)
            .setPriority(Notification.PRIORITY_MAX)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(!incoming)
            .setAutoCancel(false)
            .setContentIntent(pending)
            .setFullScreenIntent(if (incoming) pending else null, incoming)
            .build()
        try {
            manager.notify(CALL_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // Android 13+ notification permission may be denied. Telecom still owns call state.
        }
    }

    private fun ensureCallChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CALL_CHANNEL,
                "Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming and ongoing call notifications"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
    }

    private fun cancelCallNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(CALL_NOTIFICATION_ID)
    }

    companion object {
        const val CALL_CHANNEL = "moogs_calls"
        const val CALL_NOTIFICATION_ID = 7002
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
    @Volatile var eventSink: ((Map<String, Any?>) -> Unit)? = null

    private val callback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            service?.updateCallNotification(call)
            publish()
        }
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

    fun answer() { currentCall?.answer(VideoProfile.STATE_AUDIO_ONLY) }
    fun reject() { currentCall?.reject(false, null) }
    fun disconnect() { currentCall?.disconnect() }

    fun hold(value: Boolean) {
        val call = currentCall ?: return
        if (value) call.hold() else call.unhold()
    }

    fun playDtmf(digit: String) {
        if (digit.length == 1 && (digit[0].isDigit() || digit[0] == '*' || digit[0] == '#')) {
            currentCall?.playDtmfTone(digit[0])
        }
    }

    fun stopDtmf() { currentCall?.stopDtmfTone() }

    fun snapshot(): Map<String, Any?> {
        val call = currentCall
        val details = call?.details
        val audio = service?.callAudioState
        muted = audio?.isMuted ?: muted
        speaker = audio?.route == CallAudioState.ROUTE_SPEAKER
        val state = call?.state ?: Call.STATE_DISCONNECTED
        return mapOf(
            "hasCall" to (call != null),
            "number" to (details?.handle?.schemeSpecificPart ?: ""),
            "displayName" to (details?.callerDisplayName ?: ""),
            "direction" to when (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) details?.callDirection else null) {
                Call.Details.DIRECTION_INCOMING -> "incoming"
                Call.Details.DIRECTION_OUTGOING -> "outgoing"
                else -> "unknown"
            },
            "state" to stateName(state),
            "muted" to muted,
            "speaker" to speaker,
            "canHold" to (details?.can(Call.Details.CAPABILITY_SUPPORT_HOLD) == true),
            "isHeld" to (state == Call.STATE_HOLDING),
            "connectedDurationMillis" to if (state == Call.STATE_ACTIVE || state == Call.STATE_HOLDING) {
                val connectedAt = details?.connectTimeMillis ?: 0L
                if (connectedAt > 0L) (SystemClock.elapsedRealtime() - connectedAt).coerceAtLeast(0L) else 0L
            } else 0L
        )
    }

    fun publish() { eventSink?.invoke(snapshot()) }

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
