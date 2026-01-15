import 'package:flutter/services.dart';
import '../models/printer_status.dart';
import '../models/bluetooth_device.dart';
import '../models/printer_info.dart';

/// Discovered Zebra Printer model
class DiscoveredPrinter {
  final String type; // "bluetooth" or "network"
  final String address;
  final String friendlyName;

  DiscoveredPrinter({required this.type, required this.address, required this.friendlyName});

  factory DiscoveredPrinter.fromMap(Map<dynamic, dynamic> map) {
    return DiscoveredPrinter(type: map['type'] as String? ?? '', address: map['address'] as String? ?? '', friendlyName: map['friendlyName'] as String? ?? '');
  }

  @override
  String toString() {
    return 'DiscoveredPrinter{type: $type, address: $address, friendlyName: $friendlyName}';
  }
}

/// Class for communicating with Zebra printers using Link-OS SDK
class PrinterManager {
  /// Singleton instance
  static final PrinterManager _instance = PrinterManager._internal();

  /// Factory constructor
  factory PrinterManager() => _instance;

  /// Private constructor
  PrinterManager._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Method channel
  static const MethodChannel _channel = MethodChannel('com.sameetdmr.zebra_printer/zebra_print');

  /// Callback for when a printer is found during discovery
  void Function(DiscoveredPrinter printer)? onPrinterFound;

  /// Callback for when discovery is finished
  void Function(List<DiscoveredPrinter> printers)? onDiscoveryFinished;

  /// Callback for when connection state changes
  void Function(Map<String, dynamic> info)? onConnectionStateChanged;

  /// Method call handler for callbacks from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPrinterFound':
        if (onPrinterFound != null && call.arguments != null) {
          final printer = DiscoveredPrinter.fromMap(call.arguments as Map<dynamic, dynamic>);
          onPrinterFound!(printer);
        } else {}
        break;
      case 'onDiscoveryFinished':
        if (onDiscoveryFinished != null && call.arguments != null) {
          final List<dynamic> printersList = call.arguments as List<dynamic>;
          final List<DiscoveredPrinter> printers = printersList.map((e) => DiscoveredPrinter.fromMap(e as Map<dynamic, dynamic>)).toList();
          onDiscoveryFinished!(printers);
        } else {}
        break;
      case 'onConnectionStateChanged':
        if (onConnectionStateChanged != null && call.arguments != null) {
          final info = Map<String, dynamic>.from(call.arguments as Map);
          onConnectionStateChanged!(info);
        } else {}
        break;
      default:
        break;
    }
  }

  // ==================== DISCOVERY METHODS ====================

  /// Starts discovering Zebra printers using Zebra Link-OS SDK
  ///
  /// [type] Discovery type: "bluetooth", "network", or "both" (default)
  ///
  /// Returns a list of discovered Zebra printers
  Future<List<DiscoveredPrinter>> startDiscovery({String type = 'both'}) async {
    try {
      print('[PrinterManager] startDiscovery called with type: $type');
      final result = await _channel.invokeMethod('startDiscovery', {'type': type});

      if (result == null) {
        print('[PrinterManager] startDiscovery returned null');
        return [];
      }

      final List<dynamic> printersList = result as List<dynamic>;
      print('[PrinterManager] startDiscovery found ${printersList.length} printers');

      final printers = printersList.map((e) => DiscoveredPrinter.fromMap(e as Map<dynamic, dynamic>)).toList();

      return printers;
    } on PlatformException catch (e) {
      print('[PrinterManager] startDiscovery error: ${e.code} - ${e.message}');
      throw Exception("Discovery Error (${e.code}): ${e.message}");
    } catch (e) {
      print('[PrinterManager] startDiscovery unexpected error: $e');
      rethrow;
    }
  }

  /// Stops the printer discovery process
  Future<bool> stopDiscovery() async {
    try {
      final result = await _channel.invokeMethod('stopDiscovery');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      throw Exception("Stop Discovery Error (${e.code}): ${e.message}");
    }
  }

  // ==================== CONNECTION METHODS ====================

  /// Connects to a Zebra printer and maintains the connection
  ///
  /// [address] Printer address (MAC address for Bluetooth or IP for Network)
  ///
  /// Returns true if connected successfully, false otherwise
  Future<bool> connect(String address) async {
    try {
      print('[PrinterManager] connect called for address: $address');
      final result = await _channel.invokeMethod('connect', {'address': address});
      print('[PrinterManager] connect result: $result');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('[PrinterManager] connect error: ${e.code} - ${e.message}');
      throw Exception("Connection Error (${e.code}): ${e.message}");
    }
  }

  /// Disconnects from a Zebra printer
  ///
  /// [address] Optional printer address. If null, disconnects from currently connected printer
  ///
  /// Returns true if disconnected successfully, false otherwise
  Future<bool> disconnect({String? address}) async {
    try {
      print('[PrinterManager] disconnect called for address: $address');
      final result = await _channel.invokeMethod('disconnect', {'address': address});
      print('[PrinterManager] disconnect result: $result');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('[PrinterManager] disconnect error: ${e.code} - ${e.message}');
      throw Exception("Disconnection Error (${e.code}): ${e.message}");
    }
  }

  /// Checks if printer is currently connected
  ///
  /// [address] Optional printer address to check. If null, checks general connection status
  ///
  /// Returns true if connected, false otherwise
  Future<bool> isConnected({String? address}) async {
    try {
      print('[PrinterManager] isConnected called for address: $address');
      final result = await _channel.invokeMethod('isConnected', {'address': address});
      print('[PrinterManager] isConnected result: $result');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('[PrinterManager] isConnected error: ${e.code} - ${e.message}');
      throw Exception("IsConnected Error (${e.code}): ${e.message}");
    }
  }

  /// Unpairs a Bluetooth device
  /// Uses Android Bluetooth API to remove bonding
  ///
  /// Returns true if successful, throws exception otherwise
  Future<bool> unpairPrinter(String address) async {
    try {
      print('[PrinterManager] unpairPrinter called for: $address');
      final result = await _channel.invokeMethod('unpairPrinter', {'address': address});
      print('[PrinterManager] unpairPrinter successful');
      return result as bool;
    } on PlatformException catch (e) {
      print('[PrinterManager] unpairPrinter error: ${e.code} - ${e.message}');
      throw Exception("Unpair Printer Error (${e.code}): ${e.message}");
    }
  }

  /// Gets paired (bonded) Bluetooth devices
  /// Uses Android Bluetooth API to get bonded devices
  ///
  /// Returns a list of paired Bluetooth devices as BluetoothDevice objects
  Future<List<BluetoothDevice>> getPairedPrinters() async {
    try {
      print('[PrinterManager] getPairedPrinters called');
      final result = await _channel.invokeMethod('getPairedPrinters');

      if (result == null) {
        print('[PrinterManager] getPairedPrinters returned null');
        return [];
      }

      final List<dynamic> devicesList = result as List<dynamic>;
      print('[PrinterManager] getPairedPrinters found ${devicesList.length} printers');

      // Map'i BluetoothDevice'a dönüştür
      final devices =
          devicesList.map((deviceMap) {
            final map = Map<String, dynamic>.from(deviceMap as Map);
            return BluetoothDevice(
              name: map['friendlyName'] as String?,
              address: map['address'] as String,
              type: BluetoothDeviceType.classic, // Paired devices are classic Bluetooth
              bondState: BluetoothBondState.bonded, // All are bonded
              isConnected: false, // Initial state
            );
          }).toList();

      return devices;
    } on PlatformException catch (e) {
      print('[PrinterManager] getPairedPrinters error: ${e.code} - ${e.message}');
      throw Exception("Get Paired Printers Error (${e.code}): ${e.message}");
    }
  }

  // ==================== PRINTING METHODS ====================

  /// Sends ZPL code to the printer
  ///
  /// [macAddress] MAC address of the printer
  /// [zplData] ZPL code
  ///
  /// Returns result message if successful, throws an error if failed
  Future<String> sendZplToPrinter(String macAddress, String zplData) async {
    if (macAddress.isEmpty) {
      throw Exception("MAC address cannot be empty.");
    }
    try {
      // If ZPL code already starts with ^XA and ends with ^XZ, send as is
      final String finalZplToSend;
      if (zplData.trim().startsWith("^XA") && zplData.trim().endsWith("^XZ")) {
        finalZplToSend = zplData;
      } else {
        // Otherwise, wrap the ZPL code between ^XA and ^XZ
        const String initCommands = "^XA";
        finalZplToSend = "$initCommands$zplData^XZ";
      }

      final String result = await _channel.invokeMethod('printLabel', {'address': macAddress, 'data': finalZplToSend});
      return result;
    } on PlatformException catch (e) {
      throw Exception("Print Error (${e.code}): ${e.message}");
    }
  }

  /// Sends CPCL code to the printer
  ///
  /// [macAddress] MAC address of the printer
  /// [cpclData] CPCL code
  /// [charsetName] Character set name (e.g., "UTF-8", "ISO-8859-1")
  ///
  /// Returns result message if successful, throws an error if failed
  Future<String> sendCpclToPrinter(String macAddress, String cpclData, String charsetName) async {
    if (macAddress.isEmpty) {
      throw Exception("MAC address cannot be empty.");
    }
    try {
      final String finalCpclToSend = cpclData;
      final String result = await _channel.invokeMethod('printLabelCpcl', {'address': macAddress, 'data': finalCpclToSend, 'charsetName': charsetName});
      return result;
    } on PlatformException catch (e) {
      throw Exception("Print Error (${e.code}): ${e.message}");
    }
  }

  /// Prints a test label
  ///
  /// [macAddress] MAC address of the printer
  ///
  /// Returns result message if successful, throws an error if failed
  Future<String> printTestLabel(String macAddress) async {
    String testZpl = """^XA
^PON
^PW400
^MMT
^PR0
^LH0,6
^PMN
^FO50,50
^A0N,50,50
^FDZebra Test Print^FS
^FO50,120
^A0N,30,30
^FDDate: ${DateTime.now()}^FS
^FO50,170
^A0N,30,30
^FDTest Successful!^FS
^PQ1,0,1,Y
^XZ""";
    return sendZplToPrinter(macAddress, testZpl);
  }

  /// Gets information about the printer
  ///
  /// [macAddress] MAC address of the printer
  ///
  /// Returns PrinterInfo object with model, serial number, firmware, and language information
  /// Throws an error if failed
  Future<PrinterInfo> getPrinterInfo(String macAddress) async {
    print('📱 getPrinterInfo called with address: $macAddress');
    
    if (macAddress.isEmpty) {
      throw Exception("MAC address cannot be empty");
    }
    
    try {
      print('📱 Invoking native getPrinterInfo method...');
      final String result = await _channel.invokeMethod('getPrinterInfo', {'address': macAddress});
      print('📱 Native method returned: $result');
      
      final printerInfo = PrinterInfo.fromString(result);
      print('📱 PrinterInfo parsed successfully: ${printerInfo.toCompactString()}');
      return printerInfo;
    } on PlatformException catch (e) {
      print('❌ PlatformException in getPrinterInfo:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');
      throw Exception("Printer Info Error (${e.code}): ${e.message}");
    } catch (e) {
      print('❌ Unexpected error in getPrinterInfo: $e');
      throw Exception("Printer Info Error: $e");
    }
  }

  /// Checks the printer status
  ///
  /// [macAddress] MAC address of the printer
  ///
  /// Returns printer status, returns a status with error if failed
  Future<PrinterStatus> checkPrinterStatus(String macAddress) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('checkPrinterStatus', {'address': macAddress});
      return PrinterStatus.fromMap(result);
    } on PlatformException catch (e) {
      return PrinterStatus(isConnected: false, errorMessage: "Printer Status Error (${e.code}): ${e.message}");
    }
  }
}
