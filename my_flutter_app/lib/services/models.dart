enum SipRegistrationStatus {
  idle,
  registering,
  registered,
  failed,
  unregistered,
}

enum ActiveCallStatus {
  idle,
  ringing,
  connecting,
  inCall,
  ended,
  failed,
}

enum CallLogType {
  incoming,
  outgoing,
  missed,
}

class SipCredentials {
  const SipCredentials({
    required this.server,
    required this.port,
    required this.username,
    required this.password,
    required this.transport,
  });

  final String server;
  final int port;
  final String username;
  final String password;
  final String transport;

  SipCredentials copyWith({
    String? server,
    int? port,
    String? username,
    String? password,
    String? transport,
  }) {
    return SipCredentials(
      server: server ?? this.server,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      transport: transport ?? this.transport,
    );
  }

  bool get isValid =>
      server.trim().isNotEmpty &&
      username.trim().isNotEmpty &&
      password.trim().isNotEmpty &&
      port > 0;

  static const SipCredentials defaults = SipCredentials(
    server: 'localhost',
    port: 5060,
    username: '1001',
    password: '1234',
    transport: 'WS',
  );
}

class CallLogEntry {
  const CallLogEntry({
    this.id,
    required this.number,
    required this.type,
    required this.timestamp,
    required this.durationSeconds,
  });

  final int? id;
  final String number;
  final CallLogType type;
  final DateTime timestamp;
  final int durationSeconds;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'number': number,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': durationSeconds,
    };
  }

  factory CallLogEntry.fromMap(Map<String, Object?> map) {
    return CallLogEntry(
      id: map['id'] as int?,
      number: (map['number'] as String?) ?? '',
      type: CallLogType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => CallLogType.outgoing,
      ),
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
    );
  }
}
