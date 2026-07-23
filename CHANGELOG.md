# Changelog

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