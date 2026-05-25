import 'package:flutter/services.dart';

class AndroidKeepAliveService {
  AndroidKeepAliveService._();

  static const MethodChannel _channel = MethodChannel('sip_keep_alive');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('start');
    } catch (_) {
      // Best effort only.
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {
      // Best effort only.
    }
  }
}