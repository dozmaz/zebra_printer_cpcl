# getPrinterInfo() Debug Test Rehberi

## 🔍 Eklenen Debug Log'ları

### Dart Tarafı (Flutter)
```
📱 getPrinterInfo called with address: XX:XX:XX:XX:XX:XX
📱 Invoking native getPrinterInfo method...
📱 Native method returned: Model: ZD421...
📱 PrinterInfo parsed successfully: ZD421 (S/N: XXX) - V84.20.11Z - ZPL
```

### Android Tarafı (Native)
```
D/PrinterManager: getPrinterInfo called
D/PrinterManager: Getting printer info for: XX:XX:XX:XX:XX:XX
D/PrinterManager: getPrinterInfo method started for: XX:XX:XX:XX:XX:XX
D/PrinterManager: Creating Bluetooth connection...
D/PrinterManager: Opening connection...
D/PrinterManager: Connection opened successfully
D/PrinterManager: Creating ZebraPrinter instance...
D/PrinterManager: Getting printer information via SGD commands...
D/PrinterManager: Model: ZD421
D/PrinterManager: Serial: XXXXXXXXXXXX
D/PrinterManager: Firmware: V84.20.11Z
D/PrinterManager: Getting printer control language...
D/PrinterManager: Language: ZPL
D/PrinterManager: Printer info collected successfully: Model: ZD421...
D/PrinterManager: Printer info retrieved successfully: Model: ZD421...
```

## 📋 Test Adımları

### 1. APK'yı Cihaza Yükle
```bash
cd /Users/sameddemir/Desktop/Markets/zebraLinkOs/zebra_printer_package/example
flutter install
```

### 2. Logcat'i Başlat (Ayrı Terminal)
```bash
adb logcat | grep -E "PrinterManager|flutter"
```

### 3. Uygulamayı Çalıştır ve Test Et

1. **Zebra SDK Tab**'ine git
2. **Discover** butonuna tıkla ve yazıcıyı bul
3. Yazıcıyı seç (liste öğesine tıkla)
4. **Connect** butonuna tıkla
5. **Info** butonuna tıkla ⬅️ **BU ADIM**
6. Log'ları izle

## 🐛 Olası Hatalar ve Çözümleri

### Hata 1: "INVALID_ADDRESS"
**Sebep:** MAC address null veya boş
**Çözüm:** Önce yazıcıyı seçtiğinizden emin olun

```dart
// Example app'te kontrol:
if (_selectedPrinter == null) {
  print('❌ Yazıcı seçilmedi!');
  return;
}
```

### Hata 2: "INFO_FAIL: Could not connect to device"
**Sebep:** Bluetooth bağlantısı kurulamadı
**Çözüm:** 
1. Yazıcının açık ve menzilde olduğundan emin olun
2. Önce **Connect** butonuna tıklayın
3. Sonra **Info** butonuna tıklayın

### Hata 3: "Connection timeout"
**Sebep:** Bluetooth soketi hazır değil
**Çözüm:** 800ms stabilizasyon süresi eklendi (otomatik)

### Hata 4: Method çağrılmıyor (hiç log yok)
**Sebep:** Method channel mapping hatası
**Kontrol:** 
```dart
// printer_manager.dart içinde:
final String result = await _channel.invokeMethod('getPrinterInfo', {'address': macAddress});
                                                    ^^^^^^^^^^^^^^^^  // Method adı
```

## 🧪 Manual Test Kodu

Example app'te test etmek için:

```dart
Future<void> _testGetPrinterInfo() async {
  print('🧪 Starting getPrinterInfo test...');
  
  if (_selectedPrinter == null) {
    print('❌ No printer selected');
    setState(() => _status = 'Please select a printer first');
    return;
  }
  
  setState(() => _status = 'Getting printer info...');
  
  try {
    print('🧪 Calling getPrinterInfo with address: ${_selectedPrinter!.address}');
    
    PrinterInfo info = await widget.printerManager.getPrinterInfo(_selectedPrinter!.address);
    
    print('✅ Success! Printer Info:');
    print('   Model: ${info.model}');
    print('   Serial: ${info.serialNumber}');
    print('   Firmware: ${info.firmware}');
    print('   Language: ${info.language}');
    
    setState(() => _status = 'Info retrieved: ${info.model}');
    
    // Show dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Printer Info'),
          content: Text(info.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    
  } catch (e) {
    print('❌ Error: $e');
    setState(() => _status = 'Info error: $e');
  }
}
```

## 📊 Beklenen Sonuç

### Başarılı Durum
```
📱 getPrinterInfo called with address: AC:3F:A4:40:A7:F3
D/PrinterManager: getPrinterInfo called
D/PrinterManager: Getting printer info for: AC:3F:A4:40:A7:F3
D/PrinterManager: getPrinterInfo method started for: AC:3F:A4:40:A7:F3
D/PrinterManager: Creating Bluetooth connection...
D/PrinterManager: Opening connection...
D/PrinterManager: Connection opened successfully
D/PrinterManager: Creating ZebraPrinter instance...
D/PrinterManager: Getting printer information via SGD commands...
D/PrinterManager: Model: ZD421
D/PrinterManager: Serial: 12345678
D/PrinterManager: Firmware: V84.20.11Z
D/PrinterManager: Language: ZPL
D/PrinterManager: Printer info collected successfully
📱 Native method returned: Model: ZD421
Seri No: 12345678
Firmware: V84.20.11Z
Dil: ZPL

📱 PrinterInfo parsed successfully: ZD421 (S/N: 12345678) - V84.20.11Z - ZPL

✅ Dialog açıldı ve bilgiler gösterildi
```

## 🔧 Eğer Hala Çalışmıyorsa

1. **Full Clean Build:**
```bash
cd example
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk --debug
flutter install
```

2. **Log Filtreleme:**
```bash
# Sadece PrinterManager log'ları
adb logcat PrinterManager:D *:S

# Sadece Flutter log'ları
adb logcat flutter:V *:S

# Her ikisi de
adb logcat | grep -E "(PrinterManager|flutter|getPrinterInfo)"
```

3. **Permissions Kontrolü:**
```bash
adb shell dumpsys package com.sameetdmr.zebra_printer_example | grep permission
```

## 📝 Hangi Bilgileri Paylaşmalıyım?

Eğer hala çalışmıyorsa, şunları paylaşın:

1. ✅ Flutter console çıktısı (📱 emoji'li log'lar)
2. ✅ Android logcat çıktısı (D/PrinterManager log'ları)
3. ✅ Hata mesajı (eğer varsa)
4. ✅ Yazıcı model ve MAC adresi
5. ✅ Hangi adımda durdu? (connect, discover, info?)

---

## 🎯 Son Yapılan İyileştirmeler

### v0.2.2+debug
- ✅ Detaylı log'lama eklendi (Dart + Android)
- ✅ Null kontrolü eklendi
- ✅ 800ms bağlantı stabilizasyonu eklendi
- ✅ Exception handling geliştirildi
- ✅ Hata mesajları netleştirildi

Şimdi her adımda ne olduğunu görebilirsiniz! 🚀

