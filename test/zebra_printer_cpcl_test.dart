import 'package:flutter_test/flutter_test.dart';
import 'package:zebra_printer_cpcl/zebra_printer_cpcl.dart';
import 'package:zebra_printer_cpcl/zebra_printer_cpcl_platform_interface.dart';
import 'package:zebra_printer_cpcl/zebra_printer_cpcl_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockZebraPrinterCpclPlatform
    with MockPlatformInterfaceMixin
    implements ZebraPrinterCpclPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ZebraPrinterCpclPlatform initialPlatform = ZebraPrinterCpclPlatform.instance;

  test('$MethodChannelZebraPrinterCpcl is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZebraPrinterCpcl>());
  });

  test('getPlatformVersion', () async {
    ZebraPrinterCpcl zebraPrinterCpclPlugin = ZebraPrinterCpcl();
    MockZebraPrinterCpclPlatform fakePlatform = MockZebraPrinterCpclPlatform();
    ZebraPrinterCpclPlatform.instance = fakePlatform;

    expect(await zebraPrinterCpclPlugin.getPlatformVersion(), '42');
  });
}
