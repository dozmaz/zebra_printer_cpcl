/// Enum for Bluetooth device types
enum BluetoothDeviceType {
  /// Unknown device type (0)
  unknown,

  /// Classic Bluetooth device (1)
  classic,

  /// Bluetooth Low Energy device (2)
  le,

  /// Device supporting both classic and LE (3)
  dual;

  /// Creates BluetoothDeviceType from integer value
  static BluetoothDeviceType fromInt(int? value) {
    switch (value) {
      case 1:
        return BluetoothDeviceType.classic;
      case 2:
        return BluetoothDeviceType.le;
      case 3:
        return BluetoothDeviceType.dual;
      default:
        return BluetoothDeviceType.unknown;
    }
  }

  /// Converts enum value to integer
  int toInt() {
    switch (this) {
      case BluetoothDeviceType.classic:
        return 1;
      case BluetoothDeviceType.le:
        return 2;
      case BluetoothDeviceType.dual:
        return 3;
      case BluetoothDeviceType.unknown:
        return 0;
    }
  }
}

/// Enum for Bluetooth device bond states
enum BluetoothBondState {
  /// Not bonded (10)
  none,

  /// Bonding in progress (11)
  bonding,

  /// Bonded (12)
  bonded;

  /// Creates BluetoothBondState from integer value
  static BluetoothBondState fromInt(int? value) {
    switch (value) {
      case 11:
        return BluetoothBondState.bonding;
      case 12:
        return BluetoothBondState.bonded;
      default:
        return BluetoothBondState.none;
    }
  }

  /// Converts enum value to integer
  int toInt() {
    switch (this) {
      case BluetoothBondState.bonding:
        return 11;
      case BluetoothBondState.bonded:
        return 12;
      case BluetoothBondState.none:
        return 10;
    }
  }
}

class BluetoothDevice {
  /// Device name (can be null)
  final String? name;

  /// Device MAC address
  final String address;

  /// Device type (can be null)
  final BluetoothDeviceType type;

  /// Device bond state
  final BluetoothBondState bondState;

  /// Device connection state
  final bool isConnected;

  /// BluetoothDevice constructor
  BluetoothDevice({required this.address, this.name, BluetoothDeviceType? type, BluetoothBondState? bondState, this.isConnected = false}) : type = type ?? BluetoothDeviceType.unknown, bondState = bondState ?? BluetoothBondState.none;

  /// Creates BluetoothDevice from Map
  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> map) {
    return BluetoothDevice(
      name: map['name'] as String?,
      address: map['address'] as String,
      type: BluetoothDeviceType.fromInt(map['type'] as int?),
      bondState: BluetoothBondState.fromInt(map['bondState'] as int?),
      isConnected: map['isConnected'] as bool? ?? false,
    );
  }

  /// Converts to Map
  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address, 'type': type.toInt(), 'bondState': bondState.toInt(), 'isConnected': isConnected};
  }

  /// Override for equality check
  @override
  bool operator ==(Object other) => identical(this, other) || other is BluetoothDevice && runtimeType == other.runtimeType && address == other.address;

  /// Override for hash code
  @override
  int get hashCode => address.hashCode;

  /// Returns string representation
  @override
  String toString() {
    return 'BluetoothDevice{name: $name, address: $address, type: $type, bondState: $bondState, isConnected: $isConnected}';
  }
}
