import 'dart:async';

import 'package:flutter/services.dart';
import '../models/bluetooth_device.dart';

/// Enum for Bluetooth connection state
enum BluetoothConnectionState {
  /// No connection
  disconnected,

  /// Connecting
  connecting,

  /// Connection established
  connected,

  /// Disconnecting
  disconnecting,

  /// Connection error
  error,
}

/// Enum for Bluetooth scan state
enum BluetoothScanState {
  /// No scanning
  idle,

  /// Scan starting
  starting,

  /// Scanning in progress
  scanning,

  /// Scan stopping
  stopping,
}

/// Class for managing Bluetooth operations
class BluetoothManager {
  /// Singleton instance
  static final BluetoothManager _instance = BluetoothManager._internal();

  /// Factory constructor
  factory BluetoothManager() => _instance;

  /// Private constructor
  BluetoothManager._internal() {
    _init();
  }

  /// Method channel
  static const MethodChannel _channel = MethodChannel('com.sameetdmr.zebra_printer/bluetooth');

  /// Stream controller triggered when discovery finishes
  final StreamController<void> _discoveryFinishedController = StreamController.broadcast();

  /// Stream controller triggered when device is found
  final StreamController<BluetoothDevice> _deviceFoundController = StreamController.broadcast();

  /// Stream controller triggered when connection state changes
  final StreamController<BluetoothConnectionState> _connectionStateController = StreamController.broadcast();

  /// Stream controller triggered when scan state changes
  final StreamController<BluetoothScanState> _scanStateController = StreamController.broadcast();

  /// Scan state
  BluetoothScanState _scanState = BluetoothScanState.idle;

  /// Connection state
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;

  /// Connected device
  BluetoothDevice? _connectedDevice;

  /// List of found devices
  final List<BluetoothDevice> _devices = [];

  /// List of bonded devices
  final List<BluetoothDevice> _bondedDevices = [];

  /// Returns the scan state
  BluetoothScanState get scanState => _scanState;

  /// Returns the connection state
  BluetoothConnectionState get connectionState => _connectionState;

  /// Returns the connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Is scanning in progress?
  bool get isScanning => _scanState == BluetoothScanState.scanning || _scanState == BluetoothScanState.starting;

  /// Is connection established?
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;

  /// Returns the list of found devices (unmodifiable list)
  List<BluetoothDevice> get devices => List.unmodifiable(_devices);

  /// Returns the list of bonded devices (unmodifiable list)
  List<BluetoothDevice> get bondedDevices => List.unmodifiable(_bondedDevices);

  /// Stream triggered when device is found
  Stream<BluetoothDevice> get onDeviceFound => _deviceFoundController.stream;

  /// Stream triggered when discovery finishes
  Stream<void> get onDiscoveryFinished => _discoveryFinishedController.stream;

  /// Stream triggered when connection state changes
  Stream<BluetoothConnectionState> get onConnectionStateChanged => _connectionStateController.stream;

  /// Stream triggered when scan state changes
  Stream<BluetoothScanState> get onScanStateChanged => _scanStateController.stream;

  /// Sets up the method channel handler
  void _init() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handles calls from the method channel
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeviceFound':
        final deviceMap = call.arguments as Map<dynamic, dynamic>;
        final device = BluetoothDevice.fromMap(deviceMap);
        if (!_devices.contains(device)) {
          _devices.add(device);
          _deviceFoundController.add(device);
        }
        break;

      case 'onDiscoveryFinished':
        _updateScanState(BluetoothScanState.idle);
        _discoveryFinishedController.add(null);
        break;

      case 'onConnectionStateChanged':
        final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
        final int state = args['state'] as int;
        final String? address = args['address'] as String?;

        switch (state) {
          case 0: // Disconnected
            _updateConnectionState(BluetoothConnectionState.disconnected);
            _connectedDevice = null;
            break;
          case 1: // Connecting
            _updateConnectionState(BluetoothConnectionState.connecting);
            break;
          case 2: // Connected
            _updateConnectionState(BluetoothConnectionState.connected);
            if (address != null) {
              _connectedDevice = _findDeviceByAddress(address);
            }
            break;
          case 3: // Disconnecting
            _updateConnectionState(BluetoothConnectionState.disconnecting);
            break;
          case 4: // Error
            _updateConnectionState(BluetoothConnectionState.error);
            _connectedDevice = null;
            break;
        }
        break;

      default:
        throw PlatformException(code: 'Unimplemented', message: 'Method ${call.method} not implemented');
    }
    return null;
  }

  /// Updates the scan state and notifies the stream
  void _updateScanState(BluetoothScanState newState) {
    if (_scanState != newState) {
      _scanState = newState;
      _scanStateController.add(newState);
    }
  }

  /// Updates the connection state and notifies the stream
  void _updateConnectionState(BluetoothConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
    }
  }

  /// Finds a device by MAC address
  BluetoothDevice? _findDeviceByAddress(String address) {
    for (final device in _devices) {
      if (device.address == address) {
        return device;
      }
    }

    for (final device in _bondedDevices) {
      if (device.address == address) {
        return device;
      }
    }

    return null;
  }

  /// Checks if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod('isBluetoothEnabled');
  }

  /// Gets and updates the bonded devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    final List<dynamic> result = await _channel.invokeMethod('getBondedDevices');
    final devices = result.map((deviceMap) => BluetoothDevice.fromMap(deviceMap)).toList();

    // Update the bonded devices list
    _bondedDevices.clear();
    _bondedDevices.addAll(devices);

    return devices;
  }

  /// Starts device discovery
  Future<bool> startDiscovery() async {
    if (isScanning) {
      return false;
    }

    _updateScanState(BluetoothScanState.starting);

    try {
      // First get bonded devices
      final bondedDevices = await getBondedDevices();

      // Clear the found devices list and add bonded devices
      _devices.clear();
      _devices.addAll(bondedDevices);

      // Start discovery
      final result = await _channel.invokeMethod('startDiscovery');

      if (result == true) {
        _updateScanState(BluetoothScanState.scanning);
        return true;
      } else {
        _updateScanState(BluetoothScanState.idle);
        return false;
      }
    } catch (e) {
      _updateScanState(BluetoothScanState.idle);
      return false;
    }
  }

  /// Stops device discovery
  Future<bool> stopDiscovery() async {
    if (!isScanning) {
      return false;
    }

    _updateScanState(BluetoothScanState.stopping);

    try {
      final result = await _channel.invokeMethod('stopDiscovery');
      _updateScanState(BluetoothScanState.idle);
      return result;
    } catch (e) {
      _updateScanState(BluetoothScanState.idle);
      return false;
    }
  }

  /// Pairs with a device
  Future<bool> pairDevice(String address) async {
    try {
      return await _channel.invokeMethod('pairDevice', {'address': address});
    } catch (e) {
      return false;
    }
  }

  /// Unpairs from a device
  Future<bool> unpairDevice(String address) async {
    try {
      // If this is the connected device, disconnect first
      if (_connectedDevice?.address == address) {
        await disconnect();
      }

      return await _channel.invokeMethod('unpairDevice', {'address': address});
    } catch (e) {
      return false;
    }
  }

  /// Connects to a device
  Future<bool> connect(String address) async {
    if (_connectionState == BluetoothConnectionState.connected || _connectionState == BluetoothConnectionState.connecting) {
      return false;
    }

    _updateConnectionState(BluetoothConnectionState.connecting);

    try {
      return await _channel.invokeMethod('connect', {'address': address});
    } catch (e) {
      _updateConnectionState(BluetoothConnectionState.error);
      return false;
    }
  }

  /// Disconnects from a device
  Future<bool> disconnect() async {
    if (_connectionState != BluetoothConnectionState.connected) {
      return false;
    }

    _updateConnectionState(BluetoothConnectionState.disconnecting);

    try {
      return await _channel.invokeMethod('disconnect');
    } catch (e) {
      _updateConnectionState(BluetoothConnectionState.error);
      return false;
    }
  }

  /// Closes the stream controllers
  void dispose() {
    // Stop active scanning if any
    if (isScanning) {
      stopDiscovery();
    }

    // Disconnect active connection if any
    if (isConnected) {
      disconnect();
    }

    // Close stream controllers
    _discoveryFinishedController.close();
    _deviceFoundController.close();
    _connectionStateController.close();
    _scanStateController.close();
  }
}