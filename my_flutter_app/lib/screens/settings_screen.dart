import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';
import '../widgets/glass_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SipService _sipService = SipService.instance;
  static const Set<String> _availableTransports = {'TCP', 'WS'};

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _transport = 'WS';

  @override
  void initState() {
    super.initState();
    final credentials = _sipService.credentials;
    _serverController.text = credentials.server;
    _portController.text = credentials.port.toString();
    _usernameController.text = credentials.username;
    _passwordController.text = credentials.password;
    final normalizedTransport = credentials.transport.trim().toUpperCase();
    _transport = _availableTransports.contains(normalizedTransport)
      ? normalizedTransport
      : 'WS';
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('SIP Settings', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _sipService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Account Configuration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                GlassTextField(
                  controller: _serverController,
                  labelText: 'SIP Server',
                  hintText: 'e.g. 192.168.1.20',
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _portController,
                  keyboardType: TextInputType.number,
                  labelText: 'Port',
                  hintText: '8088',
                ),
                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _transport,
                      dropdownColor: const Color(0xFF1A1A1A),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'TCP', child: Text('TCP')),
                        DropdownMenuItem(value: 'WS', child: Text('WebSocket (WS)')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _transport = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                ),
                const SizedBox(height: 16),
                GlassTextField(
                  controller: _passwordController,
                  obscureText: true,
                  labelText: 'Password',
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Status: ${_sipService.statusMessage}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      if (_sipService.lastError.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _sipService.lastError,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GlassButton(
                  color: Colors.blueAccent,
                  onPressed: () async {
                    final next = SipCredentials(
                      server: _serverController.text.trim(),
                      port: int.tryParse(_portController.text.trim()) ?? 0,
                      username: _usernameController.text.trim(),
                      password: _passwordController.text,
                      transport: _transport,
                    );
                    await _sipService.saveCredentials(next);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SIP settings saved.')),
                    );
                  },
                  child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        color: Colors.greenAccent,
                        onPressed: () async {
                          await _sipService.register();
                        },
                        child: const Text('Register', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GlassButton(
                        color: Colors.orangeAccent,
                        onPressed: () async {
                          await _sipService.unregister(explicit: true);
                        },
                        child: const Text('Unregister', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.dialpad),
                  child: const Text('Go To Dialpad', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
