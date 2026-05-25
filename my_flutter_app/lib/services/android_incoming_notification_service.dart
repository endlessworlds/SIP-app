import 'package:flutter/services.dart';

class AndroidIncomingNotificationService {
  AndroidIncomingNotificationService._();

  static const MethodChannel _channel = MethodChannel('sip_keep_alive');

  static Future<void> showIncomingCall(String caller) async {
    try {
      await _channel.invokeMethod('showIncomingCallNotification', caller);
    } catch (_) {
      // Best effort only.
    }
  }

  static Future<void> cancelIncomingCall() async {
    try {
      await _channel.invokeMethod('cancelIncomingCallNotification');
    } catch (_) {
      // Best effort only.
    }
  }
}