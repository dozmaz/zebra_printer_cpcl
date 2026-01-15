import 'package:flutter/material.dart';
import 'package:zebra_printer_cpcl/zebra_printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Zebra Printer Demo', theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true), home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  final BluetoothManager _bluetoothManager = BluetoothManager();
  final PrinterManager _printerManager = PrinterManager();

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bluetoothManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Zebra Printer Demo'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(icon: Icon(Icons.print), text: 'Zebra SDK'), Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth')]),
      ),
      body: TabBarView(controller: _tabController, children: [ZebraSDKTab(printerManager: _printerManager), BluetoothTab(bluetoothManager: _bluetoothManager, printerManager: _printerManager)]),
    );
  }
}

// ==================== ZEBRA SDK TAB ====================

class ZebraSDKTab extends StatefulWidget {
  final PrinterManager printerManager;

  const ZebraSDKTab({super.key, required this.printerManager});

  @override
  State<ZebraSDKTab> createState() => _ZebraSDKTabState();
}

class _ZebraSDKTabState extends State<ZebraSDKTab> {
  List<DiscoveredPrinter> _printers = [];
  DiscoveredPrinter? _selectedPrinter;
  bool _isDiscovering = false;
  String _status = 'Ready - Zebra Link-OS SDK';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _setupPrinterListeners();
  }

  void _setupPrinterListeners() {
    widget.printerManager.onPrinterFound = (printer) {
      setState(() {
        if (!_printers.any((p) => p.address == printer.address)) {
          _printers.add(printer);
        }
      });
    };

    widget.printerManager.onDiscoveryFinished = (printers) {
      setState(() {
        _isDiscovering = false;
        _status = 'Discovery complete. Found ${printers.length} Zebra printer(s)';
      });
    };

    widget.printerManager.onConnectionStateChanged = (info) {
      setState(() {
        _isConnected = info['isConnected'] ?? false;
        if (_isConnected) {
          _status = 'Connected to ${info['address']} (${info['language']})';
        } else {
          _status = info['error'] ?? 'Disconnected';
        }
      });
    };
  }

  Future<void> _discoverPrinters() async {
    setState(() {
      _status = 'Discovering Zebra printers...';
      _printers = [];
      _isDiscovering = true;
    });

    try {
      final result = await widget.printerManager.startDiscovery(type: 'bluetooth');

      // Eğer sonuç boşsa ve callback'ten de veri gelmediyse
      if (result.isEmpty && _printers.isEmpty) {
        setState(() {
          _status =
              'No Zebra printers found. Make sure:\n'
              '1. Bluetooth is ON\n'
              '2. Printer is powered ON\n'
              '3. Printer is in range\n'
              '4. Location permission is granted';
          _isDiscovering = false;
        });
      }
    } catch (e) {
      setState(() {
        _status =
            'Discovery error: $e\n\n'
            'Check permissions and Bluetooth status';
        _isDiscovering = false;
      });
    }
  }

  Future<void> _getPairedPrinters() async {
    try {
      final paired = await widget.printerManager.getPairedPrinters();
      setState(() {
        _printers = paired.map((device) => DiscoveredPrinter(
          address: device.address,
          friendlyName: device.name ?? device.address,
          type: 'bluetooth',
        )).toList();
        _status = 'Loaded ${paired.length} paired device(s)';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading paired devices: $e';
      });
    }
  }

  Future<void> _unpairPrinter(DiscoveredPrinter printer) async {
    try {
      await widget.printerManager.unpairPrinter(printer.address);
      setState(() {
        _printers.removeWhere((p) => p.address == printer.address);
        if (_selectedPrinter?.address == printer.address) {
          _selectedPrinter = null;
          _isConnected = false;
        }
        _status = 'Unpaired ${printer.friendlyName}';
      });
    } catch (e) {
      setState(() {
        _status = 'Unpair error: $e';
      });
    }
  }

  Future<void> _stopDiscovery() async {
    await widget.printerManager.stopDiscovery();
    setState(() {
      _isDiscovering = false;
      _status = 'Discovery stopped';
    });
  }

  Future<void> _connect(DiscoveredPrinter printer) async {
    setState(() {
      _status = 'Connecting to ${printer.friendlyName}...';
      _selectedPrinter = printer;
    });

    try {
      final connected = await widget.printerManager.connect(printer.address);
      if (connected) {
        setState(() {
          _status = 'Connected to ${printer.friendlyName}';
        });
      } else {
        setState(() {
          _status = 'Connection failed';
          _selectedPrinter = null;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection error: $e';
        _selectedPrinter = null;
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      // Disconnect from currently selected printer
      final disconnected = await widget.printerManager.disconnect(address: _selectedPrinter?.address);
      if (disconnected) {
        setState(() {
          _status = 'Disconnected';
          _selectedPrinter = null;
        });
      } else {
        setState(() {
          _status = 'Disconnect failed';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Disconnect error: $e';
      });
    }
  }

  Future<void> _printTest() async {
    if (_selectedPrinter == null) return;

    setState(() {
      _status = 'Printing test label...';
    });

    try {
      await widget.printerManager.printTestLabel(_selectedPrinter!.address);
      setState(() {
        _status = 'Print successful';
      });
    } catch (e) {
      setState(() {
        _status = 'Print error: $e';
      });
    }
  }

  Future<void> _checkStatus() async {
    if (_selectedPrinter == null) return;

    try {
      PrinterStatus status = await widget.printerManager.checkPrinterStatus(_selectedPrinter!.address);
      setState(() {
        _status =
            'Status: ${status.isConnected ? "Connected" : "Disconnected"}, '
            'Paper: ${status.isPaperOut ? "Out" : "OK"}, '
            'Head: ${status.isHeadOpen ? "Open" : "Closed"}';
      });
    } catch (e) {
      setState(() {
        _status = 'Status check error: $e';
      });
    }
  }

  Future<void> _getPrinterInfo() async {
    if (_selectedPrinter == null) return;

    try {
      PrinterInfo info = await widget.printerManager.getPrinterInfo(_selectedPrinter!.address);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Printer Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Model', info.model),
                const SizedBox(height: 8),
                _buildInfoRow('Serial Number', info.serialNumber),
                const SizedBox(height: 8),
                _buildInfoRow('Firmware', info.firmware),
                const SizedBox(height: 8),
                _buildInfoRow('Language', info.language.toString()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Info error: $e';
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            children: [Text(_status, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8), Text('Using Zebra Link-OS SDK', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(onPressed: _isDiscovering ? _stopDiscovery : _discoverPrinters, icon: Icon(_isDiscovering ? Icons.stop : Icons.search), label: Text(_isDiscovering ? 'Stop' : 'Discover')),
              ElevatedButton.icon(onPressed: _getPairedPrinters, icon: const Icon(Icons.devices), label: const Text('Paired')),
              if (_isConnected) ...[
                ElevatedButton.icon(onPressed: _disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400)),
                ElevatedButton.icon(onPressed: _printTest, icon: const Icon(Icons.print), label: const Text('Print')),
                ElevatedButton.icon(onPressed: _checkStatus, icon: const Icon(Icons.info_outline), label: const Text('Status')),
                ElevatedButton.icon(onPressed: _getPrinterInfo, icon: const Icon(Icons.info), label: const Text('Info')),
              ],
            ],
          ),
        ),

        const Divider(),

        // Printer List
        Expanded(
          child:
              _printers.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No Zebra printers found', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        const Text('Tap "Discover Printers" to search', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _printers.length,
                    itemBuilder: (context, index) {
                      final printer = _printers[index];
                      final isSelected = printer.address == _selectedPrinter?.address;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: printer.type == 'bluetooth' ? Colors.blue : Colors.green, child: Icon(printer.type == 'bluetooth' ? Icons.bluetooth : Icons.wifi, color: Colors.white)),
                          title: Text(printer.friendlyName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text('${printer.type.toUpperCase()} • ${printer.address}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected && _isConnected) const Icon(Icons.check_circle, color: Colors.green),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                color: Colors.red,
                                onPressed: () => _unpairPrinter(printer),
                                tooltip: 'Unpair',
                              ),
                            ],
                          ),
                          onTap: isSelected ? null : () => _connect(printer),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ==================== BLUETOOTH TAB ====================

class BluetoothTab extends StatefulWidget {
  final BluetoothManager bluetoothManager;
  final PrinterManager printerManager;

  const BluetoothTab({super.key, required this.bluetoothManager, required this.printerManager});

  @override
  State<BluetoothTab> createState() => _BluetoothTabState();
}

class _BluetoothTabState extends State<BluetoothTab> {
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;
  String _status = 'Ready - Generic Bluetooth';

  @override
  void initState() {
    super.initState();
    _setupBluetoothListeners();
  }

  void _setupBluetoothListeners() {
    widget.bluetoothManager.onDeviceFound.listen((device) {
      setState(() {
        if (!_devices.any((d) => d.address == device.address)) {
          _devices.add(device);
        }
      });
    });

    widget.bluetoothManager.onScanStateChanged.listen((state) {
      setState(() {
        _isScanning = state == BluetoothScanState.scanning;
      });
    });

    widget.bluetoothManager.onConnectionStateChanged.listen((state) {
      setState(() {
        if (state == BluetoothConnectionState.connected) {
          _status = 'Connected: ${widget.bluetoothManager.connectedDevice?.name}';
        } else if (state == BluetoothConnectionState.disconnected) {
          _status = 'Disconnected';
        } else if (state == BluetoothConnectionState.connecting) {
          _status = 'Connecting...';
        } else if (state == BluetoothConnectionState.error) {
          _status = 'Connection error';
        }
      });
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      _status = 'Scanning all Bluetooth devices...';
      _devices = [];
    });

    try {
      bool isEnabled = await widget.bluetoothManager.isBluetoothEnabled();
      if (!isEnabled) {
        setState(() {
          _status = 'Bluetooth is off';
        });
        return;
      }

      List<BluetoothDevice> bondedDevices = await widget.bluetoothManager.getBondedDevices();
      setState(() {
        _devices = bondedDevices;
      });

      await widget.bluetoothManager.startDiscovery();
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    await widget.bluetoothManager.stopDiscovery();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _status = 'Connecting to ${device.name}...';
      _selectedDevice = device;
    });

    try {
      await widget.bluetoothManager.connect(device.address);
    } catch (e) {
      setState(() {
        _status = 'Connection error: $e';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await widget.bluetoothManager.disconnect();
      setState(() {
        _selectedDevice = null;
      });
    } catch (e) {
      setState(() {
        _status = 'Disconnection error: $e';
      });
    }
  }

  Future<void> _printTest() async {
    if (_selectedDevice == null) return;

    setState(() {
      _status = 'Printing test label...';
    });

    try {
      String result = await widget.printerManager.printTestLabel(_selectedDevice!.address);
      setState(() {
        _status = 'Test label printed: $result';
      });
    } catch (e) {
      setState(() {
        _status = 'Print error: $e';
      });
    }
  }

  Future<void> _checkStatus() async {
    if (_selectedDevice == null) return;

    try {
      PrinterStatus status = await widget.printerManager.checkPrinterStatus(_selectedDevice!.address);
      setState(() {
        _status = 'Printer status: ${status.isConnected ? "Connected" : "Not connected"}';
        if (status.isConnected) {
          _status += ', Paper: ${status.isPaperOut ? "Out" : "Available"}';
          _status += ', Head: ${status.isHeadOpen ? "Open" : "Closed"}';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Status check error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade50,
          child: Column(
            children: [Text(_status, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center), const SizedBox(height: 8), Text('Using Android Bluetooth API', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(onPressed: _isScanning ? _stopScan : _scanDevices, icon: Icon(_isScanning ? Icons.stop : Icons.search), label: Text(_isScanning ? 'Stop Scan' : 'Scan Devices')),
              if (widget.bluetoothManager.isConnected) ...[
                ElevatedButton.icon(onPressed: _disconnect, icon: const Icon(Icons.link_off), label: const Text('Disconnect'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400)),
                ElevatedButton.icon(onPressed: _printTest, icon: const Icon(Icons.print), label: const Text('Print Test')),
                ElevatedButton.icon(onPressed: _checkStatus, icon: const Icon(Icons.info_outline), label: const Text('Check Status')),
              ],
            ],
          ),
        ),

        const Divider(),

        // Device List
        Expanded(
          child:
              _devices.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No Bluetooth devices found', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        const Text('Tap "Scan Devices" to search', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnected = device.address == widget.bluetoothManager.connectedDevice?.address;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        elevation: isConnected ? 4 : 1,
                        color: isConnected ? Colors.amber.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.blue, child: Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth, color: Colors.white)),
                          title: Text(device.name ?? 'Unnamed Device', style: TextStyle(fontWeight: isConnected ? FontWeight.bold : FontWeight.normal)),
                          subtitle: Text(device.address),
                          trailing: isConnected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: isConnected ? null : () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
