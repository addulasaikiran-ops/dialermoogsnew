package com.moogs.phone

import android.telecom.Call
import android.telecom.InCallService

/**
 * Telecom entry point for calls when Moog's Phone is selected as the default dialer.
 * The first implementation deliberately keeps call state handling native and small;
 * Flutter call controls will be connected through the platform channel in the next slice.
 */
class MoogsInCallService : InCallService() {
    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        MoogsCallRegistry.attach(call)
    }

    override fun onCallRemoved(call: Call) {
        MoogsCallRegistry.detach(call)
        super.onCallRemoved(call)
    }
}

internal object MoogsCallRegistry {
    @Volatile
    var currentCall: Call? = null
        private set

    fun attach(call: Call) {
        currentCall = call
    }

    fun detach(call: Call) {
        if (currentCall === call) currentCall = null
    }
}
