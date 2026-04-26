import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final SipService _sipService = SipService.instance;

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
      body: AnimatedBuilder(
        animation: _sipService,
        builder: (context, _) {
          final number =
              _sipService.activeNumber.isEmpty ? destination : _sipService.activeNumber;
            final isIncomingAwaitingAnswer = _sipService.isIncomingActiveCall &&
              _sipService.callStatus != ActiveCallStatus.inCall &&
              _sipService.callStatus != ActiveCallStatus.ended &&
              _sipService.callStatus != ActiveCallStatus.failed;
          final statusLabel = _sipService.callStatus == ActiveCallStatus.inCall
            ? '${_sipService.statusMessage} • ${_sipService.formattedCallDuration}'
            : _sipService.statusMessage;

          return SafeArea(
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
                    'Extension $number',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.graphic_eq, size: 18),
                      label: Text(statusLabel),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilterChip(
                        selected: _sipService.isMuted,
                        onSelected: (_) {
                          _sipService.toggleMute();
                        },
                        avatar: const Icon(Icons.mic_off),
                        label: const Text('Mute'),
                      ),
                      FilterChip(
                        selected: _sipService.isSpeakerOn,
                        onSelected: (_) {
                          _sipService.toggleSpeaker();
                        },
                        avatar: const Icon(Icons.volume_up),
                        label: const Text('Speaker'),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isIncomingAwaitingAnswer)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _sipService.rejectIncomingCall();
                              if (!context.mounted) {
                                return;
                              }
                              _endCallAndReturn();
                            },
                            icon: const Icon(Icons.call_end),
                            label: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _sipService.answerIncomingCall();
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Accept'),
                          ),
                        ),
                      ],
                    )
                  else
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
                            onPressed: () async {
                              await _sipService.hangup();
                              if (!context.mounted) {
                                return;
                              }
                              _endCallAndReturn();
                            },
                            icon: const Icon(Icons.call_end),
                            label: const Text('Hangup'),
                          ),
                        ),
                      ],
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
