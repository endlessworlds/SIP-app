import 'package:flutter/material.dart';

import '../app.dart';
import '../services/models.dart';
import '../services/sip_service.dart';
import '../widgets/glass_widgets.dart';

class CallLogScreen extends StatefulWidget {
  const CallLogScreen({super.key});

  @override
  State<CallLogScreen> createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  final SipService _sipService = SipService.instance;
  late Future<List<CallLogEntry>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _sipService.fetchCallLogs();
  }

  Future<void> _refresh() async {
    final next = _sipService.fetchCallLogs();
    setState(() => _logsFuture = next);
    await next;
  }

  String _label(CallLogType type) {
    switch (type) {
      case CallLogType.incoming:
        return 'Incoming';
      case CallLogType.outgoing:
        return 'Outgoing';
      case CallLogType.missed:
        return 'Missed';
    }
  }

  String _durationText(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _timeText(DateTime timestamp) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Call Logs', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dialpad),
            icon: const Icon(Icons.dialpad),
            tooltip: 'Dialpad',
          ),
        ],
      ),
      body: FutureBuilder<List<CallLogEntry>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load call logs',
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          }

          final logs = snapshot.data ?? <CallLogEntry>[];
          if (logs.isEmpty) {
            return const Center(
              child: Text(
                'No calls yet',
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.indigo,
            backgroundColor: const Color(0xFF1A1A1A),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              itemBuilder: (context, index) {
                final log = logs[index];
                final isMissed = log.type == CallLogType.missed;
                return GlassContainer(
                  borderRadius: 16,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMissed
                            ? Colors.redAccent.withOpacity(0.2)
                            : Colors.greenAccent.withOpacity(0.2),
                        border: Border.all(
                          color: isMissed
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.greenAccent.withOpacity(0.5),
                        ),
                      ),
                      child: Icon(
                        isMissed ? Icons.call_missed : Icons.call,
                        color: isMissed ? Colors.redAccent : Colors.greenAccent,
                      ),
                    ),
                    title: Text(
                      'Extension ${log.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${_label(log.type)} • ${_timeText(log.timestamp)}',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: Text(
                      _durationText(log.durationSeconds),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: logs.length,
            ),
          );
        },
      ),
    );
  }
}
