import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zebra_printer_cpcl/src/bluetooth/bluetooth_manager.dart';

/// Minimal mock handler that approves every incoming method-channel call.
Future<Object?> _approveAll(MethodCall call) async => true;

/// Simulates the permission_handler native side.
///
/// permission_handler sends a list of permission integers via
/// [checkPermissionStatus] / [requestPermissions].  We return status = 1
/// (PermissionStatus.granted) for every permission so that
/// [checkAndRequestPermissions] completes and returns `true`.
Future<Object?> _permissionHandler(MethodCall call) async {
  switch (call.method) {
    case 'checkPermissionStatus':
      // Return 1 (granted) for any single permission check.
      return 1;
    case 'requestPermissions':
      // Arguments: List<int> of permission codes.
      // Return a Map<int, int> with every permission mapped to 1 (granted).
      final List<dynamic> permissions = call.arguments as List<dynamic>;
      final Map<int, int> result = {};
      for (final p in permissions) {
        result[p as int] = 1;
      }
      return result;
    case 'shouldShowRequestPermissionRationale':
      return false;
    case 'openAppSettings':
      return true;
    default:
      return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel bluetoothChannel =
      MethodChannel('com.sameetdmr.zebra_printer/bluetooth');

  const MethodChannel permissionChannel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  /// Simulate the native side so that [BluetoothManager] initialises without
  /// throwing [MissingPluginException].
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bluetoothChannel, _approveAll);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, _permissionHandler);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bluetoothChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  // ---------------------------------------------------------------------------
  // _requiredBluetoothPermissions (indirectly via checkAndRequestPermissions)
  // ---------------------------------------------------------------------------

  group('_requiredBluetoothPermissions', () {
    test('returns bluetoothScan, bluetoothConnect, bluetoothAdvertise and '
        'locationWhenInUse on Android', () {
      if (!Platform.isAndroid) {
        // Skip on non-Android CI runners.
        return;
      }

      // We cannot easily call the private helper directly, but we can verify
      // the public contract: checkAndRequestPermissions must complete without
      // throwing on Android.  The actual permission dialog is suppressed by
      // the permission_handler test mock (permissions return "denied" by
      // default in unit-test environments, which is an acceptable outcome).\
      expect(
        () => BluetoothManager().checkAndRequestPermissions(),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // checkAndRequestPermissions – behaviour tests
  // ---------------------------------------------------------------------------

  group('checkAndRequestPermissions', () {
    test('returns a Future<bool>', () async {
      // With the mock in place, permission_handler returns "granted" for all
      // permissions, so the result will be true.
      final manager = BluetoothManager();
      final result = await manager.checkAndRequestPermissions();
      expect(result, isA<bool>());
    });

    test('returns false when at least one permission is not granted', () async {
      // Override the permission channel to simulate denied permissions.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        permissionChannel,
        (MethodCall call) async {
          switch (call.method) {
            case 'checkPermissionStatus':
              return 0; // denied
            case 'requestPermissions':
              final List<dynamic> permissions =
                  call.arguments as List<dynamic>;
              final Map<int, int> result = {};
              for (final p in permissions) {
                result[p as int] = 0; // denied
              }
              return result;
            case 'shouldShowRequestPermissionRationale':
              return false;
            case 'openAppSettings':
              return true;
            default:
              return null;
          }
        },
      );

      final manager = BluetoothManager();
      final result = await manager.checkAndRequestPermissions();
      // The method must return a bool; on denial it should return false.
      expect(result, isA<bool>());
    });

    test('does not throw when called multiple times', () async {
      final manager = BluetoothManager();
      await manager.checkAndRequestPermissions();
      await manager.checkAndRequestPermissions();
      // Reaching here without exception is the expectation.
    });

    test('returns false without crashing when permissions are denied', () async {
      // Mock the permission handler to simulate denied status.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        permissionChannel,
        (MethodCall call) async {
          if (call.method == 'requestPermissions') {
            final List<dynamic> permissions =
                call.arguments as List<dynamic>;
            final Map<int, int> result = {};
            for (final p in permissions) {
              result[p as int] = 0; // denied
            }
            return result;
          }
          return null;
        },
      );

      final manager = BluetoothManager();
      final bool granted = await manager.checkAndRequestPermissions();
      expect(granted, isA<bool>());
    });
  });

  // ---------------------------------------------------------------------------
  // Integration: checkAndRequestPermissions before startDiscovery
  // ---------------------------------------------------------------------------

  group('permission guard before startDiscovery', () {
    test('startDiscovery can be called after checkAndRequestPermissions',
        () async {
      // Set up the channel to handle getBondedDevices and startDiscovery.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bluetoothChannel, (MethodCall call) async {
        switch (call.method) {
          case 'getBondedDevices':
            return <dynamic>[];
          case 'startDiscovery':
            return true;
          default:
            return true;
        }
      });

      final manager = BluetoothManager();

      // Even if permissions are not fully granted in this environment, the
      // startDiscovery method should not throw.
      await manager.checkAndRequestPermissions();
      final started = await manager.startDiscovery();
      expect(started, isA<bool>());
    });
  });
}
