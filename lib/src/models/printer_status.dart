/// Enum for printer connection state
enum PrinterConnectionState {
  /// Printer is connected
  connected,

  /// Printer is disconnected
  disconnected;

  /// Creates PrinterConnectionState from boolean value
  static PrinterConnectionState fromBool(bool isConnected) {
    return isConnected ? PrinterConnectionState.connected : PrinterConnectionState.disconnected;
  }

  /// Converts enum value to boolean
  bool toBool() {
    return this == PrinterConnectionState.connected;
  }
}

/// Enum for paper state
enum PaperState {
  /// Paper is present
  present,

  /// Paper is out
  out;

  /// Creates PaperState from boolean value
  static PaperState fromBool(bool isPaperOut) {
    return isPaperOut ? PaperState.out : PaperState.present;
  }

  /// Converts enum value to boolean
  bool isPaperOut() {
    return this == PaperState.out;
  }
}

/// Enum for printer head state
enum HeadState {
  /// Printer head is closed
  closed,

  /// Printer head is open
  open;

  /// Creates HeadState from boolean value
  static HeadState fromBool(bool isHeadOpen) {
    return isHeadOpen ? HeadState.open : HeadState.closed;
  }

  /// Converts enum value to boolean
  bool isOpen() {
    return this == HeadState.open;
  }
}

/// Enum for printer pause state
enum PauseState {
  /// Printer is running
  running,

  /// Printer is paused
  paused;

  /// Creates PauseState from boolean value
  static PauseState fromBool(bool isPaused) {
    return isPaused ? PauseState.paused : PauseState.running;
  }

  /// Converts enum value to boolean
  bool isPaused() {
    return this == PauseState.paused;
  }
}

class PrinterStatus {
  /// Printer connection state
  final PrinterConnectionState connectionState;

  /// Paper state
  final PaperState paperState;

  /// Printer pause state
  final PauseState pauseState;

  /// Printer head state
  final HeadState headState;

  /// Printer head temperature
  final String temperature;

  /// Error message (if any)
  final String? errorMessage;

  /// PrinterStatus constructor
  PrinterStatus({bool isConnected = false, bool isPaperOut = false, bool isPaused = false, bool isHeadOpen = false, this.temperature = '0', this.errorMessage})
    : connectionState = PrinterConnectionState.fromBool(isConnected),
      paperState = PaperState.fromBool(isPaperOut),
      pauseState = PauseState.fromBool(isPaused),
      headState = HeadState.fromBool(isHeadOpen);

  /// Constructor with direct enum values
  PrinterStatus.withEnums({required this.connectionState, required this.paperState, required this.pauseState, required this.headState, this.temperature = '0', this.errorMessage});

  /// Creates PrinterStatus from Map
  factory PrinterStatus.fromMap(Map<dynamic, dynamic> map) {
    return PrinterStatus(
      isConnected: map['isConnected'] as bool? ?? false,
      isPaperOut: map['isPaperOut'] as bool? ?? false,
      isPaused: map['isPaused'] as bool? ?? false,
      isHeadOpen: map['isHeadOpen'] as bool? ?? false,
      temperature: map['temperature'] as String? ?? '0',
      errorMessage: map['error'] as String?,
    );
  }

  /// Converts to Map
  Map<String, dynamic> toMap() {
    return {'isConnected': connectionState.toBool(), 'isPaperOut': paperState.isPaperOut(), 'isPaused': pauseState.isPaused(), 'isHeadOpen': headState.isOpen(), 'temperature': temperature, 'error': errorMessage};
  }

  /// Getters for backward compatibility
  bool get isConnected => connectionState.toBool();
  bool get isPaperOut => paperState.isPaperOut();
  bool get isPaused => pauseState.isPaused();
  bool get isHeadOpen => headState.isOpen();

  /// Returns string representation
  @override
  String toString() {
    return 'PrinterStatus{connection: $connectionState, paper: $paperState, state: $pauseState, head: $headState, temperature: $temperature, error: $errorMessage}';
  }
}