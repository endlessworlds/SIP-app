import 'package:flutter/services.dart';

class AndroidAppLauncher {
  AndroidAppLauncher._();

  static const MethodChannel _channel = MethodChannel('sip_keep_alive');

  static Future<void> bringToFront() async {
    try {
      await _channel.invokeMethod('bringToFront');
    } catch (_) {
      // Best effort only.
    }
  }
}