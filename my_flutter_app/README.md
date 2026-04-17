## Local Asterisk DevContainer

This repository includes a devcontainer that installs Asterisk and starts it in the foreground so the Flutter SIP prototype has a local backend during development.

The container ships with two test users:
- `1001` / `1234`
- `1002` / `1234`

Relevant Asterisk config lives in [.devcontainer/asterisk](../.devcontainer/asterisk). The WebSocket SIP transport listens on `ws://localhost:8088/ws`, and the PJSIP UDP transport listens on `5060`.

To use it:
1. Reopen the workspace in the devcontainer.
2. Let Asterisk start automatically.
3. Run `asterisk -rx "pjsip show endpoints"` inside the container to confirm the users are loaded.
4. Point the Flutter app at `localhost` from inside the container, or use the host/container IP from an Android device on the same network.

This is the plan:

I want you to build an open-source competitor for SIP phone applications. To understand what a SIP phone software looks like, take a reference from Bria — it provides SIP phone functionality across both mobile and desktop.

For implementation, you can use Flutter so that we can have a single codebase for both desktop and mobile apps.

This will be the core project direction.
https://www.counterpath.com/bria-mobile


Two flows matter most: how a user gets registered on the SIP server, and what happens when they make a call. Here they are, one at a time.

![alt text](public/image.png)


Now the call flow — what happens from the moment the user taps "call" to when audio is flowing.---

![alt text](public/image-1.png)
How registration works — the full picture
There is no "login system" you need to build. SIP handles it natively. Here's exactly what you do at each level:
On the server (sip.conf in Asterisk):
[1001]
type=friend
secret=password123
host=dynamic
context=phones

That's one user. 1001 is their extension (also their username). secret is their password. host=dynamic means they can register from any IP. Repeat this block for every user. Reload Asterisk — done.
On the Flutter app (sip_service.dart):
final settings = UaSettings();
settings.webSocketUrl  = 'ws://YOUR_SERVER_IP:8088/ws';
settings.uri           = 'sip:1001@YOUR_SERVER_IP';
settings.authorizationUser = '1001';
settings.password      = 'password123';
settings.displayName   = 'User Name';

_ua = UA(settings);
_ua.start();

That's it. dart_sip_ua fires the REGISTER automatically when you call _ua.start(). It also handles the 401 → digest-auth retry automatically. You never write that part.
What happens on first launch:
App shows a Settings screen with three fields: SIP server IP, username, password.
User fills these in once and taps Save.
You store them with flutter_secure_storage (encrypted on device).
On every subsequent launch, you read them back and call _ua.start().
If registration succeeds → show "Ready". If it fails (wrong password, server unreachable) → show an error on the same screen

There is no separate account database you need to build. Asterisk is the user database. Adding/removing users is editing sip.conf and running asterisk -rx "sip reload".

What to build — screens and services only
4 screens:
SettingsScreen — server IP, username, password, Save button. Shown on first launch or when not registered.
DialpadScreen — number input + call button. Only shown when registered.
CallScreen — shown during an active call. Shows duration, mute toggle, hang-up button.
CallLogScreen — list of past calls from local storage.
3 services:
SipService — wraps dart_sip_ua. Exposes register(), call(number), hangup(), mute(), and a stream of call state changes.
AudioService — (physical devices)wraps flutter_webrtc. Starts/stops the mic. Switches between earpiece and speaker.
StorageService — flutter_secure_storage for credentials, shared_preferences for call log.

Local vs real world — exactly what changes


Local dev
Real world
Server
Asterisk in Docker on your laptop
Same Docker image on a $5 VPS
App config
Server IP = 192.168.x.x (your LAN IP)
Server IP = your VPS public IP
WebSocket
ws://192.168.x.x:8088/ws
wss://yourdomain.com:8089/ws (TLS)
NAT
Not an issue (same network)
Add STUN: stun:stun.l.google.com:19302 in UaSettings
Firewall
Nothing to open
Open UDP 5060 (SIP) + 10000–20000 (RTP)

One line of config changes between local and production. Everything else is identical.


Why NAT is a problem for SIP calls
SIP and RTP (audio) need two-way communication. When your app sends audio to the other person, it tells them "send audio back to me at 192.168.1.5:10000". But that address is private — the other person is on the internet and has no idea how to reach 192.168.1.5. The audio gets lost.
Your app says:  "send RTP audio to 192.168.1.5:10000"
Other person:   has no route to 192.168.1.5
Result:         one-way audio or no audio at all

How it's solved — STUN
A STUN server is a simple public server that tells your app what its real public IP and port looks like from the outside.
Your app  →  STUN server:  "what's my public address?"
STUN      →  "you are 203.0.113.45:54321"
Your app  →  tells the other person "send audio to 203.0.113.45:54321"
Router    →  forwards it to your private IP correctly
You just add one line in your Flutter app:
dart
settings.iceServers = [
  {'url': 'stun:stun.l.google.com:19302'}
];
Google runs a free public STUN server. That one line fixes NAT for most cases.

When STUN isn't enough — TURN
Some strict corporate firewalls or mobile networks block direct peer-to-peer connections entirely. STUN won't work because there's no path through at all. In that case you need a TURN server — it acts as a relay, bouncing the audio through itself.
Without TURN:   your app  ←→  other person   (blocked)
With TURN:      your app  →  TURN server  →  other person
Twilio provides TURN servers automatically. For local dev with Asterisk you won't hit this problem because you're on the same network.

In plain terms


What it is
NAT
Your router hiding your real local IP from the internet
STUN
A free lookup service that tells your app its real public address
TURN
A relay server for when direct connection is completely blocked



## Plan: SIP App Working Prototype (Android + Linux)

This draft turns the current Flutter starter into a simple, readable, working SIP prototype aligned with the README goals: full call flow (register, outbound/inbound handling, hangup), in-call controls (mute/speaker), and basic call logging. It prioritizes Android first (fastest SIP/media validation), then stabilizes Linux behavior. It also documents two backend paths: external SIP server and local Asterisk. The plan is scoped to the existing architecture target (screens + services) in [my_flutter_app/README.md](my_flutter_app/README.md#L50-L60), while replacing the current template app in [my_flutter_app/lib/main.dart](my_flutter_app/lib/main.dart#L1-L117).

**Steps**
1. Define MVP acceptance criteria in [my_flutter_app/README.md](my_flutter_app/README.md#L50-L60): successful SIP register, outbound call, inbound call handling, mute toggle, speaker toggle, hangup, and call log persistence.
2. Add required dependencies in [my_flutter_app/pubspec.yaml](my_flutter_app/pubspec.yaml): sip/media, secure credential storage, preferences-based call log, and Android mic-permission support.
3. Add platform prerequisites for Android in [my_flutter_app/android/app/src/main/AndroidManifest.xml](my_flutter_app/android/app/src/main/AndroidManifest.xml#L1-L44): network + microphone permissions needed for SIP/media in non-debug builds.
4. Replace template UI in [my_flutter_app/lib/main.dart](my_flutter_app/lib/main.dart#L1-L117) with app routing and state entrypoint, then create screens matching README scope: Settings, Dialpad, Call, Call Log under lib/.
5. Implement service layer per README architecture: SIP service for registration/call lifecycle, storage service for creds/logs, and audio control integration for mute/speaker behavior.
6. Wire event-driven state flow: SIP events update UI states (idle, registering, registered, ringing, in-call, ended) and append call records on success/failure/missed calls.
7. Implement Android-first happy path and error UX (invalid creds, registration failure, call failure), then run Linux parity pass for call flow and audio route behavior.
8. Update docs in [my_flutter_app/README.md](my_flutter_app/README.md) with exact run instructions for prototype usage and both backend options (external SIP and local Asterisk path).

**Verification**
- Environment/setup: `cd /workspaces/SIP-app/my_flutter_app`, `flutter pub get`, `flutter devices`.
- Android validation: `flutter run -d <androidDeviceId>` and verify register → call → mute/speaker → hangup → call log entry.
- Linux validation: `flutter run -d linux` and verify same flow (noting platform-specific route behavior).
- Basic quality checks: `flutter analyze`, `flutter test` (existing test file is currently template and should be updated for new app flow in [my_flutter_app/test/widget_test.dart](my_flutter_app/test/widget_test.dart#L1-L30)).

**Decisions**
- Scope includes full flow + call log + mute/speaker (per your selection), but delivery is phased Android-first then Linux stabilization.
- SIP backend docs include both options: external server and local Asterisk.
- Plan file target is repository root: [PLAN.md](PLAN.md).




# SIP App Build Plan

## Overview
Build a working Flutter SIP prototype for Android first, then Linux desktop, using the current starter project in `my_flutter_app/`. The goal is a simple, readable app that supports the core SIP call flow and basic call logging.

## Target Features
- SIP registration
- Outbound calling
- Inbound call handling
- Hang up
- Mute toggle
- Speaker toggle
- Call log persistence
- Android-first validation, then Linux parity

## Architecture Direction
The app should move from the template Flutter app into a screen-and-service architecture:
- `Settings` screen for SIP credentials and server configuration
- `Dialpad` screen for outbound calls
- `Call` screen for live call controls and status
- `Call Log` screen for history
- Service layer for SIP, storage, and audio controls

## Build Steps

### 1. Set up the environment
Make sure the dev container and Flutter tooling are ready.

#### Commands
```bash
flutter config --enable-linux-desktop --enable-macos-desktop --enable-windows-desktop
cd /workspaces/SIP-app/my_flutter_app
flutter pub get
flutter devices
```

### 2. Define the MVP requirements
Document the app behavior and acceptance criteria before implementation.

#### MVP acceptance criteria
- Successful SIP registration
- Successful outbound call
- Successful inbound call handling
- Mute toggle works during a call
- Speaker toggle works during a call
- Hangup ends the call cleanly
- Call logs are saved and shown

### 3. Add dependencies
Update `my_flutter_app/pubspec.yaml` with the packages needed for SIP, secure storage, preferences, and permissions.

#### Expected dependency groups
- SIP/media library
- Secure credential storage
- Preferences or local storage for call logs
- Android microphone permission support

### 4. Add Android platform prerequisites
Update Android configuration so SIP and audio features work in release builds.

#### Expected Android changes
- Internet/network permission
- Microphone permission
- Any required audio or foreground-service support if used by the SIP stack

### 5. Replace the template app
Remove the default starter UI and replace it with the actual app entrypoint and routing.

#### Implementation areas
- `lib/main.dart` as the app bootstrap
- Routing or navigation setup
- Shared state management for SIP status and call state

### 6. Create the feature screens
Build the UI around the core call workflow.

#### Screens
- `Settings`
- `Dialpad`
- `Call`
- `Call Log`

#### UI behavior
- Show registration state
- Show call state transitions
- Allow entering SIP credentials and server details
- Allow dialing and ending calls
- Allow toggling mute and speaker
- Show recent call records

### 7. Implement the service layer
Separate SIP and storage logic from UI.

#### Services to implement
- SIP service for registration, call lifecycle, incoming calls, and hangup
- Storage service for credentials and call logs
- Audio control service for mute and speaker routing

### 8. Wire event-driven state flow
Connect SIP events to the UI.

#### Core states
- idle
- registering
- registered
- ringing
- in-call
- ended
- failed

#### Event handling
- Update UI when registration succeeds or fails
- Update UI when a call starts, rings, ends, or fails
- Save call log entries on success, failure, and missed calls

### 9. Support both backend methods
Document and support two SIP backend options.

#### Backend methods
- External SIP server
- Local Asterisk server

#### Notes
- External server is good for quick testing
- Asterisk is useful for local controlled validation

### 10. Prioritize Android first
Implement and validate the full happy path on Android before stabilizing desktop behavior.

#### Android validation flow
- Register
- Place outbound call
- Receive inbound call
- Toggle mute
- Toggle speaker
- Hang up
- Verify call log entry

### 11. Stabilize Linux desktop behavior
After Android works, verify the same flow on Linux.

#### Linux validation flow
- Register
- Place outbound call
- Handle inbound call
- Toggle mute
- Toggle speaker
- Hang up
- Verify call log behavior

### 12. Update documentation
Keep the README and build notes aligned with the implementation.

#### Documentation to update
- Setup instructions
- Run instructions
- Backend configuration
- Verification steps
- Known limitations by platform

## Verification Checklist
- `flutter pub get`
- `flutter devices`
- `flutter run -d <androidDeviceId>`
- `flutter run -d linux`
- `flutter analyze`
- `flutter test`

## Recommended Build Order
1. Confirm tooling and Flutter targets
2. Define MVP acceptance criteria
3. Add dependencies
4. Update Android permissions
5. Replace template app entrypoint
6. Build screens
7. Implement services
8. Wire SIP events to UI state
9. Add call logging
10. Validate Android end-to-end
11. Validate Linux end-to-end
12. Update documentation

## Methods Used to Build the Project
- Use Flutter for the cross-platform UI
- Keep SIP, storage, and audio logic in services instead of widgets
- Drive the UI from events and state changes
- Validate Android first for the fastest SIP/media feedback loop
- Use Linux desktop as the next parity target
- Support both external SIP servers and local Asterisk for testing flexibility

## Notes
- The current workspace contains the Flutter app in `my_flutter_app/`.
- The template app should be replaced with the prototype architecture above.
- This plan is intended to guide implementation from starter app to working SIP prototype.

