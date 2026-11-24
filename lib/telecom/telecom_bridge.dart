import 'package:flutter/services.dart';
import 'call_snapshot.dart';
class TelecomBridge {
  static const _methods = MethodChannel('com.moogs.phone/telecom');
  static const _events = EventChannel('com.moogs.phone/call_events');

  static Stream<CallSnapshot> get callEvents => _events
      .receiveBroadcastStream()
      .where((event) => event is Map)
      .map((event) => CallSnapshot.fromMap(event as Map));

  static Future<CallSnapshot> currentCall() async {
    final result = await _methods.invokeMapMethod<dynamic, dynamic>('getCallSnapshot');
    return CallSnapshot.fromMap(result ?? const {'hasCall': false});
  }

  static Future<void> act(String action, [Map<String, Object?> args = const {}]) =>
      _methods.invokeMethod<void>(action, args);

  static Future<void> placeCall(String number) =>
      act('placeCall', {'number': number});

  static Future<void> requestDefaultDialer() => act('requestDefaultDialer');
}


