import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';
import '../widgets/glass_widgets.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final SipService _sipService = SipService.instance;
  bool _navigatedForTerminalState = false;

  @override
  void initState() {
    super.initState();
    _sipService.addListener(_handleSipStateChanged);
  }

  @override
  void dispose() {
    _sipService.removeListener(_handleSipStateChanged);
    super.dispose();
  }

  void _handleSipStateChanged() {
    if (!_sipService.isCallInTerminalState || _navigatedForTerminalState) {
      return;
    }

    _navigatedForTerminalState = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _endCallAndReturn();
    });
  }

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

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Active Call', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: AnimatedBuilder(
        animation: _sipService,
        builder: (context, _) {
          final number =
              _sipService.activeNumber.isEmpty ? destination : _sipService.activeNumber;
          final isIncomingAwaitingAnswer =
              _sipService.isIncomingActiveCall &&
              _sipService.callStatus == ActiveCallStatus.ringing;
          final statusLabel = _sipService.callStatus == ActiveCallStatus.inCall
            ? '${_sipService.statusMessage} • ${_sipService.formattedCallDuration}'
            : _sipService.statusMessage;

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 64, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Extension $number',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    borderRadius: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.graphic_eq, size: 18, color: Colors.greenAccent),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel,
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassButton(
                      isCircle: true,
                      color: _sipService.isMuted ? Colors.white : Colors.transparent,
                      onPressed: () {
                        _sipService.toggleMute();
                      },
                      child: Icon(
                        _sipService.isMuted ? Icons.mic_off : Icons.mic,
                        color: _sipService.isMuted ? Colors.black87 : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 32),
                    GlassButton(
                      isCircle: true,
                      color: _sipService.isSpeakerOn ? Colors.white : Colors.transparent,
                      onPressed: () {
                        _sipService.toggleSpeaker();
                      },
                      child: Icon(
                        _sipService.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                        color: _sipService.isSpeakerOn ? Colors.black87 : Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isIncomingAwaitingAnswer)
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          color: Colors.redAccent,
                          borderRadius: 32,
                          onPressed: () async {
                            await _sipService.rejectIncomingCall();
                            if (!context.mounted) return;
                            _endCallAndReturn();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_end, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Reject', style: TextStyle(color: Colors.white, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassButton(
                          color: Colors.greenAccent,
                          borderRadius: 32,
                          onPressed: () async {
                            await _sipService.answerIncomingCall();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Accept', style: TextStyle(color: Colors.white, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          borderRadius: 32,
                          onPressed: _endCallAndReturn,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.dialpad, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Dialpad', style: TextStyle(color: Colors.white, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GlassButton(
                          color: Colors.redAccent,
                          borderRadius: 32,
                          onPressed: () async {
                            await _sipService.hangup();
                            if (!context.mounted) return;
                            _endCallAndReturn();
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call_end, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Hangup', style: TextStyle(color: Colors.white, fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
