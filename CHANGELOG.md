# Changelog

All notable changes to the FleetRoute platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1+2] - 2026-11-18

### Added
- **Cold-Chain Temperature Excursion Alert Log & Audit Exporter (Sprint 3)**:
  - SQLite persistence table `temperature_excursions` with duration tracking and severity classification (`WARNING`, `CRITICAL`, `NOMINAL`).
  - Automated threshold breach detection triggering when reefer temperatures exceed -15.0°C for more than 5 minutes (300 seconds).
  - Pharmaceutical GDP (Good Distribution Practice) compliant RFC 4180 CSV export report generator.
  - Dedicated `ColdChainAuditView` dashboard featuring compliance metrics, filter toggles, auditor breach acknowledgment workflow, and 800x360 landscape safety.
  - Telematics radar map integration with direct excursion audit log navigation when inspecting refrigerated vans.
  - Automated test coverage including 8 unit tests in `test/unit/cold_chain_cubit_test.dart` and 4 widget tests in `test/widget/cold_chain_widget_test.dart`.
- GitHub Actions automated release pipeline (`.github/workflows/release.yml`) for building and publishing release APK artifacts.

## [1.0.0+1] - 2026-11-17

### Added
- **Toll & Border Customs Fee Estimator (Sprint 2)**:
  - Automated highway toll and provincial customs barrier spatial intersection engine.
  - Axle-indexed tariff calculation across 2-axle, 3-axle, and 4-axle+ heavy semi trucks with 5% electronic M-Tag discount.
  - Interactive `TollBreakdownSheet` modal bottom sheet and route optimizer summary card.
- **Driver HOS Fatigue & Rest Stop Timer (Sprint 1)**:
  - Federal Hours of Service driving clock (max 11h) and mandatory 30-min break countdown timers.
  - Nearest freight rest stop discovery and duty status state transitions.
- **Initial FleetRoute Architecture**:
  - Offline-first SQLite spatial manifest and vehicle telematics engine.
  - Native Android/iOS OBD-II CAN-bus bridge and streaming telemetry.
  - Electronic Proof of Delivery (ePOD) with SVG signature capture.
  - On-Device AI Dispatch Copilot chat interface.
