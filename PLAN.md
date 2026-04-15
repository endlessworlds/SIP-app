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
