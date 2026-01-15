# PrinterManager API Guide

This guide explains how to use the `PrinterManager` class to discover, connect to, and communicate with Zebra printers using the Zebra Link-OS SDK.

## Overview

The `PrinterManager` provides the following capabilities:

1. **Discover** - Find Zebra printers on Bluetooth and Network
2. **Connect** - Establish connection to a Zebra printer
3. **Disconnect** - Close connection to a printer
4. **Print** - Send ZPL data to printer
5. **Get Info** - Retrieve printer information
6. **Check Status** - Get printer status (paper, head, etc.)

## Quick Start

```dart
import 'package:zebra_printer/zebra_printer.dart';

// Create instance (singleton)
final printerManager = PrinterManager();

// Discover Zebra printers
List<DiscoveredPrinter> printers = await printerManager.discoverPrinters();

// Connect to a printer
await printerManager.connect(printers.first.address);

// Print a test label
await printerManager.printTestLabel(printers.first.address);

// Check printer status
PrinterStatus status = await printerManager.checkPrinterStatus(printers.first.address);

// Disconnect
await printerManager.disconnect(printers.first.address);
```

## API Methods

### 1. Discovery Methods

#### `discoverPrinters({String type = 'both'})`

Discovers Zebra printers on the network and via Bluetooth.

**Parameters:**
- `type` (optional): Discovery type
  - `'bluetooth'` - Only Bluetooth printers
  - `'network'` - Only network printers
  - `'both'` - Both Bluetooth and network (default)

**Returns:** `Future<List<DiscoveredPrinter>>`

**Example:**
```dart
// Discover all Zebra printers
List<DiscoveredPrinter> allPrinters = await printerManager.discoverPrinters();

// Discover only Bluetooth printers
List<DiscoveredPrinter> btPrinters = await printerManager.discoverPrinters(type: 'bluetooth');

// Discover only network printers
List<DiscoveredPrinter> netPrinters = await printerManager.discoverPrinters(type: 'network');
```

#### `stopDiscovery()`

Stops the ongoing printer discovery process.

**Returns:** `Future<bool>`

**Example:**
```dart
await printerManager.stopDiscovery();
```

### 2. Discovery Callbacks

Set up callbacks to receive real-time notifications during discovery:

#### `onPrinterFound`

Called each time a printer is discovered.

**Example:**
```dart
printerManager.onPrinterFound = (DiscoveredPrinter printer) {
  print('Found: ${printer.friendlyName}');
  print('Type: ${printer.type}'); // "bluetooth" or "network"
  print('Address: ${printer.address}');
};
```

#### `onDiscoveryFinished`

Called when discovery is complete.

**Example:**
```dart
printerManager.onDiscoveryFinished = (List<DiscoveredPrinter> printers) {
  print('Discovery complete. Found ${printers.length} printer(s)');
};
```

### 3. Connection Methods

#### `connect(String address)`

Connects to a Zebra printer.

**Parameters:**
- `address`: Printer MAC address (for Bluetooth) or IP address (for Network)

**Returns:** `Future<String>` - Success message

**Example:**
```dart
try {
  String result = await printerManager.connect('00:11:22:33:44:55');
  print(result); // "Connection successful: 00:11:22:33:44:55"
} catch (e) {
  print('Connection failed: $e');
}
```

#### `disconnect(String address)`

Disconnects from a printer.

**Parameters:**
- `address`: Printer address

**Returns:** `Future<String>` - Success message

**Example:**
```dart
await printerManager.disconnect('00:11:22:33:44:55');
```

### 4. Printing Methods

#### `sendZplToPrinter(String address, String zplData)`

Sends ZPL code to the printer.

**Parameters:**
- `address`: Printer address
- `zplData`: ZPL code to print

**Returns:** `Future<String>` - Print result message

**Example:**
```dart
String zpl = '^XA^FO50,50^A0N,50,50^FDHello World^FS^XZ';
try {
  String result = await printerManager.sendZplToPrinter('00:11:22:33:44:55', zpl);
  print(result);
} catch (e) {
  print('Print error: $e');
}
```

#### `printTestLabel(String address)`

Prints a test label with current date/time.

**Parameters:**
- `address`: Printer address

**Returns:** `Future<String>` - Print result message

**Example:**
```dart
await printerManager.printTestLabel('00:11:22:33:44:55');
```

### 5. Information Methods

#### `getPrinterInfo(String address)`

Gets detailed printer information.

**Parameters:**
- `address`: Printer address

**Returns:** `Future<String>` - Printer information (model, serial number, firmware, language)

**Example:**
```dart
String info = await printerManager.getPrinterInfo('00:11:22:33:44:55');
print(info);
// Output:
// Model: ZTC ZD410-203dpi ZPL
// Seri No: XXRJ183900347
// Firmware: 76.19.10Z
// Dil: ZPL
```

#### `checkPrinterStatus(String address)`

Checks printer status.

**Parameters:**
- `address`: Printer address

**Returns:** `Future<PrinterStatus>` - Printer status object

**Example:**
```dart
PrinterStatus status = await printerManager.checkPrinterStatus('00:11:22:33:44:55');
print('Connected: ${status.isConnected}');
print('Paper Out: ${status.isPaperOut}');
print('Head Open: ${status.isHeadOpen}');
print('Paused: ${status.isPaused}');
print('Temperature: ${status.temperature}');
```

## Models

### DiscoveredPrinter

Represents a discovered Zebra printer.

**Properties:**
- `type`: `String` - "bluetooth" or "network"
- `address`: `String` - MAC address or IP address
- `friendlyName`: `String` - Printer's friendly name

**Example:**
```dart
DiscoveredPrinter printer = printers.first;
print('Name: ${printer.friendlyName}');
print('Type: ${printer.type}');
print('Address: ${printer.address}');
```

### PrinterStatus

Represents printer status information.

**Properties:**
- `isConnected`: `bool` - Connection status
- `isPaperOut`: `bool` - Paper status (true = out of paper)
- `isHeadOpen`: `bool` - Print head status (true = open)
- `isPaused`: `bool` - Pause status (true = paused)
- `temperature`: `String?` - Print head temperature
- `errorMessage`: `String?` - Error message if any

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:zebra_printer/zebra_printer.dart';

class PrinterPage extends StatefulWidget {
  @override
  _PrinterPageState createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final printerManager = PrinterManager();
  List<DiscoveredPrinter> printers = [];
  DiscoveredPrinter? selectedPrinter;
  String status = 'Ready';

  @override
  void initState() {
    super.initState();
    
    // Set up discovery callbacks
    printerManager.onPrinterFound = (printer) {
      setState(() {
        if (!printers.any((p) => p.address == printer.address)) {
          printers.add(printer);
        }
      });
    };

    printerManager.onDiscoveryFinished = (foundPrinters) {
      setState(() {
        status = 'Found ${foundPrinters.length} printer(s)';
      });
    };
  }

  Future<void> discoverPrinters() async {
    setState(() {
      status = 'Discovering printers...';
      printers = [];
    });

    try {
      await printerManager.discoverPrinters(type: 'both');
    } catch (e) {
      setState(() {
        status = 'Discovery error: $e';
      });
    }
  }

  Future<void> printTest() async {
    if (selectedPrinter == null) return;

    setState(() {
      status = 'Printing...';
    });

    try {
      await printerManager.printTestLabel(selectedPrinter!.address);
      setState(() {
        status = 'Print successful';
      });
    } catch (e) {
      setState(() {
        status = 'Print error: $e';
      });
    }
  }

  Future<void> checkStatus() async {
    if (selectedPrinter == null) return;

    try {
      PrinterStatus printerStatus = 
        await printerManager.checkPrinterStatus(selectedPrinter!.address);
      
      setState(() {
        status = 'Connected: ${printerStatus.isConnected}, '
                'Paper: ${printerStatus.isPaperOut ? "Out" : "OK"}';
      });
    } catch (e) {
      setState(() {
        status = 'Status check error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zebra Printer')),
      body: Column(
        children: [
          Text('Status: $status'),
          ElevatedButton(
            onPressed: discoverPrinters,
            child: Text('Discover Printers'),
          ),
          if (selectedPrinter != null) ...[
            ElevatedButton(
              onPressed: printTest,
              child: Text('Print Test'),
            ),
            ElevatedButton(
              onPressed: checkStatus,
              child: Text('Check Status'),
            ),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return ListTile(
                  title: Text(printer.friendlyName),
                  subtitle: Text('${printer.type} - ${printer.address}'),
                  selected: printer.address == selectedPrinter?.address,
                  onTap: () {
                    setState(() {
                      selectedPrinter = printer;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Error Handling

All methods throw exceptions on error. Always use try-catch blocks:

```dart
try {
  await printerManager.discoverPrinters();
} on Exception catch (e) {
  // Handle error
  print('Error: $e');
}
```

Common error codes:
- `ALREADY_DISCOVERING` - Discovery already in progress
- `DISCOVERY_ERROR` - Error during discovery
- `CONNECTION_FAILED` - Failed to connect to printer
- `PRINT_FAIL` - Failed to print
- `INFO_FAIL` - Failed to get printer info
- `STATUS_FAIL` - Failed to get printer status

## Best Practices

1. **Always stop discovery** when no longer needed to save battery
2. **Handle errors gracefully** - Network/Bluetooth issues are common
3. **Use callbacks** for real-time discovery updates
4. **Test printer status** before printing
5. **Dispose resources** properly when done

## Reference

For more details on the Zebra Link-OS SDK, visit:
https://techdocs.zebra.com/link-os/2-14/android


