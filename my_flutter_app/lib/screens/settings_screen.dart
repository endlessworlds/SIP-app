import 'package:flutter/material.dart';

import '../app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _serverController =
      TextEditingController(text: '192.168.1.10');
  final TextEditingController _portController = TextEditingController(text: '5060');
  final TextEditingController _usernameController = TextEditingController(text: '1001');
  final TextEditingController _passwordController = TextEditingController(text: '1234');

  String _transport = 'UDP';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account Configuration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'SIP Server',
                  hintText: 'e.g. 192.168.1.10',
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
                  DropdownMenuItem(value: 'UDP', child: Text('UDP')),
                  DropdownMenuItem(value: 'TCP', child: Text('TCP')),
                  DropdownMenuItem(value: 'WS', child: Text('WebSocket (WS)')),
                ],
                onChanged: (value) {
                  if (value == null) return;
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saved: ${_usernameController.text}@${_serverController.text}:${_portController.text} ($_transport)',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save Settings'),
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
      ),
    );
  }
}
