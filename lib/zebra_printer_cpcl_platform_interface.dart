import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zebra_printer_cpcl_method_channel.dart';

abstract class ZebraPrinterCpclPlatform extends PlatformInterface {
  /// Constructs a ZebraPrinterCpclPlatform.
  ZebraPrinterCpclPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZebraPrinterCpclPlatform _instance = MethodChannelZebraPrinterCpcl();

  /// The default instance of [ZebraPrinterCpclPlatform] to use.
  ///
  /// Defaults to [MethodChannelZebraPrinterCpcl].
  static ZebraPrinterCpclPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZebraPrinterCpclPlatform] when
  /// they register themselves.
  static set instance(ZebraPrinterCpclPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
