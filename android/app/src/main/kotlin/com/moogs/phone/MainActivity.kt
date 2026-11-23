package com.moogs.phone

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.telecom.TelecomManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moogs.phone/telecom"
    private val requestDialerRole = 4102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestDefaultDialer" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val roleManager = getSystemService(RoleManager::class.java)
                                if (roleManager.isRoleAvailable(RoleManager.ROLE_DIALER) &&
                                    !roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                                    startActivityForResult(
                                        roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER),
                                        requestDialerRole
                                    )
                                }
                                result.success(roleManager.isRoleHeld(RoleManager.ROLE_DIALER))
                            } else {
                                val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
                                if (telecom.defaultDialerPackage != packageName) {
                                    startActivityForResult(
                                        Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                                            .putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName),
                                        requestDialerRole
                                    )
                                }
                                result.success(telecom.defaultDialerPackage == packageName)
                            }
                        } catch (error: Exception) {
                            result.error("DIALER_ROLE_ERROR", error.message, null)
                        }
                    }
                    "placeCall" -> {
                        val number = call.argument<String>("number")?.trim()
                        if (number.isNullOrEmpty()) {
                            result.error("INVALID_NUMBER", "A phone number is required", null)
                        } else {
                            try {
                                val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
                                val uri = Uri.fromParts("tel", number, null)
                                telecom.placeCall(uri, null)
                                result.success(null)
                            } catch (error: SecurityException) {
                                result.error("CALL_PERMISSION_REQUIRED", error.message, null)
                            } catch (error: Exception) {
                                result.error("CALL_FAILED", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
