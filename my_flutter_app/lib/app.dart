import 'package:flutter/material.dart';

import 'screens/call_log_screen.dart';
import 'screens/call_screen.dart';
import 'screens/dialpad_screen.dart';
import 'screens/settings_screen.dart';
import 'services/sip_service.dart';

class AppRoutes {
  static const String settings = '/settings';
  static const String dialpad = '/dialpad';
  static const String call = '/call';
  static const String callLog = '/call-log';
}

class SipApp extends StatefulWidget {
  const SipApp({super.key});

  @override
  State<SipApp> createState() => _SipAppState();
}

class _SipAppState extends State<SipApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SipService.instance.addListener(_onSipStateChanged);
  }

  @override
  void dispose() {
    SipService.instance.removeListener(_onSipStateChanged);
    super.dispose();
  }

  void _onSipStateChanged() {
    if (!SipService.instance.incomingNavigationPending) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    SipService.instance.markIncomingNavigationHandled();
    navigator.pushNamed(AppRoutes.call);
  }

  @override
  Widget build(BuildContext context) {
    final initialRoute = SipService.instance.credentials.isValid
        ? AppRoutes.dialpad
        : AppRoutes.settings;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SIP App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      initialRoute: initialRoute,
      routes: {
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.dialpad: (_) => const DialpadScreen(),
        AppRoutes.call: (_) => const CallScreen(),
        AppRoutes.callLog: (_) => const CallLogScreen(),
      },
    );
  }
}
