# FleetRoute Engineering Rules

When prompted with "run daily sprint" or when developing features for FleetRoute:

1. **Pre-flight Checks**:
   - Check `git status`, verify clean tree on `main`.
   - Ensure remotes `origin` and `fleetroute_app` point to `https://github.com/Safeer-Hussain/fleetroute_app.git`.
2. **Backlog Selection**:
   - Read `docs/AUTONOMOUS_BACKLOG.md` and pick the first unchecked `[ ]` item.
3. **Clean Architecture Implementation**:
   - Feature-First Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`).
   - ZERO hardcoded colors. Use `Theme.of(context).colorScheme`.
   - ZERO emojis anywhere in source code, UI strings, debug logs, or commit messages.
   - Unique Hero tags on every `FloatingActionButton`.
   - Landscape 360dp height viewport safety (compact `NavigationRail`, two-pane master-detail).
   - Keyboard & modal sheet safety (`isScrollControlled: true`, `viewInsets.bottom` single application).
4. **Automated Testing**:
   - Add unit tests for BLoC/Cubit and widget tests for UI.
5. **Sprint Gate Verification**:
   - Run `dart run tool/sprint_gate.dart`. Enforce 0 analyzer issues and 100% test pass.
6. **Commit & Sync**:
   - Mark item `[x]` in `docs/AUTONOMOUS_BACKLOG.md`.
   - Conventional commit without emojis.
   - Push to `origin main` and `fleetroute_app main`.
   - Confirm `git log origin/main..HEAD` is empty.
