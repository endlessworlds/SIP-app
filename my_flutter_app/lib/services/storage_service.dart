import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class StorageService {
  static const _credentialsServerKey = 'sip_server';
  static const _credentialsPortKey = 'sip_port';
  static const _credentialsUsernameKey = 'sip_username';
  static const _credentialsPasswordKey = 'sip_password';
  static const _credentialsTransportKey = 'sip_transport';

  static const _dbName = 'sip_app.db';
  static const _dbVersion = 1;
  static const _callLogsTable = 'call_logs';

  static const Set<String> _supportedTransports = {'TCP', 'WS'};

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Database? _database;

  Future<void> init() async {
    if (_database != null) {
      return;
    }

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, _dbName);

    _database = await openDatabase(
      fullPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_callLogsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT NOT NULL,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<SipCredentials> loadCredentials() async {
    final server =
        await _secureStorage.read(key: _credentialsServerKey) ?? SipCredentials.defaults.server;
    final portString =
        await _secureStorage.read(key: _credentialsPortKey) ?? SipCredentials.defaults.port.toString();
    final username =
        await _secureStorage.read(key: _credentialsUsernameKey) ?? SipCredentials.defaults.username;
    final password =
        await _secureStorage.read(key: _credentialsPasswordKey) ?? SipCredentials.defaults.password;
    final rawTransport =
      await _secureStorage.read(key: _credentialsTransportKey) ?? SipCredentials.defaults.transport;
    final normalizedTransport = rawTransport.trim().toUpperCase();
    final transport = _supportedTransports.contains(normalizedTransport)
      ? normalizedTransport
      : 'WS';

    if (transport != rawTransport) {
      await _secureStorage.write(key: _credentialsTransportKey, value: transport);
    }

    return SipCredentials(
      server: server,
      port: int.tryParse(portString) ?? SipCredentials.defaults.port,
      username: username,
      password: password,
      transport: transport,
    );
  }

  Future<void> saveCredentials(SipCredentials credentials) async {
    await _secureStorage.write(key: _credentialsServerKey, value: credentials.server);
    await _secureStorage.write(key: _credentialsPortKey, value: credentials.port.toString());
    await _secureStorage.write(key: _credentialsUsernameKey, value: credentials.username);
    await _secureStorage.write(key: _credentialsPasswordKey, value: credentials.password);
    await _secureStorage.write(key: _credentialsTransportKey, value: credentials.transport);
  }

  Future<void> saveCallLog(CallLogEntry entry) async {
    final db = _database;
    if (db == null) {
      throw StateError('StorageService.init must be called before using call logs.');
    }

    await db.insert(_callLogsTable, entry.toMap());
  }

  Future<List<CallLogEntry>> fetchCallLogs() async {
    final db = _database;
    if (db == null) {
      throw StateError('StorageService.init must be called before using call logs.');
    }

    final rows = await db.query(
      _callLogsTable,
      orderBy: 'timestamp DESC',
    );
    return rows.map(CallLogEntry.fromMap).toList();
  }
}
