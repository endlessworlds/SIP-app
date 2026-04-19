import 'package:flutter/material.dart';

import '../app.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isHold = false;

  void _endCallAndReturn() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.dialpad);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final destination = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Call'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const CircleAvatar(
                radius: 44,
                child: Icon(Icons.person, size: 44),
              ),
              const SizedBox(height: 14),
              Text(
                'Extension $destination',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: const Icon(Icons.graphic_eq, size: 18),
                  label: const Text('Connected • 00:18'),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilterChip(
                    selected: _isMuted,
                    onSelected: (value) => setState(() => _isMuted = value),
                    avatar: const Icon(Icons.mic_off),
                    label: const Text('Mute'),
                  ),
                  FilterChip(
                    selected: _isSpeakerOn,
                    onSelected: (value) => setState(() => _isSpeakerOn = value),
                    avatar: const Icon(Icons.volume_up),
                    label: const Text('Speaker'),
                  ),
                  FilterChip(
                    selected: _isHold,
                    onSelected: (value) => setState(() => _isHold = value),
                    avatar: const Icon(Icons.pause_circle_outline),
                    label: const Text('Hold'),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                        onPressed: _endCallAndReturn,
                      icon: const Icon(Icons.dialpad),
                      label: const Text('Dialpad'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _endCallAndReturn,
                      icon: const Icon(Icons.call_end),
                      label: const Text('Hangup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
