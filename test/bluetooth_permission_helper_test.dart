import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zebra_printer_cpcl/zebra_printer.dart';

Future<Object?> _mockApproveAll(MethodCall call) async {
  if (call.method == 'getAndroidSdkVersion') {
    return 35; // Simulate Android 15
  }
  return true;
}

Future<Object?> _mockPermissionHandler(MethodCall call) async {
  switch (call.method) {
    case 'checkPermissionStatus':
      return 1; // granted
    case 'requestPermissions':
      final List<dynamic> permissions = call.arguments as List<dynamic>;
      final Map<int, int> result = {};
      for (final p in permissions) {
        result[p as int] = 1; // granted
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

  const MethodChannel printerChannel =
      MethodChannel('com.sameetdmr.zebra_printer/zebra_print');
  const MethodChannel bluetoothChannel =
      MethodChannel('com.sameetdmr.zebra_printer/bluetooth');
  const MethodChannel permissionChannel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    BluetoothPermissionHelper.setMockSdkVersion(null);
    BluetoothPermissionHelper.mockIsAndroid = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printerChannel, _mockApproveAll);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bluetoothChannel, _mockApproveAll);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, _mockPermissionHandler);
  });

  tearDown(() {
    BluetoothPermissionHelper.setMockSdkVersion(null);
    BluetoothPermissionHelper.mockIsAndroid = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bluetoothChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  group('BluetoothPermissionHelper SDK Version Logic', () {
    test('Android 10 & 11 (API 29 & 30) permissions list', () async {
      BluetoothPermissionHelper.setMockSdkVersion(29);
      final permissions =
          await BluetoothPermissionHelper.getRequiredBluetoothPermissions();

      // On Android 10/11, Location is required for Bluetooth discovery
      expect(permissions, contains(Permission.locationWhenInUse));
    });

    test('Android 12 to 17 (API 31 to 37) permissions list', () async {
      BluetoothPermissionHelper.setMockSdkVersion(35); // Android 15
      final permissions =
          await BluetoothPermissionHelper.getRequiredBluetoothPermissions();

      expect(permissions, contains(Permission.bluetoothScan));
      expect(permissions, contains(Permission.bluetoothConnect));
    });

    test('checkAndRequestPermissions returns true when granted', () async {
      BluetoothPermissionHelper.setMockSdkVersion(35);
      final bool granted =
          await BluetoothPermissionHelper.checkAndRequestPermissions();
      expect(granted, isTrue);
    });

    test('checkAndRequestPermissions returns false when denied on Android 15',
        () async {
      BluetoothPermissionHelper.setMockSdkVersion(35);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, (MethodCall call) async {
        if (call.method == 'requestPermissions') {
          final List<dynamic> permissions = call.arguments as List<dynamic>;
          final Map<int, int> result = {};
          for (final p in permissions) {
            result[p as int] = 0; // denied
          }
          return result;
        }
        return null;
      });

      final bool granted =
          await BluetoothPermissionHelper.checkAndRequestPermissions(
        openSettingsIfPermanentlyDenied: false,
      );
      expect(granted, isFalse);
    });
  });

  group('PrinterManager Permission Integration', () {
    test('checkAndRequestPermissions returns boolean', () async {
      final printerManager = PrinterManager();
      final bool result =
          await printerManager.checkAndRequestPermissions();
      expect(result, isTrue);
    });

    test('arePermissionsGranted returns boolean', () async {
      final printerManager = PrinterManager();
      final bool result = await printerManager.arePermissionsGranted();
      expect(result, isA<bool>());
    });
  });
}
