import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../navigation/adaptive_scaffold.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  String _statusText = 'Initializing FleetRoute telemetry engine...';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.repeat(reverse: true);

    // Defer heavy database initialization and precaching to post-frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAsyncInitialization();
    });
  }

  Future<void> _runAsyncInitialization() async {
    try {
      // Step 1: Precache asset images safely in post-frame callback
      if (mounted) {
        final currentContext = context;
        await Future.wait([
          precacheImage(
            const AssetImage('assets/icons/app_icon.png'),
            currentContext,
          ),
          precacheImage(
            const AssetImage('assets/images/heavy_semi_truck.png'),
            currentContext,
          ),
          precacheImage(
            const AssetImage('assets/images/cold_chain_van.png'),
            currentContext,
          ),
          precacheImage(
            const AssetImage('assets/images/electric_courier.png'),
            currentContext,
          ),
          precacheImage(
            const AssetImage('assets/images/driver_avatar.png'),
            currentContext,
          ),
          precacheImage(
            const AssetImage('assets/images/depot_geofence.png'),
            currentContext,
          ),
        ]);
      }

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _statusText = 'Initializing SQLite spatial manifest & route graph...';
      });

      // Step 2: Initialize SQLite database
      final db = await AppDatabase.instance.database;
      await AppDatabase.instance.seedInitialData(db);

      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _statusText = 'Mounting native OBD-II CAN-bus telemetry bridge...';
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _statusText = 'FleetRoute Command Ready.';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _controller.stop();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (ctx, anim, secAnim) => const AdaptiveScaffold(),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.4),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.15),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icons/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'FLEETROUTE',
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enterprise Autonomous Telematics & Dispatch Platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  minHeight: 2.5,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
