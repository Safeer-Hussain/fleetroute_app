# FleetRoute Autonomous Engineering Engine Rules

When prompted with "run daily sprint" or when executing autonomous engineering tasks, strictly adhere to the 6-phase engineering workflow:

## Phase 1: Pre-Flight Environment Checks
1. Verify git working directory is clean (`git status`).
2. Verify current branch is `main`.
3. Check remotes: Ensure `origin` and `fleetroute_app` point to `https://github.com/Safeer-Hussain/fleetroute_app.git`.
4. Run `git pull origin main --rebase` to ensure local repository is up to date.

## Phase 2: Backlog Item Selection
1. Inspect `docs/AUTONOMOUS_BACKLOG.md`.
2. Find the topmost unchecked item (`- [ ] Sprint N: ...`).
3. Parse User Story, Acceptance Criteria, and Test Matrix for the selected sprint.

## Phase 3: Feature Implementation (Strict Clean Architecture)
1. Build Domain Layer first: Entity extensions, Repository contracts in `lib/domain/`.
2. Build Data Layer: Model serialization, SQLite migrations, Repository implementations in `lib/data/`.
3. Build Presentation Layer: BLoCs/Cubits, reactive state mutations, and UI widgets in `lib/presentation/`.
4. Strictly follow:
   - ZERO hardcoded colors (use `Theme.of(context).colorScheme`).
   - ZERO emojis anywhere in code, strings, logs, or commit messages.
   - Unique Hero tags on any new `FloatingActionButton`.
   - Landscape 360dp viewport safety (compact NavigationRail, two-pane master-detail).
   - Keyboard safe layouts (translucent tap-to-dismiss, no double-applied viewInsets).

## Phase 4: Automated Testing
1. Add minimum 2 unit tests covering state emissions and business logic.
2. Add minimum 1 widget test verifying rendering, zero RenderFlex overflows, and zero duplicate Hero tags.
3. Verify test suite passes with `flutter test`.

## Phase 5: Sprint Gate Verification
1. Run `dart run tool/sprint_gate.dart`.
2. Ensure all 5 steps pass:
   - Dependencies verified (`flutter pub get`)
   - Formatting verified (`dart format`)
   - Static analysis 0 issues (`flutter analyze --no-fatal-infos --no-pub`)
   - Test suite 100% pass (`flutter test --no-pub`)
   - Runtime device log verification

## Phase 6: Autonomous Release & Remote Synchronization
1. Mark the completed item as `[x]` in `docs/AUTONOMOUS_BACKLOG.md`.
2. Create conventional commit message without emojis:
   `feat(sprint-N): implement <feature-title> with tests and gatekeeper validation`
3. Push to GitHub:
   - `git push origin main`
   - `git push fleetroute_app main`
4. Verify synchronization: Ensure `git log origin/main..HEAD` is empty.
