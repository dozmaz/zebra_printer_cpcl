# getPairedPrinters() Kullanım Örnekleri

## ✅ Artık `Future<List<BluetoothDevice>>` Döndürüyor!

`getPairedPrinters()` metodu artık `BluetoothDevice` nesneleri döndürüyor, tıpkı `BluetoothManager.getBondedDevices()` gibi.

## 📱 Temel Kullanım

```dart
import 'package:zebra_printer/zebra_printer.dart';

// PrinterManager instance
final printerManager = PrinterManager();

// Eşleşmiş yazıcıları al
Future<void> loadPairedPrinters() async {
  try {
    final List<BluetoothDevice> pairedDevices = await printerManager.getPairedPrinters();
    
    print('${pairedDevices.length} eşleşmiş cihaz bulundu');
    
    for (var device in pairedDevices) {
      print('📱 ${device.name ?? 'Unknown'}');
      print('   Address: ${device.address}');
      print('   Type: ${device.type}');
      print('   Bond State: ${device.bondState}');
      print('   Connected: ${device.isConnected}');
    }
  } catch (e) {
    print('Hata: $e');
  }
}
```

## 🎯 isConnect Benzeri Kullanım

```dart
/// Eşleşmiş yazıcıları kontrol et
Future<List<BluetoothDevice>> getPairedDevices() async {
  try {
    return await printerManager.getPairedPrinters();
  } catch (e) {
    print('getPairedDevices error: $e');
    return [];
  }
}

// Kullanım
final devices = await getPairedDevices();
if (devices.isNotEmpty) {
  print('${devices.length} cihaz bulundu');
}
```

## 🔍 Belirli Adresin Eşleşmiş Olup Olmadığını Kontrol Et

```dart
Future<bool> isPaired(String deviceAddress) async {
  try {
    final devices = await printerManager.getPairedPrinters();
    return devices.any((device) => device.address == deviceAddress);
  } catch (e) {
    return false;
  }
}

// Kullanım
final paired = await isPaired('AC:3F:A4:XX:XX:XX');
if (paired) {
  print('Bu cihaz eşleşmiş');
}
```

## 🖨️ Sadece Zebra Yazıcıları Filtrele

```dart
Future<List<BluetoothDevice>> getZebraPrinters() async {
  try {
    final allDevices = await printerManager.getPairedPrinters();
    
    // Sadece Zebra yazıcıları filtrele
    return allDevices.where((device) {
      final name = device.name?.toLowerCase() ?? '';
      return name.contains('zebra') || 
             name.contains('zt') || 
             name.contains('zd') || 
             name.contains('zq');
    }).toList();
  } catch (e) {
    return [];
  }
}

// Kullanım
final zebraPrinters = await getZebraPrinters();
print('${zebraPrinters.length} Zebra yazıcı bulundu');
```

## 🎨 UI ile Kullanım

```dart
class PrinterListWidget extends StatefulWidget {
  @override
  _PrinterListWidgetState createState() => _PrinterListWidgetState();
}

class _PrinterListWidgetState extends State<PrinterListWidget> {
  final PrinterManager _printerManager = PrinterManager();
  List<BluetoothDevice> _pairedDevices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
  }

  Future<void> _loadPairedDevices() async {
    setState(() => _isLoading = true);
    
    try {
      final devices = await _printerManager.getPairedPrinters();
      setState(() {
        _pairedDevices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _pairedDevices.length,
      itemBuilder: (context, index) {
        final device = _pairedDevices[index];
        return ListTile(
          leading: Icon(Icons.bluetooth_connected, color: Colors.green),
          title: Text(device.name ?? 'Unknown Device'),
          subtitle: Text(
            'Address: ${device.address}\n'
            'Type: ${device.type}\n'
            'Bond: ${device.bondState}'
          ),
          trailing: device.bondState == BluetoothBondState.bonded
              ? Icon(Icons.check_circle, color: Colors.green)
              : null,
          onTap: () => _connectToDevice(device),
        );
      },
    );
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final success = await _printerManager.connect(device.address);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.name} bağlandı!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası: $e')),
      );
    }
  }
}
```

## 🔄 Karşılaştırma: Önceki vs Şimdi

### Önceki (Map<String, dynamic>)
```dart
final List<Map<String, dynamic>> devices = await printerManager.getPairedPrinters();
final name = devices[0]['friendlyName'] as String?;
final address = devices[0]['address'] as String;
```

### Şimdi (BluetoothDevice)
```dart
final List<BluetoothDevice> devices = await printerManager.getPairedPrinters();
final name = devices[0].name;
final address = devices[0].address;
final bondState = devices[0].bondState; // ✅ Yeni!
final type = devices[0].type; // ✅ Yeni!
```

## ⚡ Hızlı Erişim

```dart
// İlk Zebra yazıcıya bağlan
Future<bool> connectToFirstZebra() async {
  final zebras = await printerManager.getPairedPrinters();
  final zebra = zebras.firstWhere(
    (d) => d.name?.toLowerCase().contains('zebra') ?? false,
    orElse: () => throw Exception('Zebra yazıcı bulunamadı'),
  );
  
  return await printerManager.connect(zebra.address);
}
```

## 📊 Özet

| Özellik | Değer |
|---------|-------|
| **Dönüş Tipi** | `Future<List<BluetoothDevice>>` ✅ |
| **Model** | `BluetoothDevice` (standart model) |
| **Bond State** | `BluetoothBondState.bonded` (hepsi eşleşmiş) |
| **Type** | `BluetoothDeviceType.classic` |
| **isConnected** | `false` (initial state) |

Artık `getPairedPrinters()` ve `getBondedDevices()` aynı tip döndürüyor! 🎉


