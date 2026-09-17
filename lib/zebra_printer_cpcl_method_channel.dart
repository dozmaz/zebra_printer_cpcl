import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zebra_printer_cpcl_platform_interface.dart';

/// An implementation of [ZebraPrinterCpclPlatform] that uses method channels.
class MethodChannelZebraPrinterCpcl extends ZebraPrinterCpclPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('zebra_printer_cpcl');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
