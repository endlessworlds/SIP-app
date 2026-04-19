import 'package:flutter/material.dart';

import 'screens/call_log_screen.dart';
import 'screens/call_screen.dart';
import 'screens/dialpad_screen.dart';
import 'screens/settings_screen.dart';

class AppRoutes {
  static const String settings = '/settings';
  static const String dialpad = '/dialpad';
  static const String call = '/call';
  static const String callLog = '/call-log';
}

class SipApp extends StatelessWidget {
  const SipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIP App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: AppRoutes.dialpad,
      routes: {
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.dialpad: (_) => const DialpadScreen(),
        AppRoutes.call: (_) => const CallScreen(),
        AppRoutes.callLog: (_) => const CallLogScreen(),
      },
    );
  }
}
