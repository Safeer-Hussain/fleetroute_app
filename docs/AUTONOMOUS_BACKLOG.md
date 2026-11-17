# FleetRoute Autonomous Engineering Backlog

This backlog defines 25 granular daily engineering sprints for autonomous iteration.
Execute using the 6-phase autonomous sprint rule:
`Pre-flight checks` -> `Select first [ ] item` -> `Implement Clean Architecture code` -> `Automated Tests` -> `tool/sprint_gate.dart validation` -> `Commit & Push to origin main and fleetroute_app main`.

---

- [x] **Sprint 1: Driver HOS (Hours of Service) Fatigue & Rest Stop Timer**
  - *User Story*: As a long-haul freight driver, I need a visual HOS clock tracking driving hours (max 11h) and mandatory 30-min break alerts to stay compliant with federal transport regulations.
  - *Acceptance Criteria*: Countdown timer persisted to SQLite, visual amber/red warning states when approaching 8h and 11h thresholds, and nearest freight rest stop finder.
  - *Test Matrix*: HOS unit tests validating clock decrement, state transitions (`DRIVING`, `ON_DUTY`, `SLEEPER_BERTH`, `OFF_DUTY`), and widget tests for the countdown gauge. (Passed 7 unit tests + 3 widget tests).

- [x] **Sprint 2: Toll & Border Customs Fee Estimator**
  - *User Story*: As a dispatch accountant, I need automated highway toll fee and provincial border clearance fee calculation for any planned dispatch route.
  - *Acceptance Criteria*: Spatial highway toll barrier geocoding, vehicle axle-based fee lookup (2-axle vs 4-axle semi), total toll fee summarized on route detail card.
  - *Test Matrix*: Fee calculation unit tests across axle tiers and border crossing nodes. (Passed 8 unit tests + 3 widget tests).

- [ ] **Sprint 3: Cold-Chain Temperature Excursion Alert Log & Audit Exporter**
  - *User Story*: As a pharmaceutical quality assurance auditor, I need an automated excursion audit report capturing any time reefer temperature exceeds -15°C for more than 5 minutes.
  - *Acceptance Criteria*: SQLite audit table `temperature_excursions`, duration tracking, CSV/PDF formatted export sheet.
  - *Test Matrix*: Excursion detection logic tests, duration threshold boundary tests, export serialization tests.

- [ ] **Sprint 4: Fuel Station Lowest-Price Dynamic Route Finder**
  - *User Story*: As a fleet operator, I want the route optimizer to suggest refueling stops at highway fuel depots with the lowest verified diesel price along the corridor.
  - *Acceptance Criteria*: Corridor fuel station nodes mapped, price delta calculation, 1-tap route waypoint injection.
  - *Test Matrix*: Nearest corridor station search algorithm tests, fuel cost saving delta assertions.

- [ ] **Sprint 5: Multi-Depot Fleet Load Balancing Calculator**
  - *User Story*: As an enterprise logistics director, I need an automated load-balancing calculator that redistributes idle trucks from oversaturated depots to high-demand terminals.
  - *Acceptance Criteria*: Vehicle availability vs pending waybill ratio per depot, automated deadhead mileage reduction recommendation.
  - *Test Matrix*: Deadhead mileage optimization formulas, load-balancing allocation unit tests.

- [ ] **Sprint 6: Hazardous Materials (HAZMAT) Freight Route Restrictions Engine**
  - *User Story*: As a safety compliance officer, I need HAZMAT freight routes to automatically bypass residential tunnels, water reservoirs, and congested urban cores.
  - *Acceptance Criteria*: Route classification tags (`HAZMAT_CLASS_1` through `CLASS_9`), avoidance polygon geofences, fallback highway routing.
  - *Test Matrix*: Geofence intersection tests, tunnel bypass route assertion tests.

- [ ] **Sprint 7: Real-Time Fleet Geofence ETA & Customer Notification Dispatcher**
  - *User Story*: As a cargo consignee, I want automatic SMS/Webhook notifications triggered when the delivery truck is 15 minutes away or breaches the 3km terminal geofence.
  - *Acceptance Criteria*: Geofence proximity trigger, webhook mock payload dispatcher, ETA countdown badge.
  - *Test Matrix*: Geofence distance calculation tests, webhook event emission tests.

- [ ] **Sprint 8: Driver Behavior Scorecard & Harsh Braking / Acceleration Telematics**
  - *User Story*: As a fleet safety director, I need a driver safety scorecard based on CAN-bus accelerometer events (harsh braking >0.4g, rapid acceleration, speeding).
  - *Acceptance Criteria*: Telemetry packet delta calculation, driver safety score (0-100), weekly driver leaderboard UI.
  - *Test Matrix*: G-force threshold math tests, driver safety score reduction algorithms.

- [ ] **Sprint 9: Predictive Brake Pad & Engine Oil Life Estimator**
  - *User Story*: As a maintenance workshop chief, I need predictive wear estimators based on accumulated vehicle mileage, engine hours, and braking frequency.
  - *Acceptance Criteria*: Oil life % countdown, brake pad thickness degradation model, automated "Service Due in 1,200 km" banner.
  - *Test Matrix*: Mileage wear formula tests, service threshold trigger assertions.

- [ ] **Sprint 10: Digital Bill of Lading (eBOL) Multi-Document Exporter**
  - *User Story*: As a freight dispatcher, I need to generate standardized eBOL documents combining shipper details, cargo hazardous declarations, carrier SCAC, and consignee sign-off.
  - *Acceptance Criteria*: Formatted eBOL preview sheet, SHA-256 digital tamper stamp, clipboard and JSON export.
  - *Test Matrix*: eBOL field schema validation, tamper hash determinism tests.

- [ ] **Sprint 11: Electric Fleet Charging Curve & Range Prediction Engine**
  - *User Story*: As an EV delivery courier, I need dynamic state-of-charge (SoC) prediction taking into account payload weight, ambient temperature, and elevation gradients.
  - *Acceptance Criteria*: EV battery drain modeling, minimum charging stop duration calculator, low SoC (<15%) emergency redirect.
  - *Test Matrix*: Battery drain gradient formula tests, charging stop sequencer tests.

- [ ] **Sprint 12: Reverse Logistics & Return Cargo Consolidation Matcher**
  - *User Story*: As a freight coordinator, I want to assign empty returning trucks to nearby pickup orders to minimize empty-haul runs.
  - *Acceptance Criteria*: Return corridor matching, vehicle payload capacity validation, reverse manifest creation.
  - *Test Matrix*: Capacity check assertions, corridor proximity match tests.

- [ ] **Sprint 13: Tire Wear & Tread Depth Ultrasonic Scan Integration**
  - *User Story*: As a workshop inspector, I want to record ultrasonic tire tread depth measurements across all 4-8 wheels to detect irregular camber wear.
  - *Acceptance Criteria*: 3D/2D tire tread input interface, irregular wear warning (<3.0 mm), replacement recommendation.
  - *Test Matrix*: Tread wear validation rules, warning threshold trigger tests.

- [ ] **Sprint 14: Automated Dispatch Roster & Driver Shift-Change Handover**
  - *User Story*: As a depot supervisor, I need a digital handover sheet where incoming drivers review previous vehicle faults, fuel levels, and current cargo manifests before key handover.
  - *Acceptance Criteria*: Pre-trip inspection checklist, driver digital sign-off, shift handover history.
  - *Test Matrix*: Form completeness validation, handover state persistence tests.

- [ ] **Sprint 15: Cross-Docking Transshipment Manifest Optimizer**
  - *User Story*: As a hub manager, I need to sequence pallet transfers directly from arriving trunk trailers into departing last-mile vans without warehouse storage.
  - *Acceptance Criteria*: Inbound/outbound vehicle dock schedule matching, transfer barcode ledger.
  - *Test Matrix*: Dock scheduling collision tests, pallet assignment math tests.

- [ ] **Sprint 16: Dynamic Highway Traffic Jam Rerouting with Alternative Corridor Scoring**
  - *User Story*: As a highway dispatcher, I want real-time bottleneck detection that evaluates secondary toll roads and scores alternative routes by fuel delta and time savings.
  - *Acceptance Criteria*: Speed drop detection (<20 km/h on expressways), alternative route cost-benefit scoring, 1-tap route acceptance.
  - *Test Matrix*: Speed drop detector tests, route switch BLoC state assertions.

- [ ] **Sprint 17: Reefer Multi-Compartment Dual-Temperature Telematics**
  - *User Story*: As a frozen food logistics operator, I need dual-zone reefer monitoring: Zone 1 (-20°C Frozen) and Zone 2 (+4°C Chilled) in a single trailer.
  - *Acceptance Criteria*: Dual sensor gauges on OBD screen, separate excursion alerts per zone.
  - *Test Matrix*: Dual zone telemetry parser tests, independent alert threshold tests.

- [ ] **Sprint 18: In-Cab Incident Audio/Video Blackbox Metadata Logger**
  - *User Story*: As a safety auditor, I want a tamper-evident incident event logger recording CAN-bus speed, braking, GPS coordinates, and timestamp during sudden impact or deceleration events.
  - *Acceptance Criteria*: SQLite blackbox table, 30-second pre/post crash event buffering, audit log exporter.
  - *Test Matrix*: Blackbox buffer rollover tests, crash event capture trigger tests.

- [ ] **Sprint 19: High-Value Cargo Anti-Tamper Electronic Seal (e-Seal) NFC Scanner**
  - *User Story*: As a high-value freight escort, I need to scan and verify active container e-Seals with cryptographically signed NFC payloads at every checkpoint.
  - *Acceptance Criteria*: Simulated NFC/barcode e-Seal verification, seal breach detection, timestamped audit trail.
  - *Test Matrix*: Seal signature verification tests, breach status transition tests.

- [ ] **Sprint 20: Carbon Offset & Green Fleet Scope 1 Emission Ledger**
  - *User Story*: As an ESG compliance director, I need automated Scope 1 greenhouse gas calculations (kg CO2e per ton-km) across diesel vs electric fleet assets.
  - *Acceptance Criteria*: EPA/DEFRA carbon emission factors, weekly ESG report summary widget, green asset optimization badge.
  - *Test Matrix*: Emission factor formulas, diesel vs EV delta assertion tests.

- [ ] **Sprint 21: Delivery Window Appointment Slot Booker & Missed SLA Penalties Calculator**
  - *User Story*: As a customer service manager, I need to track 2-hour delivery appointment windows and calculate contractual SLA breach penalties in real time.
  - *Acceptance Criteria*: Appointment window clock, estimated late arrival warning, contractual SLA fee penalty calculation.
  - *Test Matrix*: SLA window comparison math, penalty formula tests.

- [ ] **Sprint 22: Offline Mesh Peer-to-Peer Convoy GPS Relay (BLE Sync)**
  - *User Story*: As a remote highway convoy driver without cellular coverage, I want my vehicle to relay GPS waypoints and emergency beacons to nearby convoy trucks via peer-to-peer Bluetooth.
  - *Acceptance Criteria*: Local mesh packet simulation, vehicle-to-vehicle convoy distance indicator, emergency beacon relay.
  - *Test Matrix*: Mesh packet deserialization tests, convoy distance threshold alerts.

- [ ] **Sprint 23: Automated Preventive Maintenance Work Order Auto-Generator**
  - *User Story*: As a workshop manager, I want critical OBD-II DTC codes (e.g., P0128, P0534) to automatically generate maintenance work orders with pre-assigned mechanics and part lists.
  - *Acceptance Criteria*: Automatic work order generation from active DTCs, labor hours estimation, parts inventory check.
  - *Test Matrix*: Work order generation triggers, parts list mapping tests.

- [ ] **Sprint 24: Driver Expense & Fuel Surcharge Reimbursement Calculator**
  - *User Story*: As a contracted owner-operator, I want to log diesel purchase receipts, highway parking fees, and automatic fuel surcharge adjustments tied to diesel market index rates.
  - *Acceptance Criteria*: Driver expense logging form, fuel surcharge percentage calculation, net reimbursement summary.
  - *Test Matrix*: Surcharge index math tests, receipt sum validation tests.

- [ ] **Sprint 25: Operations Command Wallboard Multi-Screen Dashboard Projection Mode**
  - *User Story*: As an operations center manager, I want an ultra-wide projection wallboard mode displaying live fleet corridors, heatmaps, active excursions, and KPI counters edge-to-edge.
  - *Acceptance Criteria*: Auto-scrolling wallboard mode, high-contrast dark room aesthetics, edge-to-edge KPI tiles.
  - *Test Matrix*: Projection layout responsiveness tests, auto-refresh cycle tests.
