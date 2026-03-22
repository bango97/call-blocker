package com.callblocker.service

import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import com.callblocker.CallBlockerApp
import com.callblocker.util.PatternMatcher

/**
 * Core call-blocking service. Android invokes [onScreenCall] for every incoming call.
 *
 * Requirements:
 * - [respondToCall] MUST be called within 5 seconds or the call proceeds unblocked.
 * - On API 29+: app holds ROLE_CALL_SCREENING (covers calls from contacts too).
 * - On API 24-28: app must be set as the default dialer.
 *
 * We read rules from the in-memory cache in [CallBlockerApp] — no I/O, no coroutines,
 * no risk of hitting the 5-second deadline.
 */
class BlockingCallScreeningService : CallScreeningService() {

    companion object {
        private const val TAG = "CallScreeningService"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val rawNumber: String? = callDetails.handle?.schemeSpecificPart
        if (rawNumber.isNullOrBlank()) {
            Log.d(TAG, "No number — allowing call")
            respondToCall(callDetails, CallResponse.Builder().build())
            return
        }

        // Read from the always-warm in-memory cache — zero I/O latency
        val rules = (application as CallBlockerApp).ruleCache.value
        val matchedRule = PatternMatcher.firstMatch(rawNumber, rules)

        if (matchedRule != null) {
            Log.i(TAG, "Blocking $rawNumber — matched rule '${matchedRule.label}' (${matchedRule.pattern})")
            val response = CallResponse.Builder()
                .setDisallowCall(true)      // prevents the phone from ringing
                .setRejectCall(true)        // sends busy/reject signal to caller
                .setSkipCallLog(false)      // still log it so user can review
                .setSkipNotification(true)  // suppress missed-call notification
                .build()
            respondToCall(callDetails, response)
        } else {
            Log.d(TAG, "Allowing $rawNumber — no matching rule")
            respondToCall(callDetails, CallResponse.Builder().build())
        }
    }
}
