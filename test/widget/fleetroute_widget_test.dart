import 'package:fleetroute_app/core/di/injection_container.dart' as di;
import 'package:fleetroute_app/main.dart';
import 'package:fleetroute_app/presentation/navigation/adaptive_scaffold.dart';
import 'package:fleetroute_app/presentation/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'fleetroute_theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    await di.initDependencies(prefOverride: prefs);
  });

  group('FleetRoute Comprehensive Widget Tests', () {
    testWidgets(
      'Test 16: Zero duplicate Hero tag exceptions across multi-tab shell',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const FleetRouteApp(home: AdaptiveScaffold()));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(AdaptiveScaffold), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Navigate to Route Optimizer tab (index 1)
        await tester.tap(find.text('Routes'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);

        // Navigate to ePOD tab (index 2)
        await tester.tap(find.text('ePOD'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);

        // Navigate to OBD-II Diagnostics tab (index 3)
        await tester.tap(find.text('OBD-II'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);

        // Navigate to AI Copilot tab (index 4)
        await tester.tap(find.text('AI Copilot'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 17: Zero RenderFlex overflow errors on 800x360 landscape viewport',
      (tester) async {
        tester.view.physicalSize = const Size(800, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const FleetRouteApp(home: AdaptiveScaffold()));
        await tester.pump(const Duration(milliseconds: 200));

        // NavigationRail is active in landscape
        expect(find.byType(NavigationRail), findsOneWidget);

        // Verify no RenderFlex overflow on landscape layout
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Test 18: Instant Dark / Light theme switching parity', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const FleetRouteApp(home: AdaptiveScaffold()));
      await tester.pump(const Duration(milliseconds: 200));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.dark);

      // Toggle theme via ThemeCubit from element context
      final themeCubit = BlocProvider.of<ThemeCubit>(
        tester.element(find.byType(AdaptiveScaffold)),
      );
      themeCubit.toggleTheme();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final updatedApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updatedApp.themeMode, ThemeMode.light);
      expect(tester.takeException(), isNull);
    });
  });
}
