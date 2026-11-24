package com.moogs.phone

import android.app.role.RoleManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.Manifest
import android.content.pm.PackageManager
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import android.provider.ContactsContract
import android.provider.CallLog
import android.database.Cursor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.moogs.phone/telecom"
    private val eventName = "com.moogs.phone/call_events"
    private val requestDialerRole = 4102
    private val phoneDataChannel = "com.moogs.phone/phone_data"
    private val contactsPermissionRequest = 4201
    private val callLogPermissionRequest = 4202
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDialerRoleResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4103)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == requestDialerRole) {
            val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) getSystemService(RoleManager::class.java).isRoleHeld(RoleManager.ROLE_DIALER) else (getSystemService(TELECOM_SERVICE) as TelecomManager).defaultDialerPackage == packageName
            pendingDialerRoleResult?.success(granted)
            pendingDialerRoleResult = null
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
                            val simSlot = call.argument<Int>("simSlot") ?: 0
                            if (number.isNullOrEmpty()) {
                                result.error("INVALID_NUMBER", "A phone number is required", null)
                            } else if (simSlot !in 0..1) {
                                result.error("INVALID_SIM", "Choose SIM 1 or SIM 2", null)
                            } else {
                                val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
                                val accounts = telecom.callCapablePhoneAccounts
                                val selectedHandle = runCatching {
                                    val subscriptions = getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                                    val subscriptionId = subscriptions.activeSubscriptionInfoList
                                        ?.firstOrNull { it.simSlotIndex == simSlot }?.subscriptionId
                                    subscriptionId?.let { id -> accounts.firstOrNull { it.id.toIntOrNull() == id } }
                                }.getOrNull() ?: accounts.getOrNull(simSlot)

                                if (accounts.isNotEmpty() && selectedHandle == null) {
                                    result.error("SIM_UNAVAILABLE", "The selected SIM is not available for outgoing calls", null)
                                } else {
                                    val extras = Bundle()
                                    if (selectedHandle != null) {
                                        extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, selectedHandle)
                                    }
                                    telecom.placeCall(Uri.fromParts("tel", number, null), extras)
                                    result.success(null)
                                }
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, phoneDataChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "requestPermission" -> requestPhoneDataPermission(call.argument<String>("kind") ?: "", result)
                        "getReduceEffects" -> result.success(getSharedPreferences("moogs_phone_settings", MODE_PRIVATE).getBoolean("reduce_effects", false))
                        "setReduceEffects" -> {
                            val enabled = call.argument<Boolean>("enabled") ?: false
                            getSharedPreferences("moogs_phone_settings", MODE_PRIVATE).edit().putBoolean("reduce_effects", enabled).apply()
                            result.success(null)
                        }
                        "getContacts" -> {
                            if (!hasPermission(Manifest.permission.READ_CONTACTS)) result.error("CONTACTS_PERMISSION", "Contacts permission is required", null)
                            else result.success(readContacts())
                        }
                        "getRecents" -> {
                            if (!hasPermission(Manifest.permission.READ_CALL_LOG)) result.error("CALL_LOG_PERMISSION", "Call history permission is required", null)
                            else result.success(readRecents())
                        }
                        "getFavorites" -> result.success(readFavorites())
                        "setFavorite" -> {
                            val number = call.argument<String>("number")?.trim().orEmpty()
                            val favorite = call.argument<Boolean>("favorite") ?: false
                            val name = call.argument<String>("name").orEmpty()
                            if (number.isNotEmpty()) updateFavorite(number, name, favorite)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: SecurityException) {
                    result.error("PHONE_DATA_PERMISSION", error.message, null)
                } catch (error: Exception) {
                    result.error("PHONE_DATA_ERROR", error.message, null)
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

    private fun hasPermission(permission: String): Boolean =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun requestPhoneDataPermission(kind: String, result: MethodChannel.Result) {
        val permission = when (kind) {
            "contacts" -> Manifest.permission.READ_CONTACTS
            "callLog" -> Manifest.permission.READ_CALL_LOG
            else -> {
                result.error("UNKNOWN_PERMISSION", "Unknown phone data permission", null)
                return
            }
        }
        if (hasPermission(permission)) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("PERMISSION_PENDING", "Another permission request is already open", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(permission),
            if (kind == "contacts") contactsPermissionRequest else callLogPermissionRequest
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == contactsPermissionRequest || requestCode == callLogPermissionRequest) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun readContacts(): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )
        contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            projection, null, null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " COLLATE NOCASE ASC"
        )?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (cursor.moveToNext()) {
                val number = cursor.getString(numberIndex)?.trim().orEmpty()
                if (number.isNotEmpty()) rows.add(mapOf(
                    "name" to cursor.getString(nameIndex).orEmpty(),
                    "number" to number,
                    "dateMillis" to 0L,
                    "callType" to 0
                ))
            }
        }
        return rows.distinctBy { it["number"] }
    }

    private fun readRecents(): List<Map<String, Any?>> {
        val rows = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.NUMBER,
            CallLog.Calls.DATE,
            CallLog.Calls.TYPE
        )
        contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            projection, null, null, CallLog.Calls.DATE + " DESC"
        )?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val numberIndex = cursor.getColumnIndex(CallLog.Calls.NUMBER)
            val dateIndex = cursor.getColumnIndex(CallLog.Calls.DATE)
            val typeIndex = cursor.getColumnIndex(CallLog.Calls.TYPE)
            while (cursor.moveToNext()) {
                rows.add(mapOf(
                    "name" to cursor.getString(nameIndex).orEmpty(),
                    "number" to cursor.getString(numberIndex).orEmpty(),
                    "dateMillis" to cursor.getLong(dateIndex),
                    "callType" to cursor.getInt(typeIndex)
                ))
            }
        }
        return rows
    }

    private fun favoritesPreferences() = getSharedPreferences("moogs_phone_favorites", MODE_PRIVATE)

    private fun readFavorites(): List<Map<String, Any?>> {
        val numbers = favoritesPreferences().getStringSet("numbers", emptySet()).orEmpty()
        val names = favoritesPreferences().getStringSet("names", emptySet()).orEmpty()
        val nameByNumber = names.mapNotNull {
            val split = it.indexOf('|')
            if (split > 0) it.substring(0, split) to it.substring(split + 1) else null
        }.toMap()
        return numbers.map { number ->
            mapOf("name" to (nameByNumber[number] ?: ""), "number" to number, "dateMillis" to 0L, "callType" to 0)
        }.sortedBy { (it["name"] as String).lowercase() }
    }

    private fun updateFavorite(number: String, name: String, favorite: Boolean) {
        val prefs = favoritesPreferences()
        val numbers = prefs.getStringSet("numbers", emptySet()).orEmpty().toMutableSet()
        val names = prefs.getStringSet("names", emptySet()).orEmpty().toMutableSet()
        names.removeAll { it.startsWith("$number|") }
        if (favorite) {
            numbers.add(number)
            names.add("$number|$name")
        } else {
            numbers.remove(number)
        }
        prefs.edit().putStringSet("numbers", numbers).putStringSet("names", names).apply()
    }

    private fun requestDialerRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roles = getSystemService(RoleManager::class.java)
            if (!roles.isRoleAvailable(RoleManager.ROLE_DIALER) ||
                roles.isRoleHeld(RoleManager.ROLE_DIALER)) {
                result.success(roles.isRoleHeld(RoleManager.ROLE_DIALER))
            } else {
                pendingDialerRoleResult = result
                startActivityForResult(roles.createRequestRoleIntent(RoleManager.ROLE_DIALER), requestDialerRole)
            }
        } else {
            val telecom = getSystemService(TELECOM_SERVICE) as TelecomManager
            if (telecom.defaultDialerPackage == packageName) {
                result.success(true)
            } else {
                pendingDialerRoleResult = result
                startActivityForResult(
                    Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                        .putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName),
                    requestDialerRole
                )
            }
        }
    }
}
