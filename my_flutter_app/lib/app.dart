import 'package:flutter/material.dart';
import 'dart:async';

import 'screens/call_log_screen.dart';
import 'screens/call_screen.dart';
import 'screens/dialpad_screen.dart';
import 'screens/settings_screen.dart';
import 'services/sip_service.dart';
import 'services/models.dart';

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
  bool _startupReconnectAttempted = false;

  @override
  void initState() {
    super.initState();
    SipService.instance.addListener(_onSipStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptStartupReconnect();
    });
  }

  @override
  void dispose() {
    SipService.instance.removeListener(_onSipStateChanged);
    super.dispose();
  }

  Future<void> _attemptStartupReconnect() async {
    if (_startupReconnectAttempted || !mounted) {
      return;
    }

    _startupReconnectAttempted = true;

    final service = SipService.instance;
    if (service.registrationStatus != SipRegistrationStatus.idle) {
      return;
    }

    if (!service.credentials.isValid) {
      return;
    }

    await service.unregister(explicit: false);
    await service.register();
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
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
