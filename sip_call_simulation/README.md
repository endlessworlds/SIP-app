# SIP Call Handling Simulation (Terminal First)

This folder is a deterministic simulation of your Flutter SIP call lifecycle, backed by the same Asterisk server used in the devcontainer.

It is designed for fast terminal-based verification before wiring behavior into Flutter UI/service code.

## What it validates

- Asterisk is running in the devcontainer.
- WebSocket SIP transport exists (`transport-ws` on port `8088`).
- SIP endpoints `1001` and `1002` exist.
- A call lifecycle is simulated and logged in ordered states equivalent to Flutter `SipService` state handling:
  - `CALL_INITIATION`
  - `PROGRESS`
  - `ACCEPTED`
  - `CONFIRMED`
  - `ENDED`
- Failure paths are simulated and verified:
  - `busy` (`486 USER_BUSY`)
  - `no_answer` (`408 NO_ANSWER`)
  - `registration_fail` (`403 FORBIDDEN`, modeled event)

## Run modes

From repository root:

```bash
bash sip_call_simulation/scripts/run_terminal_simulation.sh all
```

Before device tests, run LAN preflight:

```bash
bash sip_call_simulation/scripts/run_lan_preflight.sh
```

Other modes:

```bash
bash sip_call_simulation/scripts/run_terminal_simulation.sh happy
bash sip_call_simulation/scripts/run_terminal_simulation.sh failure
```

If successful, you will see `Simulation verified successfully` and the state log output.

## Generated output

- Event log: `/tmp/sip_simulation_events.log`
- Expected order definition: `sip_call_simulation/expected/flutter_call_state_order.txt`
- Failure expected orders:
  - `sip_call_simulation/expected/failure_busy_order.txt`
  - `sip_call_simulation/expected/failure_no_answer_order.txt`
  - `sip_call_simulation/expected/failure_registration_order.txt`

## Asterisk changes included

Dialplan context added in `.devcontainer/asterisk/extensions.conf`:

- Context: `sip-sim`
- Extensions:
  - `9100` caller leg (writes ordered caller states)
  - `9101` callee leg (writes ringing/confirmed)
  - `9200` busy failure simulation
  - `9201` no-answer failure simulation
  - `9202` registration-fail simulation

## Protocol matrix (recommended)

- Flutter Android <-> Flutter Android:
  - Transport: `WS`
  - Port: `8088`
  - Accounts: `1001` and `1002`
  - Server: Asterisk host LAN IP (not localhost)
- Flutter Android <-> PC softphone (Linphone/Zoiper):
  - Android side: `WS:8088`, account `1001` or `1002`
  - PC softphone side: `UDP:5060`, account `2001` or `2002`
  - Dialplan accepts direct extension dialing via `phones` context

## Common Flutter/Android pitfalls fixed in project

- No hidden fallback from user-entered LAN IP to localhost.
- Mobile loopback (`localhost`/`127.0.0.1`) is blocked with a clear guidance error.
- WS call target uses configured WS port correctly.
- Default credentials now favor WS setup (`port 8088`) and require explicit server IP.

## Local Wi-Fi checklist (same network)

1. Run Asterisk in devcontainer and verify with LAN preflight script.
2. Confirm both Android devices and host machine are on same Wi-Fi subnet.
3. In each Android app, set server to host LAN IP and transport `WS` port `8088`.
4. Use different accounts (`1001`, `1002`) for each Android device.
5. If using PC softphone, use account `2001` or `2002` on `UDP` `5060`.
6. Ensure host firewall allows inbound `8088/tcp`, `5060/udp`, and `10000-20000/udp`.

This does not replace your existing `phones` context. It only adds a dedicated simulation path.

## How to convert this prototype into Flutter working code later

1. Keep Asterisk `sip-sim` as integration-test mode in dev/staging only.
2. In Flutter `SipService.callStateChanged`, map incoming SIP events to the same ordered model used here.
3. Add a debug-only method in Flutter that calls a backend/dev endpoint or AMI command to trigger:
   - `channel originate Local/9100@sip-sim extension 9101@sip-sim`
4. Parse `/tmp/sip_simulation_events.log` (or AMI events) into assertions for automated tests.
5. Replace the simulation trigger with real dialed targets (`sip:<ext>@<server>:8088`) once verified.

## Notes

- The simulation is signaling/state oriented. It is intended for call flow correctness, not media quality validation.
- `registration_fail` is modeled as a deterministic simulation event to validate Flutter error handling paths.
- For full end-to-end media tests, use two real SIP clients (1001 and 1002) registered via WebSocket + WebRTC.
