# Zebra Printer Package - API Usage Guide

## Table of Contents
1. [Quick Start](#quick-start)
2. [PrinterManager API](#printermanager-api)
3. [Connection Management](#connection-management)
4. [Discovery Features](#discovery-features)
5. [Printing Operations](#printing-operations)
6. [Status & Info](#status--info)
7. [Best Practices](#best-practices)
8. [Common Patterns](#common-patterns)

---

## Quick Start

### Installation
```yaml
dependencies:
  zebra_printer: ^0.2.0
```

### Basic Setup
```dart
import 'package:zebra_printer/zebra_printer.dart';

final printerManager = PrinterManager();
```

---

## PrinterManager API

### Method Summary

| Method | Parameters | Return | Description |
|--------|-----------|--------|-------------|
| `startDiscovery()` | `type: String?` | `Future<List<DiscoveredPrinter>>` | Discover printers |
| `stopDiscovery()` | - | `Future<bool>` | Stop discovery |
| `connect()` | `address: String` | `Future<Map<String, dynamic>>` | Connect to printer |
| `disconnect()` | `address: String?` | `Future<String>` | Disconnect |
| `isConnected()` | `address: String?` | `Future<bool>` | Check connection |
| `sendZplToPrinter()` | `macAddress, zplData` | `Future<String>` | Print ZPL |
| `printTestLabel()` | `macAddress` | `Future<String>` | Print test |
| `checkPrinterStatus()` | `macAddress` | `Future<PrinterStatus>` | Get status |
| `getPrinterInfo()` | `macAddress` | `Future<String>` | Get info |

### Callback Properties

| Callback | Type | Description |
|----------|------|-------------|
| `onPrinterFound` | `void Function(DiscoveredPrinter)?` | Real-time printer found |
| `onDiscoveryFinished` | `void Function(List<DiscoveredPrinter>)?` | Discovery complete |
| `onConnectionStateChanged` | `void Function(Map<String, dynamic>)?` | Connection state |

---

## Connection Management

### Pattern 1: Connect & Disconnect Specific Printer

```dart
// Connect
try {
  final info = await printerManager.connect('AC:3F:A4:XX:XX:XX');
  print('Connected: ${info['friendlyName']}');
} catch (e) {
  print('Error: $e');
}

// Check specific printer
bool connected = await printerManager.isConnected(
  address: 'AC:3F:A4:XX:XX:XX'
);

// Disconnect specific printer
await printerManager.disconnect(
  address: 'AC:3F:A4:XX:XX:XX'
);
```

### Pattern 2: Connect & Auto-Disconnect

```dart
// Connect
await printerManager.connect('AC:3F:A4:XX:XX:XX');

// Check general connection
bool connected = await printerManager.isConnected();

// Disconnect current printer
await printerManager.disconnect();
```

### Pattern 3: Connection State Monitoring

```dart
class _MyWidgetState extends State<MyWidget> {
  String? connectedAddress;
  bool isConnected = false;
  
  @override
  void initState() {
    super.initState();
    
    // Monitor connection changes
    printerManager.onConnectionStateChanged = (info) {
      setState(() {
        isConnected = info['isConnected'] ?? false;
        connectedAddress = info['address'] as String?;
      });
      
      if (isConnected) {
        print('Connected to: ${info['friendlyName']}');
      } else {
        print('Disconnected from: $connectedAddress');
      }
    };
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(isConnected 
          ? 'Connected to $connectedAddress' 
          : 'Not connected'
        ),
        if (isConnected)
          ElevatedButton(
            onPressed: () => printerManager.disconnect(),
            child: Text('Disconnect'),
          ),
      ],
    );
  }
}
```

---

## Discovery Features

### Pattern 1: Bluetooth Only Discovery

```dart
Future<void> discoverBluetoothPrinters() async {
  try {
    final printers = await printerManager.startDiscovery(type: 'bluetooth');
    
    print('Found ${printers.length} Bluetooth printers:');
    for (var p in printers) {
      print('${p.friendlyName} - ${p.address}');
    }
  } catch (e) {
    print('Discovery error: $e');
  }
}
```

### Pattern 2: Network Only Discovery

```dart
Future<void> discoverNetworkPrinters() async {
  try {
    final printers = await printerManager.startDiscovery(type: 'network');
    
    for (var p in printers) {
      print('${p.friendlyName} - IP: ${p.address}');
    }
  } catch (e) {
    print('Discovery error: $e');
  }
}
```

### Pattern 3: Both (Recommended)

```dart
Future<void> discoverAllPrinters() async {
  try {
    // Discovers both Bluetooth and Network printers
    final printers = await printerManager.startDiscovery(type: 'both');
    
    // Separate by type
    final bluetoothPrinters = printers.where((p) => p.type == 'bluetooth');
    final networkPrinters = printers.where((p) => p.type == 'network');
    
    print('Bluetooth: ${bluetoothPrinters.length}');
    print('Network: ${networkPrinters.length}');
  } catch (e) {
    print('Discovery error: $e');
  }
}
```

### Pattern 4: Real-Time Discovery with Callbacks

```dart
class PrinterDiscoveryWidget extends StatefulWidget {
  @override
  _PrinterDiscoveryWidgetState createState() => _PrinterDiscoveryWidgetState();
}

class _PrinterDiscoveryWidgetState extends State<PrinterDiscoveryWidget> {
  final printerManager = PrinterManager();
  List<DiscoveredPrinter> discoveredPrinters = [];
  bool isDiscovering = false;
  
  @override
  void initState() {
    super.initState();
    
    // Real-time callback when printer is found
    printerManager.onPrinterFound = (printer) {
      setState(() {
        if (!discoveredPrinters.any((p) => p.address == printer.address)) {
          discoveredPrinters.add(printer);
        }
      });
      print('Found: ${printer.friendlyName}');
    };
    
    // Callback when discovery completes
    printerManager.onDiscoveryFinished = (printers) {
      setState(() {
        isDiscovering = false;
      });
      print('Discovery complete. Total: ${printers.length}');
    };
  }
  
  Future<void> startDiscovery() async {
    setState(() {
      discoveredPrinters.clear();
      isDiscovering = true;
    });
    
    try {
      await printerManager.startDiscovery(type: 'both');
    } catch (e) {
      setState(() => isDiscovering = false);
      print('Error: $e');
    }
  }
  
  Future<void> stopDiscovery() async {
    await printerManager.stopDiscovery();
    setState(() => isDiscovering = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isDiscovering ? stopDiscovery : startDiscovery,
          child: Text(isDiscovering ? 'Stop Discovery' : 'Start Discovery'),
        ),
        if (isDiscovering) CircularProgressIndicator(),
        Expanded(
          child: ListView.builder(
            itemCount: discoveredPrinters.length,
            itemBuilder: (context, index) {
              final printer = discoveredPrinters[index];
              return ListTile(
                title: Text(printer.friendlyName),
                subtitle: Text('${printer.type} - ${printer.address}'),
                leading: Icon(
                  printer.type == 'bluetooth' 
                    ? Icons.bluetooth 
                    : Icons.wifi,
                ),
                onTap: () => connectToPrinter(printer),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<void> connectToPrinter(DiscoveredPrinter printer) async {
    try {
      await printerManager.connect(printer.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${printer.friendlyName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }
}
```

---

## Printing Operations

### Pattern 1: Simple Text Print

```dart
Future<void> printText(String text) async {
  String zpl = """
^XA
^FO50,50
^A0N,50,50
^FD$text^FS
^XZ
""";

  try {
    await printerManager.sendZplToPrinter('AC:3F:A4:XX:XX:XX', zpl);
    print('Print successful');
  } catch (e) {
    print('Print error: $e');
  }
}
```

### Pattern 2: Multi-Field Label

```dart
Future<void> printShippingLabel({
  required String printerAddress,
  required String name,
  required String address,
  required String city,
  required String zip,
}) async {
  String zpl = """
^XA
^FO50,50^A0N,40,40^FDShipping Label^FS
^FO50,100^GB350,2,2^FS
^FO50,120^A0N,30,30^FD$name^FS
^FO50,160^A0N,25,25^FD$address^FS
^FO50,195^A0N,25,25^FD$city, $zip^FS
^XZ
""";

  await printerManager.sendZplToPrinter(printerAddress, zpl);
}
```

### Pattern 3: Barcode Print

```dart
Future<void> printBarcode(String printerAddress, String barcode) async {
  String zpl = """
^XA
^FO50,50^A0N,30,30^FDProduct Barcode:^FS
^FO50,100^BY3^BCN,100,Y,N,N^FD$barcode^FS
^FO50,220^A0N,25,25^FD$barcode^FS
^XZ
""";

  await printerManager.sendZplToPrinter(printerAddress, zpl);
}
```

### Pattern 4: QR Code Print

```dart
Future<void> printQRCode(String printerAddress, String data) async {
  String zpl = """
^XA
^FO50,50^A0N,30,30^FDScan QR Code:^FS
^FO50,100^BQN,2,10^FDMA,$data^FS
^XZ
""";

  await printerManager.sendZplToPrinter(printerAddress, zpl);
}
```

### Pattern 5: Receipt Print

```dart
class ReceiptPrinter {
  final String printerAddress;
  
  ReceiptPrinter(this.printerAddress);
  
  Future<void> printReceipt({
    required String storeName,
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    StringBuffer zpl = StringBuffer('^XA\n');
    
    // Header
    zpl.write('^FO50,50^A0N,40,40^FD$storeName^FS\n');
    zpl.write('^FO50,100^GB350,2,2^FS\n');
    
    // Items
    int y = 120;
    for (var item in items) {
      String name = item['name'];
      String price = item['price'].toStringAsFixed(2);
      zpl.write('^FO50,$y^A0N,25,25^FD$name^FS\n');
      zpl.write('^FO300,$y^A0N,25,25^FD\$$price^FS\n');
      y += 35;
    }
    
    // Total
    zpl.write('^FO50,$y^GB350,2,2^FS\n');
    y += 20;
    zpl.write('^FO50,$y^A0N,30,30^FDTotal: \$${total.toStringAsFixed(2)}^FS\n');
    
    zpl.write('^XZ');
    
    await PrinterManager().sendZplToPrinter(printerAddress, zpl.toString());
  }
}

// Usage
final receiptPrinter = ReceiptPrinter('AC:3F:A4:XX:XX:XX');
await receiptPrinter.printReceipt(
  storeName: 'My Store',
  items: [
    {'name': 'Item 1', 'price': 10.99},
    {'name': 'Item 2', 'price': 5.50},
    {'name': 'Item 3', 'price': 7.25},
  ],
  total: 23.74,
);
```

---

## Status & Info

### Pattern 1: Check Status Before Print

```dart
Future<void> safePrint(String printerAddress, String zpl) async {
  try {
    // Check status first
    final status = await printerManager.checkPrinterStatus(printerAddress);
    
    if (!status.isConnected) {
      print('Printer not connected');
      return;
    }
    
    if (status.isPaperOut) {
      print('Paper out! Please load paper.');
      return;
    }
    
    if (status.isHeadOpen) {
      print('Printer head is open!');
      return;
    }
    
    if (status.isPaused) {
      print('Printer is paused');
      return;
    }
    
    // All good, proceed with print
    await printerManager.sendZplToPrinter(printerAddress, zpl);
    print('Print successful');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

### Pattern 2: Get Printer Information

```dart
Future<void> displayPrinterInfo(String printerAddress) async {
  try {
    final info = await printerManager.getPrinterInfo(printerAddress);
    print('Printer Information:');
    print(info);
  } catch (e) {
    print('Could not get printer info: $e');
  }
}
```

### Pattern 3: Status Monitoring Widget

```dart
class PrinterStatusWidget extends StatefulWidget {
  final String printerAddress;
  
  PrinterStatusWidget({required this.printerAddress});
  
  @override
  _PrinterStatusWidgetState createState() => _PrinterStatusWidgetState();
}

class _PrinterStatusWidgetState extends State<PrinterStatusWidget> {
  PrinterStatus? status;
  Timer? timer;
  
  @override
  void initState() {
    super.initState();
    checkStatus();
    
    // Auto-refresh status every 5 seconds
    timer = Timer.periodic(Duration(seconds: 5), (_) => checkStatus());
  }
  
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  
  Future<void> checkStatus() async {
    try {
      final s = await PrinterManager().checkPrinterStatus(widget.printerAddress);
      setState(() => status = s);
    } catch (e) {
      print('Status check error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (status == null) return CircularProgressIndicator();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Printer Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _statusRow('Connection', status!.isConnected ? 'Connected' : 'Disconnected', 
                       status!.isConnected ? Colors.green : Colors.red),
            _statusRow('Paper', status!.isPaperOut ? 'Out' : 'OK', 
                       status!.isPaperOut ? Colors.red : Colors.green),
            _statusRow('Head', status!.isHeadOpen ? 'Open' : 'Closed', 
                       status!.isHeadOpen ? Colors.orange : Colors.green),
            _statusRow('State', status!.isPaused ? 'Paused' : 'Running', 
                       status!.isPaused ? Colors.orange : Colors.green),
            if (status!.errorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Error: ${status!.errorMessage}', 
                           style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
```

---

## Best Practices

### 1. Always Handle Errors

```dart
try {
  await printerManager.connect(address);
  await printerManager.sendZplToPrinter(address, zpl);
} on PlatformException catch (e) {
  print('Platform error: ${e.code} - ${e.message}');
} catch (e) {
  print('General error: $e');
}
```

### 2. Check Connection Before Print

```dart
Future<void> print(String address, String zpl) async {
  final connected = await printerManager.isConnected(address: address);
  
  if (!connected) {
    await printerManager.connect(address);
  }
  
  await printerManager.sendZplToPrinter(address, zpl);
}
```

### 3. Use Callbacks for UI Updates

```dart
@override
void initState() {
  super.initState();
  
  printerManager.onPrinterFound = (printer) {
    setState(() {
      // Update UI
    });
  };
  
  printerManager.onConnectionStateChanged = (info) {
    setState(() {
      // Update connection status
    });
  };
}
```

### 4. Clean Up Resources

```dart
@override
void dispose() {
  // Stop any ongoing discovery
  printerManager.stopDiscovery();
  
  // Optionally disconnect
  printerManager.disconnect();
  
  super.dispose();
}
```

### 5. Validate ZPL Before Sending

```dart
String validateZpl(String zpl) {
  // Ensure ZPL starts with ^XA and ends with ^XZ
  String trimmed = zpl.trim();
  
  if (!trimmed.startsWith('^XA')) {
    trimmed = '^XA\n$trimmed';
  }
  
  if (!trimmed.endsWith('^XZ')) {
    trimmed = '$trimmed\n^XZ';
  }
  
  return trimmed;
}
```

---

## Common Patterns

### Complete Workflow: Discover → Connect → Print → Disconnect

```dart
Future<void> completeWorkflow() async {
  try {
    // 1. Discover printers
    print('Discovering printers...');
    final printers = await printerManager.startDiscovery(type: 'both');
    
    if (printers.isEmpty) {
      print('No printers found');
      return;
    }
    
    // 2. Select first printer (or let user choose)
    final printer = printers.first;
    print('Selected: ${printer.friendlyName}');
    
    // 3. Connect
    print('Connecting...');
    await printerManager.connect(printer.address);
    print('Connected!');
    
    // 4. Check status
    final status = await printerManager.checkPrinterStatus(printer.address);
    if (status.isPaperOut) {
      print('Paper out!');
      return;
    }
    
    // 5. Print
    print('Printing...');
    await printerManager.printTestLabel(printer.address);
    print('Print successful!');
    
    // 6. Disconnect
    print('Disconnecting...');
    await printerManager.disconnect(address: printer.address);
    print('Disconnected!');
    
  } catch (e) {
    print('Error: $e');
  }
}
```

### Persistent Connection Pattern

```dart
class PrinterService {
  final PrinterManager _manager = PrinterManager();
  String? _connectedAddress;
  
  Future<void> ensureConnected(String address) async {
    if (_connectedAddress == address) {
      final connected = await _manager.isConnected(address: address);
      if (connected) return; // Already connected
    }
    
    await _manager.connect(address);
    _connectedAddress = address;
  }
  
  Future<void> print(String address, String zpl) async {
    await ensureConnected(address);
    await _manager.sendZplToPrinter(address, zpl);
  }
  
  Future<void> disconnectAll() async {
    await _manager.disconnect();
    _connectedAddress = null;
  }
}
```

---

## Summary

This guide covers all major use cases for the Zebra Printer package. Key takeaways:

1. Use `startDiscovery()` with callbacks for real-time updates
2. Always handle connection state properly
3. Check printer status before printing
4. Validate ZPL commands
5. Handle errors gracefully
6. Clean up resources when done

For more examples, see the [example app](example/lib/main.dart).

