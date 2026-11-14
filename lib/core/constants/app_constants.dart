class AppConstants {
  static const String appName = 'FleetRoute';
  static const String appSubtitle = 'Enterprise Autonomous Fleet Platform';
  static const String appVersion = '1.0.0+1';

  // Platform Channel Names
  static const String obdControlChannel = 'com.safeer.fleetroute/obd_control';
  static const String obdTelemetryChannel =
      'com.safeer.fleetroute/obd_telemetry';

  // Database
  static const String databaseName = 'fleetroute_enterprise.db';
  static const int databaseVersion = 1;

  // Preferences Keys
  static const String prefThemeMode = 'fleetroute_theme_mode';
  static const String prefSimulatedLatency = 'fleetroute_sim_latency';
  static const String prefForceHttp503 = 'fleetroute_force_503';
  static const String prefGeofenceBreachSim = 'fleetroute_sim_geofence_breach';

  // Map Default Focus (Lahore Freight Corridor)
  static const double defaultLat = 31.5204;
  static const double defaultLng = 74.3587;
  static const double defaultZoom = 11.5;

  // Primary Depot (Lahore Gateway Freight Hub)
  static const double depotLat = 31.4700;
  static const double depotLng = 74.2720;
  static const double geofenceRadiusKm = 4.5;
}
