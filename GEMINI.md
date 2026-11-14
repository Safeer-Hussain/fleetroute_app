# FleetRoute Autonomous Operating Manual

## Project Overview
- **Name**: FleetRoute
- **Role**: Enterprise Autonomous Fleet Telematics, Multi-Stop Route Optimization, Native OBD-II Vehicle Diagnostics, Electronic Proof of Delivery (ePOD), and On-Device AI Dispatch Copilot Platform.
- **Owner**: Safeer-Hussain
- **Repository**: https://github.com/Safeer-Hussain/fleetroute_app

## Autonomous Sprint Instruction
When prompted with "run daily sprint":
1. Run pre-flight checks (`git status`, verify `main`, sync remotes).
2. Read `docs/AUTONOMOUS_BACKLOG.md` and select the next unchecked `[ ]` sprint.
3. Build the feature across Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`).
4. Write unit and widget tests in `test/`.
5. Run `dart run tool/sprint_gate.dart`.
6. Mark sprint `[x]`, commit conventionally (no emojis), push to `origin main` and `fleetroute_app main`, and verify clean remote log.

## Code Standards
- Zero hardcoded colors.
- Zero emojis anywhere in code, assets, UI, or commit messages.
- Landscape 360dp height viewport safety.
- Unique hero tags on every FloatingActionButton.
- Offline-first SQLite persistence and native OBD-II CAN-bus bridge.
