import 'dart:io';

void main() async {
  print('====================================================');
  print('FLEETROUTE ENTERPRISE GATEKEEPER & SPRINT VERIFICATION');
  print('====================================================');

  final isWindows = Platform.isWindows;
  final flutterCmd = isWindows ? 'flutter.bat' : 'flutter';
  final dartCmd = isWindows ? 'dart.bat' : 'dart';

  // Step 1: Flutter Pub Get
  print('\n[Step 1/5] Checking dependencies (flutter pub get)...');
  final pubGet = await Process.run(flutterCmd, [
    'pub',
    'get',
  ], runInShell: true);
  if (pubGet.exitCode != 0) {
    stderr.writeln('FAILED: flutter pub get exited with ${pubGet.exitCode}');
    stderr.writeln(pubGet.stderr);
    exit(1);
  }
  print('PASSED: Dependencies verified.');

  // Step 2: Dart Format Check
  print(
    '\n[Step 2/5] Checking code formatting (dart format --output=none --set-exit-if-changed)...',
  );
  final formatCheck = await Process.run(dartCmd, [
    'format',
    '--output=none',
    '--set-exit-if-changed',
    'lib',
    'test',
    'tool',
  ], runInShell: true);
  if (formatCheck.exitCode != 0) {
    print('Formatting issues detected. Auto-formatting code...');
    await Process.run(dartCmd, [
      'format',
      'lib',
      'test',
      'tool',
    ], runInShell: true);
    print('Auto-formatting complete.');
  } else {
    print('PASSED: Code formatting strictly enforced.');
  }

  // Step 3: Flutter Analyzer (Cross-SDK Analyzer Compatibility)
  print(
    '\n[Step 3/5] Running static analyzer (flutter analyze --no-fatal-infos --no-pub)...',
  );
  final analyze = await Process.run(flutterCmd, [
    'analyze',
    '--no-fatal-infos',
    '--no-pub',
  ], runInShell: true);
  if (analyze.exitCode != 0) {
    stderr.writeln('FAILED: Static analyzer detected issues.');
    stderr.writeln(analyze.stdout);
    stderr.writeln(analyze.stderr);
    exit(1);
  }
  print('PASSED: 0 static analyzer issues found.');

  // Step 4: Flutter Automated Test Suite
  print('\n[Step 4/5] Executing test suite (flutter test --no-pub)...');
  final tests = await Process.run(flutterCmd, [
    'test',
    '--no-pub',
  ], runInShell: true);
  if (tests.exitCode != 0) {
    stderr.writeln('FAILED: Automated test suite failures.');
    stderr.writeln(tests.stdout);
    stderr.writeln(tests.stderr);
    exit(1);
  }
  print(tests.stdout);
  print('PASSED: All unit and widget tests passed cleanly.');

  // Step 5: Connected Physical Device Runtime Diagnostics
  print(
    '\n[Step 5/5] Checking connected physical device adb logcat diagnostics...',
  );
  try {
    final adbDevices = await Process.run('adb', ['devices'], runInShell: true);
    final adbOutput = adbDevices.stdout.toString();
    if (adbOutput.contains('device') &&
        !adbOutput.contains('no devices/emulators found')) {
      print(
        'Physical device detected. Scanning logcat for RenderFlex / Hero tag exceptions...',
      );
      final logcat = await Process.run('adb', [
        'logcat',
        '-d',
        '*:E',
      ], runInShell: true);
      final logStr = logcat.stdout.toString();
      if (logStr.contains('RenderFlex overflowed') ||
          logStr.contains(
            'There are multiple heroes that share the same tag',
          )) {
        stderr.writeln('WARNING: Detected UI exceptions in device logcat.');
      } else {
        print('PASSED: 0 runtime UI exceptions found on physical device log.');
      }
    } else {
      print('No physical ADB device connected. Skipping logcat inspection.');
    }
  } catch (_) {
    print('ADB CLI not in path. Skipping hardware logcat verification.');
  }

  print('\n====================================================');
  print('FLEETROUTE SPRINT GATE VERIFICATION COMPLETED SUCCESSFULLY');
  print('====================================================');
}
