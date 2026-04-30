import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sip_ua/sip_ua.dart';

import 'audio_service.dart';
import 'models.dart';
import 'storage_service.dart';

class SipService extends ChangeNotifier implements SipUaHelperListener {
  SipService._();

  static final SipService instance = SipService._();

  final SIPUAHelper _helper = SIPUAHelper();
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();

  SipCredentials _credentials = SipCredentials.defaults;
  SipCredentials get credentials => _credentials;
  SipCredentials _runtimeCredentials = SipCredentials.defaults;

  SipRegistrationStatus _registrationStatus = SipRegistrationStatus.idle;
  SipRegistrationStatus get registrationStatus => _registrationStatus;

  ActiveCallStatus _callStatus = ActiveCallStatus.idle;
  ActiveCallStatus get callStatus => _callStatus;

  String _statusMessage = 'Idle';
  String get statusMessage => _statusMessage;

  Call? _activeCall;
  Call? get activeCall => _activeCall;

  String _activeNumber = '';
  String get activeNumber => _activeNumber;

  bool _isIncomingActiveCall = false;
  bool get isIncomingActiveCall => _isIncomingActiveCall;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool get isSpeakerOn => _audioService.speakerOn;

  bool _incomingNavigationPending = false;
  bool get incomingNavigationPending => _incomingNavigationPending;

  DateTime? _callStartedAt;
  DateTime? _callEndedAt;
  bool _callWasConnected = false;

  String _lastError = '';
  String get lastError => _lastError;

  bool _pendingRegister = false;
  Timer? _registerTimeoutTimer;
  bool _uaStarted = false;

  void _stopUaIfStarted() {
    if (!_uaStarted) {
      return;
    }
    _helper.stop();
    _uaStarted = false;
  }

  Future<String?> _preflightConnectivityIssue(SipCredentials effective) async {
    final transport = _resolveTransport(effective.transport.trim().toUpperCase());
    final targetPort = transport == TransportType.WS
        ? (effective.port == 5060 ? 8088 : effective.port)
        : effective.port;

    try {
      final socket = await Socket.connect(
        effective.server,
        targetPort,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();
      return null;
    } on SocketException catch (error) {
      final reason = error.message;
      return 'Cannot reach ${effective.server}:$targetPort ($reason). Make sure phone and SIP server are reachable on the same network.';
    } catch (_) {
      return null;
    }
  }

  bool get _isMobileRuntime => Platform.isAndroid || Platform.isIOS;

  bool _isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  String _mobileTransportGuidance() {
    return 'Android SIP/WebRTC requires WS transport to the Asterisk host LAN IP on port 8088.';
  }

  bool get isCallInTerminalState =>
      _callStatus == ActiveCallStatus.ended ||
      _callStatus == ActiveCallStatus.failed;

  Future<void> initialize() async {
    _helper.addSipUaHelperListener(this);
    await _storageService.init();
    _credentials = await _storageService.loadCredentials();
    _runtimeCredentials = _credentials;

    notifyListeners();
  }

  Future<void> saveCredentials(SipCredentials newCredentials) async {
    final normalized = _normalizeForPlatform(newCredentials);
    _credentials = normalized;
    _runtimeCredentials = normalized;
    await _storageService.saveCredentials(normalized);
    _statusMessage = 'Settings saved';
    notifyListeners();
  }

  Future<void> register() async {
    _lastError = '';
    if (!_credentials.isValid) {
      _lastError = 'Please enter valid SIP credentials.';
      _registrationStatus = SipRegistrationStatus.failed;
      _statusMessage = _lastError;
      notifyListeners();
      return;
    }

    if (_isMobileRuntime) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _lastError = 'Microphone permission is required for calls.';
        _registrationStatus = SipRegistrationStatus.failed;
        _statusMessage = _lastError;
        notifyListeners();
        return;
      }
    }

    _stopUaIfStarted();

    _registrationStatus = SipRegistrationStatus.registering;
    _statusMessage = 'REGISTRATION_ATTEMPT: Registering...';
    _pendingRegister = true;
    _registerTimeoutTimer?.cancel();
    _registerTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (_registrationStatus == SipRegistrationStatus.registering) {
        _stopUaIfStarted();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.failed;
        _statusMessage = 'REGISTRATION_FAILED: timeout';
        _lastError =
            'Could not complete SIP registration. Check server, transport and network.';
        notifyListeners();
      }
    });
    notifyListeners();

    try {
      var effective = _normalizeForPlatform(_credentials);

      if (_isMobileRuntime && _isLoopbackHost(effective.server)) {
        _registerTimeoutTimer?.cancel();
        _stopUaIfStarted();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.failed;
        _statusMessage = 'REGISTRATION_FAILED';
        _lastError =
            'Mobile SIP clients cannot use localhost or 127.0.0.1. Enter the Asterisk host LAN IP instead.';
        notifyListeners();
        return;
      }

      if (_isMobileRuntime && effective.transport.trim().toUpperCase() != 'WS') {
        _registerTimeoutTimer?.cancel();
        _stopUaIfStarted();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.failed;
        _statusMessage = 'REGISTRATION_FAILED';
        _lastError = _mobileTransportGuidance();
        notifyListeners();
        return;
      }

      var preflightIssue = await _preflightConnectivityIssue(effective);

      if (preflightIssue != null) {
        _registerTimeoutTimer?.cancel();
        _stopUaIfStarted();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.failed;
        _statusMessage = 'REGISTRATION_FAILED';
        _lastError = preflightIssue;
        notifyListeners();
        return;
      }

      _runtimeCredentials = effective;
      final transport = effective.transport.trim().toUpperCase();
      final transportType = _resolveTransport(transport);
      final isWs = transportType == TransportType.WS;
      final signalPort = effective.port;
      final wsPort = signalPort == 5060 ? 8088 : signalPort;
      final sipUri = isWs
        ? 'sip:${effective.username}@${effective.server}:$wsPort'
        : 'sip:${effective.username}@${effective.server}:$signalPort';
      final registrar = isWs
        ? 'sip:${effective.server}:$wsPort'
        : 'sip:${effective.server}:$signalPort';

      final uaSettings = UaSettings()
        ..host = effective.server
        ..port = (isWs ? wsPort : signalPort).toString()
        ..uri = sipUri
        ..authorizationUser = effective.username
        ..password = effective.password
        ..displayName = effective.username
        ..register = true
        ..registrarServer = registrar
        ..transportType = transportType;

      if (isWs) {
        uaSettings.webSocketUrl = 'ws://${effective.server}:$wsPort/ws';
      }

      await _helper.start(uaSettings);
      _uaStarted = true;
    } catch (error) {
      _registerTimeoutTimer?.cancel();
      _stopUaIfStarted();
      _pendingRegister = false;
      _registrationStatus = SipRegistrationStatus.failed;
      _statusMessage = 'REGISTRATION_FAILED';
      _lastError = error.toString();
      notifyListeners();
    }
  }

  SipCredentials _normalizeForPlatform(SipCredentials input) {
    final normalizedTransport = input.transport.trim().toUpperCase();
    final safeTransport = normalizedTransport == 'TCP' || normalizedTransport == 'WS'
        ? normalizedTransport
        : 'WS';

    return input.copyWith(
      server: input.server.trim(),
      username: input.username.trim(),
      transport: safeTransport,
    );
  }

  Future<void> unregister() async {
    _pendingRegister = false;
    _registerTimeoutTimer?.cancel();
    try {
      await _helper.unregister(true);
      _stopUaIfStarted();
      _runtimeCredentials = _credentials;
      _registrationStatus = SipRegistrationStatus.unregistered;
      _statusMessage = 'Unregistered';
      notifyListeners();
    } catch (_) {
      _stopUaIfStarted();
      _runtimeCredentials = _credentials;
      _registrationStatus = SipRegistrationStatus.unregistered;
      _statusMessage = 'Unregistered';
      notifyListeners();
    }
  }

  Future<bool> makeCall(String destination) async {
    _lastError = '';
    if (_registrationStatus != SipRegistrationStatus.registered) {
      _lastError = 'Register first before placing a call.';
      notifyListeners();
      return false;
    }

    final target = destination.trim();
    if (target.isEmpty) {
      _lastError = 'Enter a phone number or extension.';
      notifyListeners();
      return false;
    }

    final effective = _normalizeForPlatform(_runtimeCredentials);
    final transport = _resolveTransport(effective.transport.trim().toUpperCase());
    if (_isMobileRuntime && _isLoopbackHost(effective.server)) {
      _lastError =
          'Mobile SIP clients cannot place calls to localhost or 127.0.0.1. Use the Asterisk host LAN IP.';
      notifyListeners();
      return false;
    }

    if (_isMobileRuntime && transport != TransportType.WS) {
      _lastError = _mobileTransportGuidance();
      notifyListeners();
      return false;
    }

    final callTarget = transport == TransportType.WS
      ? 'sip:$target@${effective.server}:8088'
      : 'sip:$target@${effective.server}:${effective.port}';
    final placed = await _helper.call(callTarget, voiceOnly: true);
    if (!placed) {
      _lastError = 'Failed to place call. Check SIP registration/network.';
      notifyListeners();
      return false;
    }

    _activeNumber = target;
    _callStartedAt = null;
    _callEndedAt = null;
    _callWasConnected = false;
    _callStatus = ActiveCallStatus.connecting;
    _isIncomingActiveCall = false;
    _statusMessage = 'CALL_INITIATION: Dialing $target';
    notifyListeners();
    return true;
  }

  Future<void> answerIncomingCall() async {
    final call = _activeCall;
    if (call == null) {
      return;
    }

    try {
      call.answer(_helper.buildCallOptions(true));
      _callStatus = ActiveCallStatus.connecting;
      _statusMessage = 'ACCEPTED: Answering...';
      notifyListeners();
    } catch (error) {
      _callStatus = ActiveCallStatus.failed;
      _statusMessage = 'Call failed';
      _lastError = _describeWebRtcFailure(error.toString());
      notifyListeners();
      _activeCall?.hangup();
    }
  }

  Future<void> rejectIncomingCall() async {
    _activeCall?.hangup();
  }

  Future<void> hangup() async {
    _activeCall?.hangup();
  }

  Future<void> toggleMute() async {
    final call = _activeCall;
    if (call == null) {
      return;
    }

    if (_isMuted) {
      call.unmute(true, false);
      _isMuted = false;
    } else {
      call.mute(true, false);
      _isMuted = true;
    }
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    final next = !_audioService.speakerOn;
    await _audioService.setSpeaker(next);
    notifyListeners();
  }

  Future<List<CallLogEntry>> fetchCallLogs() {
    return _storageService.fetchCallLogs();
  }

  String get formattedCallDuration {
    final startedAt = _callStartedAt;
    if (startedAt == null) {
      return '00:00';
    }

    final endTime = _callEndedAt ?? DateTime.now();
    final duration = endTime.difference(startedAt);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void markIncomingNavigationHandled() {
    if (_incomingNavigationPending) {
      _incomingNavigationPending = false;
      notifyListeners();
    }
  }

  TransportType _resolveTransport(String transport) {
    switch (transport) {
      case 'TCP':
        return TransportType.TCP;
      case 'WS':
        return TransportType.WS;
      default:
        return TransportType.WS;
    }
  }

  String _describeWebRtcFailure(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('without dtls fingerprint') ||
        lower.contains('setremotedescription') ||
        lower.contains('webrtc error')) {
      return 'Remote SIP endpoint does not support WebRTC DTLS-SRTP. Register with WS transport and enable DTLS-SRTP/WebRTC on PBX endpoint.';
    }
    return rawError;
  }

  String _describeCallFailure(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('486') || lower.contains('busy')) {
      return '486 Busy Here';
    }
    if (lower.contains('408') || lower.contains('no answer')) {
      return '408 Request Timeout (no answer)';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return '403 Forbidden';
    }
    if (lower.contains('401') || lower.contains('407') || lower.contains('unauthorized')) {
      return 'Authentication challenge failed';
    }
    return _describeWebRtcFailure(rawError);
  }

  String _describeRegistrationFailure(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('forbidden') || lower.contains('403')) {
      return 'SIP registration rejected by Asterisk (403 Forbidden). Check the extension username/password and the endpoint transport/auth settings on the PBX.';
    }
    if (lower.contains('unauthorized') || lower.contains('401')) {
      return 'SIP server challenged the credentials (401 Unauthorized). Verify username and password in the settings.';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'SIP extension or server not found. Check the SIP server address and extension.';
    }
    return rawError;
  }

  bool _isIncoming(Call call) {
    final direction = call.direction.toString().toLowerCase();
    return direction.contains('incoming');
  }

  String _extractDisplayNumber(String? raw) {
    if (raw == null) {
      return 'Unknown';
    }

    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Unknown';
    }

    final sipMatch = RegExp(r'sip:([^@;>]+)', caseSensitive: false).firstMatch(trimmed);
    if (sipMatch != null) {
      final value = sipMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final angleMatch = RegExp(r'<([^>]+)>').firstMatch(trimmed);
    if (angleMatch != null) {
      final value = angleMatch.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return trimmed;
  }

  void _activateIncomingUi() {
    _isIncomingActiveCall = true;
    _callStatus = ActiveCallStatus.ringing;
    _statusMessage = 'Incoming call from $_activeNumber';
    _incomingNavigationPending = true;
  }

  Future<void> _persistCallLog({
    required String number,
    required bool isIncoming,
    required bool wasConnected,
    required DateTime? startedAt,
    required DateTime endedAt,
  }) async {
    if (number.trim().isEmpty) {
      return;
    }

    final durationSeconds = startedAt == null ? 0 : endedAt.difference(startedAt).inSeconds;

    final type = isIncoming
        ? (wasConnected ? CallLogType.incoming : CallLogType.missed)
        : CallLogType.outgoing;

    final entry = CallLogEntry(
      number: number,
      type: type,
      timestamp: endedAt,
      durationSeconds: durationSeconds,
    );

    await _storageService.saveCallLog(entry);
  }

  @override
  void callStateChanged(Call call, CallState state) {
    _activeCall = call;

    if (_activeNumber.isEmpty) {
      _activeNumber = _extractDisplayNumber(call.remote_identity);
    }

    final incoming = _isIncoming(call);
    if (incoming) {
      _isIncomingActiveCall = true;
    }

    switch (state.state) {
      case CallStateEnum.CALL_INITIATION:
        _callStartedAt = null;
        _callEndedAt = null;
        _callWasConnected = false;
        if (incoming) {
          _activateIncomingUi();
        } else {
          _callStatus = ActiveCallStatus.connecting;
          _statusMessage = 'CALL_INITIATION: Dialing $_activeNumber';
        }
        break;
      case CallStateEnum.CONNECTING:
        if (incoming && !_callWasConnected) {
          _activateIncomingUi();
        } else {
          _callStatus = ActiveCallStatus.connecting;
          _statusMessage = 'CONNECTING';
        }
        break;
      case CallStateEnum.PROGRESS:
        if (incoming && !_callWasConnected) {
          _activateIncomingUi();
        } else {
          _callStatus = ActiveCallStatus.ringing;
          _statusMessage = 'PROGRESS: Ringing...';
        }
        break;
      case CallStateEnum.ACCEPTED:
        _callStatus = ActiveCallStatus.accepted;
        _statusMessage = 'ACCEPTED';
        break;
      case CallStateEnum.CONFIRMED:
        _callStatus = ActiveCallStatus.inCall;
        _statusMessage = 'CONFIRMED: In call';
        _callStartedAt ??= DateTime.now();
        _callWasConnected = true;
        break;
      case CallStateEnum.MUTED:
        _isMuted = true;
        break;
      case CallStateEnum.UNMUTED:
        _isMuted = false;
        break;
      case CallStateEnum.ENDED:
        final number = _activeNumber;
        final startedAt = _callStartedAt;
        final endedAt = DateTime.now();
        final wasIncoming = _isIncomingActiveCall || incoming;
        final wasConnected = _callWasConnected;
        _callStatus = ActiveCallStatus.ended;
        _statusMessage = 'ENDED';
        _callEndedAt = endedAt;
        unawaited(
          _persistCallLog(
            number: number,
            isIncoming: wasIncoming,
            wasConnected: wasConnected,
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        );
        _activeCall = null;
        break;
      case CallStateEnum.FAILED:
        final number = _activeNumber;
        final startedAt = _callStartedAt;
        final endedAt = DateTime.now();
        final wasIncoming = _isIncomingActiveCall || incoming;
        final wasConnected = _callWasConnected;
        _callStatus = ActiveCallStatus.failed;
        final cause = state.cause?.toString();
        final friendlyCause = cause != null && cause.isNotEmpty
          ? _describeCallFailure(cause)
          : '';
        _statusMessage = friendlyCause.isNotEmpty
          ? 'FAILED: $friendlyCause'
          : 'FAILED';
        if (friendlyCause.isNotEmpty) {
          _lastError = friendlyCause;
        }
        _callEndedAt = endedAt;
        unawaited(
          _persistCallLog(
            number: number,
            isIncoming: wasIncoming,
            wasConnected: wasConnected,
            startedAt: startedAt,
            endedAt: endedAt,
          ),
        );
        _activeCall = null;
        break;
      case CallStateEnum.NONE:
      case CallStateEnum.STREAM:
      case CallStateEnum.REFER:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
        break;
    }

    if (_callStatus == ActiveCallStatus.ended ||
        _callStatus == ActiveCallStatus.failed) {
      _resetCallUiState();
    }

    notifyListeners();
  }

  void _resetCallUiState() {
    unawaited(_audioService.reset());
    _isMuted = false;
    _incomingNavigationPending = false;
    _isIncomingActiveCall = false;
    _callWasConnected = false;
    _activeNumber = '';
    _callStartedAt = null;
    _callEndedAt = null;
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    switch (state.state) {
      case RegistrationStateEnum.REGISTERED:
        _registerTimeoutTimer?.cancel();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.registered;
        _statusMessage = 'REGISTERED';
        _lastError = '';
        break;
      case RegistrationStateEnum.REGISTRATION_FAILED:
        _registerTimeoutTimer?.cancel();
        _stopUaIfStarted();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.failed;
        final cause = state.cause.toString();
        final friendly = _describeRegistrationFailure(cause);
        _statusMessage = 'REGISTRATION_FAILED';
        _lastError = friendly;
        break;
      case RegistrationStateEnum.UNREGISTERED:
        _registerTimeoutTimer?.cancel();
        _uaStarted = false;
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.unregistered;
        _statusMessage = 'UNREGISTERED';
        break;
      case RegistrationStateEnum.NONE:
      case null:
        _registerTimeoutTimer?.cancel();
        _pendingRegister = false;
        _registrationStatus = SipRegistrationStatus.idle;
        _statusMessage = 'Idle';
        break;
    }
    notifyListeners();
  }

  @override
  void transportStateChanged(TransportState state) {
    if (state.state == TransportStateEnum.CONNECTED &&
        _pendingRegister &&
        _registrationStatus == SipRegistrationStatus.registering) {
      _statusMessage = 'Transport connected, registering...';
      notifyListeners();
      return;
    }

    if (state.state == TransportStateEnum.DISCONNECTED &&
        (_registrationStatus == SipRegistrationStatus.registered ||
            _registrationStatus == SipRegistrationStatus.registering)) {
      _registerTimeoutTimer?.cancel();
      _stopUaIfStarted();
      _pendingRegister = false;
      _registrationStatus = SipRegistrationStatus.failed;
      _statusMessage = 'Transport disconnected';
      _lastError = 'Transport disconnected while registering.';
      notifyListeners();
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {}

  @override
  void onNewNotify(Notify ntf) {}

  @override
  void onNewReinvite(ReInvite event) {}

  @override
  void dispose() {
    _registerTimeoutTimer?.cancel();
    _helper.removeSipUaHelperListener(this);
    super.dispose();
  }
}
