
import 'zebra_printer_cpcl_platform_interface.dart';

class ZebraPrinterCpcl {
  Future<String?> getPlatformVersion() {
    return ZebraPrinterCpclPlatform.instance.getPlatformVersion();
  }
}
