# unpairPrinter() Kullanım Kılavuzu

## ✅ Her İki Manager'da da Eklendi!

`unpairPrinter()` metodu hem `PrinterManager` hem de `BluetoothManager` içinde mevcuttur.

---

## 📱 PrinterManager - unpairPrinter()

### Temel Kullanım

```dart
import 'package:zebra_printer/zebra_printer.dart';

final printerManager = PrinterManager();

// Eşleşmeyi kaldır
Future<void> unpairZebraPrinter(String address) async {
  try {
    final success = await printerManager.unpairPrinter(address);
    
    if (success) {
      print('✅ Eşleşme kaldırıldı: $address');
    }
  } catch (e) {
    print('❌ Hata: $e');
  }
}

// Kullanım
await unpairZebraPrinter('AC:3F:A4:40:A7:F3');
```

### Güvenli Unpair (Bağlı Cihazlar İçin)

```dart
Future<bool> safeUnpair(String address) async {
  try {
    // 1. Önce bağlantı durumunu kontrol et
    final isConnected = await printerManager.isConnected(address: address);
    
    if (isConnected) {
      print('Cihaz bağlı, önce bağlantı kesiliyor...');
      await printerManager.disconnect(address: address);
      
      // Bağlantının kesilmesi için kısa bekle
      await Future.delayed(Duration(milliseconds: 500));
    }
    
    // 2. Eşleşmeyi kaldır
    final success = await printerManager.unpairPrinter(address);
    return success;
    
  } catch (e) {
    print('Unpair hatası: $e');
    return false;
  }
}
```

### UI ile Kullanım - Silme Butonu

```dart
class PrinterListItem extends StatelessWidget {
  final BluetoothDevice device;
  final PrinterManager printerManager;

  const PrinterListItem({
    required this.device,
    required this.printerManager,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.print),
      title: Text(device.name ?? 'Unknown'),
      subtitle: Text(device.address),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bağlan butonu
          IconButton(
            icon: Icon(Icons.bluetooth_connected),
            onPressed: () => _connect(context),
          ),
          
          // Unpair butonu
          IconButton(
            icon: Icon(Icons.link_off, color: Colors.red),
            onPressed: () => _unpair(context),
          ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    try {
      await printerManager.connect(device.address);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlandı!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _unpair(BuildContext context) async {
    // Onay dialogu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eşleşme Kaldır'),
        content: Text('${device.name} ile eşleşmeyi kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await printerManager.unpairPrinter(device.address);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Eşleşme kaldırıldı')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }
}
```

### Toplu Unpair - Tüm Yazıcıları Kaldır

```dart
Future<void> unpairAllZebraPrinters() async {
  try {
    // Eşleşmiş tüm yazıcıları al
    final printers = await printerManager.getPairedPrinters();
    
    // Zebra yazıcıları filtrele
    final zebraPrinters = printers.where((device) {
      final name = device.name?.toLowerCase() ?? '';
      return name.contains('zebra') || 
             name.contains('zt') || 
             name.contains('zd');
    }).toList();
    
    print('${zebraPrinters.length} Zebra yazıcı bulundu');
    
    // Hepsini unpair et
    for (var printer in zebraPrinters) {
      try {
        await printerManager.unpairPrinter(printer.address);
        print('✅ ${printer.name} - Unpaired');
      } catch (e) {
        print('❌ ${printer.name} - Hata: $e');
      }
    }
    
    print('Tüm Zebra yazıcılar kaldırıldı!');
  } catch (e) {
    print('Toplu unpair hatası: $e');
  }
}
```

---

## 🔵 BluetoothManager - unpairDevice()

`BluetoothManager` zaten `unpairDevice()` metoduna sahip! Kullanımı PrinterManager ile aynı:

```dart
import 'package:zebra_printer/zebra_printer.dart';

final bluetoothManager = BluetoothManager();

// Eşleşmeyi kaldır
await bluetoothManager.unpairDevice('AC:3F:A4:40:A7:F3');
```

---

## 🆚 PrinterManager vs BluetoothManager - Unpair

| Özellik | PrinterManager | BluetoothManager |
|---------|----------------|------------------|
| **Metod adı** | `unpairPrinter(address)` | `unpairDevice(address)` |
| **Kullanım** | Zebra yazıcılar için | Genel Bluetooth cihazlar için |
| **Otomatik disconnect** | ✅ Evet | ✅ Evet |
| **Return type** | `Future<bool>` | `Future<bool>` |

---

## 🎯 İyi Pratikler

### 1. Önce Disconnect, Sonra Unpair

```dart
Future<bool> properUnpair(String address) async {
  // 1. Bağlantı kontrolü
  if (await printerManager.isConnected(address: address)) {
    await printerManager.disconnect(address: address);
    await Future.delayed(Duration(milliseconds: 500)); // Bekleme
  }
  
  // 2. Unpair
  return await printerManager.unpairPrinter(address);
}
```

### 2. Hata Yönetimi

```dart
Future<void> unpairWithErrorHandling(String address) async {
  try {
    await printerManager.unpairPrinter(address);
    print('✅ Başarılı');
  } on Exception catch (e) {
    if (e.toString().contains('PERMISSION_DENIED')) {
      print('❌ Bluetooth izni gerekli');
    } else if (e.toString().contains('NO_BLUETOOTH')) {
      print('❌ Bluetooth mevcut değil');
    } else {
      print('❌ Bilinmeyen hata: $e');
    }
  }
}
```

### 3. Kullanıcı Onayı

```dart
Future<void> unpairWithConfirmation(BuildContext context, String address) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Eşleşmeyi Kaldır?'),
      content: Text('Bu işlem geri alınamaz.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('İptal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Kaldır'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await printerManager.unpairPrinter(address);
  }
}
```

---

## ⚠️ Önemli Notlar

1. **Bağlı Cihazlar**: Eşleşmeyi kaldırmadan önce bağlantı otomatik olarak kesilir
2. **Android İzinleri**: `BLUETOOTH_ADMIN` izni gereklidir
3. **Geri Alınamaz**: Unpair işlemi geri alınamaz, tekrar eşleşme gerekir
4. **Reflection Kullanımı**: Android API'de `removeBond()` reflection ile çağrılır

---

## 📝 Tam Örnek: Unpair Butonu

```dart
class UnpairButton extends StatefulWidget {
  final String address;
  final String deviceName;

  const UnpairButton({
    required this.address,
    required this.deviceName,
  });

  @override
  _UnpairButtonState createState() => _UnpairButtonState();
}

class _UnpairButtonState extends State<UnpairButton> {
  final PrinterManager _printerManager = PrinterManager();
  bool _isUnpairing = false;

  Future<void> _handleUnpair() async {
    setState(() => _isUnpairing = true);

    try {
      // Onay dialogu
      final confirmed = await _showConfirmDialog();
      if (!confirmed) {
        setState(() => _isUnpairing = false);
        return;
      }

      // Unpair işlemi
      final success = await _printerManager.unpairPrinter(widget.address);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.deviceName} eşleşmesi kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUnpairing = false);
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eşleşmeyi Kaldır'),
        content: Text(
          '${widget.deviceName} ile eşleşmeyi kaldırmak istediğinize emin misiniz?\n\n'
          'Bu işlem geri alınamaz.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Kaldır'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isUnpairing ? null : _handleUnpair,
      icon: _isUnpairing 
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(Icons.link_off),
      label: Text(_isUnpairing ? 'Kaldırılıyor...' : 'Eşleşmeyi Kaldır'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }
}

// Kullanım
UnpairButton(
  address: 'AC:3F:A4:40:A7:F3',
  deviceName: 'ZD421-203dpi ZPL',
)
```

---

## 🎉 Özet

- ✅ `PrinterManager.unpairPrinter(address)` → Zebra yazıcılar için
- ✅ `BluetoothManager.unpairDevice(address)` → Genel cihazlar için
- ✅ Otomatik disconnect
- ✅ `Future<bool>` döner
- ✅ Hata yönetimi
- ✅ Kullanıcı onayı önerilir

Artık eşleşmeyi kaldırabilirsiniz! 🚀


