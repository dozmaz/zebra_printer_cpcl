# Changelog

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