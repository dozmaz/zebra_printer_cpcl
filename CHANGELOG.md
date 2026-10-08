# Changelog

## 1.0.5

### Fixed
* Fixed `SecurityException: Need android.permission.BLUETOOTH_SCAN permission` during Bluetooth discovery and connection on Android 12+ (Android 12 to Android 17).
* Added pre-execution runtime permission checks and graceful `SecurityException` handling in native `PrinterManager` and `BluetoothManager`.
* Added `Context.RECEIVER_EXPORTED` flag for `BroadcastReceiver` registrations on Android 14+ (API 33+).
* Fixed `android.os.Build` import in native Android managers.

### Added
* Added `BluetoothPermissionHelper` (Dart & Java) for version-adaptive permission management compatible with Android 10 (API 29) through Android 17 (API 37+).
  * Android 10 & 11: Requires `ACCESS_FINE_LOCATION` for Bluetooth discovery.
  * Android 12 to 17: Requires runtime `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`.
* Added `checkAndRequestPermissions()` and `arePermissionsGranted()` methods to `PrinterManager`.
* Added automatic permission verification guards in `PrinterManager.startDiscovery()`, `connect()`, and `getPairedPrinters()`.
* Added `android:usesPermissionFlags="neverForLocation"` to `BLUETOOTH_SCAN` and `android:maxSdkVersion="30"` to legacy Bluetooth permissions in `AndroidManifest.xml`.
* Added unit tests in `test/bluetooth_permission_helper_test.dart`.

## 1.0.4

### Breaking Changes
* Migrated Android plugin implementation from Java to **Kotlin** (`ZebraPrinterPlugin.kt`)
* Migrated Android build scripts from Groovy (`build.gradle`) to **Kotlin DSL** (`build.gradle.kts` / `settings.gradle.kts`)

### Added
* New `lib/zebra_printer_cpcl.dart` — public entrypoint barrel file for the plugin
* New `lib/zebra_printer_cpcl_method_channel.dart` — `MethodChannel` implementation
* New `lib/zebra_printer_cpcl_platform_interface.dart` — platform interface abstraction
* Added `BLUETOOTH_ADVERTISE` permission to `AndroidManifest.xml` (required for Android 12+)
* Added `package` attribute to `AndroidManifest.xml` (`com.sameetdmr.zebra_printer_cpcl`)
* Added `plugin_platform_interface: ^2.1.8` dependency

### Changed
* Updated `permission_handler` from `^12.0.3` to `^13.0.2`
* Updated `android.compileSdk` to **36**
* Updated Jackson dependencies to `2.22.2` (`jackson-core`, `jackson-databind`, `jackson-annotations`)
* Updated Gradle build toolchain — AGP `9.1.0`, Gradle wrapper `8.10.2`, Java `17`
* Removed Apache Commons Lang3 dependency (no longer required)
* Updated `minSdk` to **24**

### Fixed
* Fixed `AndroidManifest.xml` Bluetooth permission declarations — removed `maxSdkVersion` constraint on legacy permissions to ensure correct behavior across all supported API levels

## 1.0.3

* Fixed resolve Android 13+ Bluetooth permission issues and update build configuration

## 1.0.2 - Add permission handling for Bluetooth operations

* Add checkAndRequestPermissions() to BluetoothManager for requesting Bluetooth-related permissions.
* Add _requiredBluetoothPermissions() helper method to determine which permissions are needed on different platforms.
* Improve permission handling by checking for permanently denied permissions and opening app settings when necessary.
* Update README.md with information about permission requirements and usage examples.
* Add test/bluetooth_manager_permissions_test.dart to verify permission handling logic.

## 1.0.1 - Refactor argument retrieval in BluetoothManager and PrinterManager to use generics

* Update README.md to reflect changes in BluetoothManager and PrinterManager

## 1.0.0

* Initial release
* Core features:
  * Scan and discover Bluetooth devices
  * Pair and unpair with Bluetooth devices
  * Connect and disconnect from Zebra printers
  * Send CPCL code to printers
  * Send ZPL code to printers
  * Check printer status
  * Get printer information
* Enum usage:
  * BluetoothDeviceType
  * BluetoothBondState
  * BluetoothConnectionState
  * BluetoothScanState
  * PrinterConnectionState
  * PaperState
  * HeadState
  * PauseState
* Advanced Bluetooth connection management
* Zebra Link-OS SDK integration for Android