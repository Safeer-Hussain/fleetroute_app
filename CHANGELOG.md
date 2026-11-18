# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-11-18

### Added
- **Cold-Chain Temperature Excursion Alert Log & Audit Exporter (Sprint 3)**:
  - Real-time pharmaceutical cold-chain temperature telemetry monitoring and continuous duration tracking.
  - Automated threshold breach detection for temperatures exceeding -15.0°C for >= 300 seconds (5 minutes) compliant with WHO/FDA Good Distribution Practice (GDP) Annex 5 standards.
  - SQLite persistence table `temperature_excursions` with status classification (`COMPLIANT_TRANSIENT` vs `EXCURSION_VIOLATION`).
  - Interactive QA auditor sign-off dialog for recording corrective actions and root cause investigations.
  - Full CSV audit manifest generation and one-tap clipboard exporter.
  - Direct access from main navigation shell with landscape 360dp height viewport safety.
  - Automated unit and widget tests covering boundary conditions, compliance transitions, and landscape rendering.
- **GitHub Release Automation Workflow**:
  - Added `.github/workflows/release.yml` for automated release APK generation (`flutter build apk --release`) and GitHub Release artifact publishing on `v*` tag pushes.

### Fixed
- Ensured `SingleChildScrollView` horizontal scroll safety on choice chips and metrics header to eliminate horizontal RenderFlex overflows on narrow viewports.

## [1.0.0] - 2026-11-17

### Added
- **Initial Enterprise Autonomous Fleet Telematics Architecture**:
  - Feature-First Clean Architecture (`core/`, `domain/`, `data/`, `presentation/`).
  - Native OBD-II CAN-bus bridge with real-time telemetry streaming (`MethodChannel` and `EventChannel`).
  - Multi-Stop Route Optimizer powered by spatial Haversine distance solver.
  - Electronic Proof of Delivery (ePOD) with SVG signature capture and receipt generation.
  - On-Device AI Dispatch Copilot powered by reactive token streaming.
  - Driver Hours of Service (HOS) fatigue counter and rest stop finder (Sprint 1).
  - Corridor Toll and Border Customs Fee Estimator with axle-indexed tariff calculation (Sprint 2).
  - Offline-first SQLite persistence and Dio mock network interceptor.
  - Dark/Light theme switching parity and 360dp landscape viewport safety.
