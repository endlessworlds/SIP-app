import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('SIP Settings')),
      body: AnimatedBuilder(
        animation: _sipService,
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    decoration: const InputDecoration(
                      labelText: 'SIP Server',
                      hintText: 'e.g. localhost',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '5060',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _transport,
                    items: const [
                      DropdownMenuItem(value: 'TCP', child: Text('TCP')),
                      DropdownMenuItem(value: 'WS', child: Text('WebSocket (WS)')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _transport = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Transport',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Status: ${_sipService.statusMessage}'),
                  if (_sipService.lastError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _sipService.lastError,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final next = SipCredentials(
                          server: _serverController.text.trim(),
                          port: int.tryParse(_portController.text.trim()) ?? 0,
                          username: _usernameController.text.trim(),
                          password: _passwordController.text,
                          transport: _transport,
                        );
                        await _sipService.saveCredentials(next);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SIP settings saved.')),
                        );
                      },
                      child: const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await _sipService.register();
                      },
                      child: const Text('Register'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _sipService.unregister();
                      },
                      child: const Text('Unregister'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.dialpad),
                      child: const Text('Go To Dialpad'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
