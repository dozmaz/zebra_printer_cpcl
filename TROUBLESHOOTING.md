# Zebra Printer Discovery Troubleshooting

## ❌ Yazıcı Bulunamıyor Problemi

Eğer **Zebra SDK Discovery** yazıcı bulamıyorsa, aşağıdaki adımları kontrol edin:

---

## ✅ 1. İzinleri Kontrol Edin

### Android Manifest (`android/src/main/AndroidManifest.xml`)

Aşağıdaki izinlerin eklendiğinden emin olun:

```xml
<!-- Bluetooth İzinleri -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Android 12+ için yeni Bluetooth izinleri -->
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" 
    android:usesPermissionFlags="neverForLocation" />

<!-- Konum İzinleri (Bluetooth discovery için ZORUNLU) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Network Discovery için gerekli -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

---

## ✅ 2. Runtime İzinlerini Verin

Uygulamayı çalıştırdığınızda, **Settings > Apps > Zebra Printer Example** altından şu izinleri manuel olarak verin:

- ✅ **Location** (Konum) - **ZORUNLU** Bluetooth discovery için
- ✅ **Nearby Devices** (Yakındaki Cihazlar) - Android 12+ için
- ✅ **Bluetooth** - Bluetooth bağlantısı için

### Komut ile İzin Verme (Test İçin):

```bash
# Location izni
adb shell pm grant com.sameetdmr.zebra_printer_example android.permission.ACCESS_FINE_LOCATION

# Bluetooth Scan izni (Android 12+)
adb shell pm grant com.sameetdmr.zebra_printer_example android.permission.BLUETOOTH_SCAN

# Bluetooth Connect izni (Android 12+)
adb shell pm grant com.sameetdmr.zebra_printer_example android.permission.BLUETOOTH_CONNECT
```

---

## ✅ 3. Cihaz Durumunu Kontrol Edin

### Yazıcı:
- ✅ Yazıcının **gücü açık** mı?
- ✅ Yazıcı **Bluetooth modu** aktif mi?
- ✅ Yazıcı **keşfedilebilir (discoverable)** modda mı?
- ✅ Yazıcı **pairing modunda** mı? (Bazı Zebra modelleri pair olmayı bekler)

### Telefon/Tablet:
- ✅ **Bluetooth** açık mı?
- ✅ **Konum servisleri (GPS)** açık mı? ⚠️ **ZORUNLU** - Bluetooth discovery için
- ✅ Cihaz **Airplane Mode** değil mi?
- ✅ Cihaz yazıcı ile **10 metre içinde** mi?

---

## ✅ 4. Zebra SDK Versiyonunu Kontrol Edin

`android/libs/ZSDK_ANDROID_API.jar` dosyasının doğru versiyonu içerdiğinden emin olun.

**Önerilen Versiyon:** Zebra Link-OS SDK v2.14+

---

## ✅ 5. Logları Kontrol Edin

### Android Logcat:

```bash
adb logcat | grep "PrinterManager\|BluetoothDiscoverer\|NetworkDiscoverer"
```

### Beklenen Log Akışı:

```
D/PrinterManager: discoverPrinters called with type: both
D/PrinterManager: Context: android.app.Application
D/PrinterManager: Starting BOTH Bluetooth and Network discovery
D/PrinterManager: Discovery methods called successfully
D/PrinterManager: foundPrinter called! Printer class: ...
D/PrinterManager: Found BT Printer: XX:XX:XX:XX:XX:XX - Zebra ZD410
```

### Eğer Hata Varsa:

```
E/PrinterManager: Discovery exception: SecurityException: Need ACCESS_FINE_LOCATION permission
```
**Çözüm:** Konum iznini verin

```
E/PrinterManager: Discovery exception: java.lang.NullPointerException
```
**Çözüm:** Context null, plugin initialization'ı kontrol edin

---

## ✅ 6. Build ve Clean

```bash
cd example
flutter clean
flutter pub get
flutter run
```

---

## ✅ 7. Manuel Pair Deneyin

Bazı Zebra yazıcılar önce **pair** olmayı bekler:

1. **Settings** > **Bluetooth** 
2. "**Available Devices**" listesinde Zebra yazıcısını bulun
3. Yazıcıya **tıklayıp pair** edin
4. Ardından uygulamadan **Discovery** yapın

---

## ✅ 8. Test Adımları

### Bluetooth Tab ile Test:
1. **Bluetooth Tab**'a geçin
2. **Scan Devices** butonuna basın
3. Yazıcı **genel Bluetooth listesinde** görünüyor mu?
   - ✅ **Görünüyorsa**: Yazıcı çalışıyor, izinler OK, sorun Zebra SDK'da
   - ❌ **Görünmüyorsa**: Yazıcı sorunu veya Bluetooth/Konum kapalı

### Zebra SDK Tab ile Test:
1. **Zebra SDK Tab**'a geçin
2. **Discover Printers** butonuna basın
3. 10-30 saniye bekleyin (Discovery zaman alabilir)
4. Yazıcı listede görünmeli

---

## ❓ Sık Sorulan Sorular

### Q: Bluetooth Tab'da görünüyor ama Zebra SDK Tab'da görünmüyor?
**A:** 
- Zebra SDK sadece **Zebra markalı yazıcıları** bulur
- Yazıcınız Zebra değilse SDK bulamaz
- Yazıcınız eski bir model ise Link-OS desteği olmayabilir

### Q: Discovery çok uzun sürüyor?
**A:** 
- Bluetooth discovery 10-15 saniye sürebilir
- Network discovery 20-30 saniye sürebilir
- `type: 'bluetooth'` kullanarak sadece BT arayın

### Q: "Permission Denied" hatası alıyorum?
**A:** 
- Android 12+ için `BLUETOOTH_SCAN` ve `ACCESS_FINE_LOCATION` **zorunlu**
- Runtime'da manuel izin verin
- Konum servislerinin **açık** olduğundan emin olun

### Q: Yazıcı bulundu ama bağlanamıyorum?
**A:** 
- Önce **pair** edin (Settings > Bluetooth)
- Yazıcının başka cihaza bağlı olmadığından emin olun
- Yazıcıyı **restart** edin
- Yazıcı modeline göre **PIN** gerekebilir (genelde: 0000 veya 1234)

---

## 📝 Debug Checklist

Sorun çözmek için sırayla kontrol edin:

- [ ] Manifest'te tüm izinler var mı?
- [ ] Runtime'da Location izni verildi mi?
- [ ] Bluetooth açık mı?
- [ ] **Konum servisleri (GPS) açık mı?** ⚠️
- [ ] Yazıcı açık ve Bluetooth modunda mı?
- [ ] Yazıcı 10 metre içinde mi?
- [ ] Yazıcı keşfedilebilir modda mı?
- [ ] Flutter clean yapıldı mı?
- [ ] Loglar kontrol edildi mi?
- [ ] Generic Bluetooth Tab'da görünüyor mu?

---

## 🆘 Hala Çalışmıyorsa

1. **Logları toplayın:**
```bash
adb logcat > zebra_logs.txt
```

2. **Yazıcı modelini not edin:**
   - Model: (örn: ZD410, ZQ520)
   - Firmware: (yazıcı ekranından veya test sayfasından)

3. **Android versiyonunu not edin:**
```bash
adb shell getprop ro.build.version.release
```

4. **Issue açın** GitHub'da loglarla birlikte

---

## 📚 Faydalı Linkler

- [Zebra Link-OS SDK Documentation](https://techdocs.zebra.com/link-os/2-14/android)
- [Android Bluetooth Permissions Guide](https://developer.android.com/guide/topics/connectivity/bluetooth/permissions)
- [Zebra Printer Support](https://www.zebra.com/us/en/support-downloads.html)

