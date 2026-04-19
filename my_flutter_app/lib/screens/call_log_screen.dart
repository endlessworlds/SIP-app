import 'package:flutter/material.dart';

import '../app.dart';

class CallLogScreen extends StatelessWidget {
  const CallLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final logs = <Map<String, String>>[
      {'name': '1002', 'type': 'Outgoing', 'time': '10:42 AM', 'duration': '02:18'},
      {'name': '1001', 'type': 'Incoming', 'time': '09:31 AM', 'duration': '00:42'},
      {'name': '1003', 'type': 'Missed', 'time': 'Yesterday', 'duration': '--:--'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Logs'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dialpad),
            icon: const Icon(Icons.dialpad),
            tooltip: 'Dialpad',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
          itemBuilder: (context, index) {
            final log = logs[index];
            final isMissed = log['type'] == 'Missed';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isMissed
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  isMissed ? Icons.call_missed : Icons.call,
                  color: isMissed
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text('Extension ${log['name']}'),
              subtitle: Text('${log['type']} • ${log['time']}'),
              trailing: Text(log['duration']!),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: logs.length,
        ),
      ),
    );
  }
}
