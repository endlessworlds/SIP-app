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
