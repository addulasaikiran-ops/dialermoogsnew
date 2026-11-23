package com.moogs.phone

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moogs.phone/telecom"
    private val eventName = "com.moogs.phone/call_events"
    private val requestDialerRole = 4102

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4103)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "requestDefaultDialer" -> requestDialerRole(result)
                        "placeCall" -> {
                            val number = call.argument<String>("number")?.trim()
                            if (number.isNullOrEmpty()) {
                                result.error("INVALID_NUMBER", "A phone number is required", null)
                            } else {
                                val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
                                telecom.placeCall(Uri.fromParts("tel", number, null), null)
                                result.success(null)
                            }
                        }
                        "getCallSnapshot" -> result.success(MoogsCallRegistry.snapshot())
                        "answer" -> { MoogsCallRegistry.answer(); result.success(null) }
                        "reject" -> { MoogsCallRegistry.reject(); result.success(null) }
                        "disconnect" -> { MoogsCallRegistry.disconnect(); result.success(null) }
                        "hold" -> {
                            MoogsCallRegistry.hold(call.argument<Boolean>("enabled") ?: true)
                            result.success(null)
                        }
                        "mute" -> {
                            MoogsCallRegistry.setMuted(call.argument<Boolean>("enabled") ?: true)
                            result.success(null)
                        }
                        "speaker" -> {
                            MoogsCallRegistry.setSpeaker(call.argument<Boolean>("enabled") ?: true)
                            result.success(null)
                        }
                        "dtmf" -> {
                            MoogsCallRegistry.playDtmf(call.argument<String>("digit") ?: "")
                            result.success(null)
                        }
                        "stopDtmf" -> { MoogsCallRegistry.stopDtmf(); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (error: SecurityException) {
                    result.error("TELECOM_PERMISSION", error.message, null)
                } catch (error: Exception) {
                    result.error("TELECOM_ERROR", error.message, null)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MoogsCallRegistry.eventSink = { snapshot -> runOnUiThread { events?.success(snapshot) } }
                    MoogsCallRegistry.publish()
                }
                override fun onCancel(arguments: Any?) {
                    MoogsCallRegistry.eventSink = null
                }
            })
    }

    private fun requestDialerRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roles = getSystemService(RoleManager::class.java)
            if (!roles.isRoleAvailable(RoleManager.ROLE_DIALER) ||
                roles.isRoleHeld(RoleManager.ROLE_DIALER)) {
                result.success(roles.isRoleHeld(RoleManager.ROLE_DIALER))
            } else {
                startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_DIALER), requestDialerRole)
                result.success(false)
            }
        } else {
            val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
            if (telecom.defaultDialerPackage == packageName) {
                result.success(true)
            } else {
                startActivityForResult(
                    Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                        .putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName),
                    requestDialerRole
                )
                result.success(false)
            }
        }
    }
}
