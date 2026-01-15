/// Enum for printer language
enum PrinterLanguage {
  /// ZPL (Zebra Programming Language)
  zpl,
  
  /// CPCL (Common Printer Command Language)
  cpcl,
  
  /// Unknown language
  unknown;
  
  /// Creates PrinterLanguage from string
  static PrinterLanguage fromString(String? language) {
    if (language == null) return PrinterLanguage.unknown;
    
    final lower = language.toLowerCase();
    if (lower.contains('zpl')) return PrinterLanguage.zpl;
    if (lower.contains('cpcl')) return PrinterLanguage.cpcl;
    return PrinterLanguage.unknown;
  }
  
  @override
  String toString() {
    switch (this) {
      case PrinterLanguage.zpl:
        return 'ZPL';
      case PrinterLanguage.cpcl:
        return 'CPCL';
      case PrinterLanguage.unknown:
        return 'Unknown';
    }
  }
}

/// Printer information model
class PrinterInfo {
  /// Printer model name
  final String model;
  
  /// Printer serial number
  final String serialNumber;
  
  /// Printer firmware version
  final String firmware;
  
  /// Printer language (ZPL/CPCL)
  final PrinterLanguage language;
  
  /// Raw info string (for debugging)
  final String? rawInfo;
  
  PrinterInfo({
    required this.model,
    required this.serialNumber,
    required this.firmware,
    required this.language,
    this.rawInfo,
  });
  
  /// Creates PrinterInfo from raw string response
  /// Parses the string format returned from Android:
  /// "Model: ZD421\nSeri No: XXXX\nFirmware: V84.20.11Z\nDil: ZPL\n"
  factory PrinterInfo.fromString(String info) {
    final lines = info.split('\n');
    
    String model = 'Unknown';
    String serialNumber = 'Unknown';
    String firmware = 'Unknown';
    String languageStr = 'Unknown';
    
    for (var line in lines) {
      if (line.contains('Model:')) {
        model = line.split(':').last.trim();
      } else if (line.contains('Seri No:')) {
        serialNumber = line.split(':').last.trim();
      } else if (line.contains('Firmware:')) {
        firmware = line.split(':').last.trim();
      } else if (line.contains('Dil:')) {
        languageStr = line.split(':').last.trim();
      }
    }
    
    return PrinterInfo(
      model: model,
      serialNumber: serialNumber,
      firmware: firmware,
      language: PrinterLanguage.fromString(languageStr),
      rawInfo: info,
    );
  }
  
  /// Creates PrinterInfo from Map (for future use if Android returns Map)
  factory PrinterInfo.fromMap(Map<dynamic, dynamic> map) {
    return PrinterInfo(
      model: map['model'] as String? ?? 'Unknown',
      serialNumber: map['serialNumber'] as String? ?? 'Unknown',
      firmware: map['firmware'] as String? ?? 'Unknown',
      language: PrinterLanguage.fromString(map['language'] as String?),
      rawInfo: map['rawInfo'] as String?,
    );
  }
  
  /// Converts to Map
  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'serialNumber': serialNumber,
      'firmware': firmware,
      'language': language.toString(),
      'rawInfo': rawInfo,
    };
  }
  
  /// Returns string representation
  @override
  String toString() {
    return 'PrinterInfo{\n'
        '  Model: $model\n'
        '  Serial Number: $serialNumber\n'
        '  Firmware: $firmware\n'
        '  Language: ${language.toString()}\n'
        '}';
  }
  
  /// Returns compact string representation
  String toCompactString() {
    return '$model (S/N: $serialNumber) - $firmware - ${language.toString()}';
  }
  
  /// Returns JSON-like Map for debugging
  Map<String, String> toJson() {
    return {
      'model': model,
      'serialNumber': serialNumber,
      'firmware': firmware,
      'language': language.toString(),
    };
  }
}

