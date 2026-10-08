import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper for verifying and requesting Bluetooth permissions across Android versions.
/// Fully compatible from Android 10 (API 29) through Android 17 (API 37+).
class BluetoothPermissionHelper {
  static const MethodChannel _printerChannel =
      MethodChannel('com.sameetdmr.zebra_printer/zebra_print');
  static const MethodChannel _bluetoothChannel =
      MethodChannel('com.sameetdmr.zebra_printer/bluetooth');

  /// Cached Android SDK version (e.g. 29 for Android 10, 35 for Android 15).
  static int? _cachedSdkInt;

  /// For mocking Android platform during tests on non-Android CI runners.
  static bool? mockIsAndroid;

  static bool get _isAndroid => mockIsAndroid ?? Platform.isAndroid;

  /// Retrieves the Android SDK version (e.g. 29 for Android 10, 35 for Android 15).
  /// Returns null on non-Android platforms or if detection fails.
  static Future<int?> getAndroidSdkVersion() async {
    if (!_isAndroid) return null;
    if (_cachedSdkInt != null) return _cachedSdkInt;

    try {
      final dynamic result =
          await _printerChannel.invokeMethod('getAndroidSdkVersion');
      if (result is int) {
        _cachedSdkInt = result;
        return _cachedSdkInt;
      }
    } catch (_) {}

    try {
      final dynamic result =
          await _bluetoothChannel.invokeMethod('getAndroidSdkVersion');
      if (result is int) {
        _cachedSdkInt = result;
        return _cachedSdkInt;
      }
    } catch (_) {}

    return null;
  }

  /// Sets mock SDK version (primarily for unit tests).
  static void setMockSdkVersion(int? sdkInt, {bool isAndroid = true}) {
    _cachedSdkInt = sdkInt;
    mockIsAndroid = isAndroid;
  }

  /// Returns the list of [Permission]s required for Bluetooth on the current platform/version.
  ///
  /// - **Android 10 & 11 (API 29 & 30)**:
  ///   Requires [Permission.locationWhenInUse] (Fine Location) for Bluetooth discovery.
  ///   Standard Bluetooth permissions are granted at install-time via Manifest.
  ///
  /// - **Android 12 to 17+ (API 31+)**:
  ///   Requires [Permission.bluetoothScan] and [Permission.bluetoothConnect].
  ///   [Permission.locationWhenInUse] is included for fallback / beacon discovery.
  ///
  /// - **iOS / other platforms**:
  ///   Requires [Permission.bluetooth].
  static Future<List<Permission>> getRequiredBluetoothPermissions() async {
    if (!_isAndroid) {
      return [Permission.bluetooth];
    }

    final int? sdkInt = await getAndroidSdkVersion();

    if (sdkInt != null && sdkInt < 31) {
      // Android 10 (API 29) & Android 11 (API 30)
      return [
        Permission.locationWhenInUse,
        Permission.bluetooth,
      ];
    }

    // Android 12 to 17+ (API 31 - 37+), or fallback if SDK version detection is unavailable
    return [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }

  /// Synchronous fallback permission list when async resolution is not possible.
  static List<Permission> getFallbackPermissions() {
    if (!Platform.isAndroid) {
      return [Permission.bluetooth];
    }
    return [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
  }

  /// Checks if all required permissions are currently granted without prompting the user.
  static Future<bool> arePermissionsGranted() async {
    if (!_isAndroid) {
      return (await Permission.bluetooth.status).isGranted;
    }

    final int? sdkInt = await getAndroidSdkVersion();

    if (sdkInt != null && sdkInt < 31) {
      // Android 10-11: Location is strictly required for discovery
      final locationStatus = await Permission.locationWhenInUse.status;
      return locationStatus.isGranted;
    }

    // Android 12+: Scan & Connect are strictly required
    final scanStatus = await Permission.bluetoothScan.status;
    final connectStatus = await Permission.bluetoothConnect.status;
    return scanStatus.isGranted && connectStatus.isGranted;
  }

  /// Requests the necessary Bluetooth and Location permissions compatible with Android 10 - 17.
  ///
  /// - On Android 10-11: Prompts for Location permission.
  /// - On Android 12-17: Prompts for Nearby Devices (Scan & Connect) and Location.
  ///
  /// If [openSettingsIfPermanentlyDenied] is true and a mandatory permission is permanently
  /// denied, opens app settings so the user can enable it manually.
  ///
  /// Returns `true` if sufficient permissions are granted, `false` otherwise.
  static Future<bool> checkAndRequestPermissions({
    bool openSettingsIfPermanentlyDenied = true,
  }) async {
    final List<Permission> permissions =
        await getRequiredBluetoothPermissions();

    final Map<Permission, PermissionStatus> statuses =
        await permissions.request();

    final int? sdkInt = await getAndroidSdkVersion();

    bool isGranted = true;
    bool anyPermanentlyDenied = false;

    if (_isAndroid && sdkInt != null && sdkInt < 31) {
      // Android 10 & 11: Location permission is mandatory
      final locStatus = statuses[Permission.locationWhenInUse] ??
          statuses[Permission.location];
      if (locStatus != null && !locStatus.isGranted) {
        isGranted = false;
        if (locStatus.isPermanentlyDenied) {
          anyPermanentlyDenied = true;
        }
      }
    } else if (_isAndroid) {
      // Android 12 to 17: Bluetooth Scan & Connect are mandatory
      final scanStatus = statuses[Permission.bluetoothScan];
      final connectStatus = statuses[Permission.bluetoothConnect];

      if (scanStatus != null && !scanStatus.isGranted) {
        isGranted = false;
        if (scanStatus.isPermanentlyDenied) anyPermanentlyDenied = true;
      }
      if (connectStatus != null && !connectStatus.isGranted) {
        isGranted = false;
        if (connectStatus.isPermanentlyDenied) anyPermanentlyDenied = true;
      }
    } else {
      // iOS / other platforms
      for (final entry in statuses.entries) {
        if (!entry.value.isGranted) {
          isGranted = false;
          if (entry.value.isPermanentlyDenied) anyPermanentlyDenied = true;
        }
      }
    }

    if (anyPermanentlyDenied && openSettingsIfPermanentlyDenied) {
      await openAppSettings();
    }

    return isGranted;
  }
}
