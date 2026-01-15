package com.sameetdmr.zebra_printer;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * Bluetooth işlemlerini yöneten sınıf
 */
public class BluetoothManager {
    private static final String TAG = "BluetoothManager";
    
    // SPP UUID (Serial Port Profile)
    private static final UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

    // Bağlantı durumları
    private static final int CONNECTION_STATE_DISCONNECTED = 0;
    private static final int CONNECTION_STATE_CONNECTING = 1;
    private static final int CONNECTION_STATE_CONNECTED = 2;
    private static final int CONNECTION_STATE_DISCONNECTING = 3;
    private static final int CONNECTION_STATE_ERROR = 4;

    private final Context context;
    private final BluetoothAdapter bluetoothAdapter;
    private final Handler mainHandler;
    private final ExecutorService executorService;
    private BroadcastReceiver discoveryReceiver;
    private BroadcastReceiver connectionReceiver;
    private boolean isDiscovering = false;
    private MethodChannel methodChannel;
    
    // Bağlantı değişkenleri
    private BluetoothSocket bluetoothSocket;
    private BluetoothDevice connectedDevice;
    private int connectionState = CONNECTION_STATE_DISCONNECTED;

    /**
     * Constructor
     * @param context Uygulama context'i
     */
    public BluetoothManager(Context context) {
        this.context = context;
        this.bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        this.mainHandler = new Handler(Looper.getMainLooper());
        this.executorService = Executors.newSingleThreadExecutor();
        
        // Bağlantı durumu değişikliklerini dinleyen receiver'ı kaydet
        registerConnectionReceiver();
    }

    /**
     * MethodChannel işleyicisini ayarlar
     * @param methodChannel Flutter tarafından gelen MethodChannel
     */
    public void setMethodCallHandler(MethodChannel methodChannel) {
        this.methodChannel = methodChannel;
        methodChannel.setMethodCallHandler(this::handleMethodCall);
    }

    /**
     * Flutter tarafından gelen method çağrılarını işler
     * @param call Method çağrısı
     * @param result Sonuç callback'i
     */
    private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "isBluetoothEnabled":
                result.success(isBluetoothEnabled());
                break;
            case "getBondedDevices":
                result.success(getBondedDevices());
                break;
            case "startDiscovery":
                startDiscovery(result);
                break;
            case "stopDiscovery":
                stopDiscovery(result);
                break;
            case "pairDevice":
                String address = call.argument("address");
                pairDevice(address, result);
                break;
            case "unpairDevice":
                String unpairAddress = call.argument("address");
                unpairDevice(unpairAddress, result);
                break;
            case "connect":
                String connectAddress = call.argument("address");
                connect(connectAddress, result);
                break;
            case "disconnect":
                disconnect(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    /**
     * Bluetooth'un açık olup olmadığını kontrol eder
     * @return Bluetooth açıksa true, değilse false
     */
    private boolean isBluetoothEnabled() {
        return bluetoothAdapter != null && bluetoothAdapter.isEnabled();
    }

    /**
     * Eşleştirilmiş cihazları döndürür
     * @return Eşleştirilmiş cihazların listesi
     */
    private List<Map<String, Object>> getBondedDevices() {
        List<Map<String, Object>> devicesList = new ArrayList<>();

        if (bluetoothAdapter == null) {
            return devicesList;
        }

        Set<BluetoothDevice> pairedDevices = bluetoothAdapter.getBondedDevices();
        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                Map<String, Object> deviceMap = new HashMap<>();
                deviceMap.put("name", device.getName());
                deviceMap.put("address", device.getAddress());
                deviceMap.put("type", device.getType());
                deviceMap.put("bondState", device.getBondState());
                
                // Bağlı cihaz ise isConnected true olsun
                boolean isConnected = connectedDevice != null && 
                                     device.getAddress().equals(connectedDevice.getAddress()) &&
                                     connectionState == CONNECTION_STATE_CONNECTED;
                deviceMap.put("isConnected", isConnected);
                
                devicesList.add(deviceMap);
            }
        }

        return devicesList;
    }

    /**
     * Cihaz keşfini başlatır
     * @param result Sonuç callback'i
     */
    private void startDiscovery(final MethodChannel.Result result) {
        if (isDiscovering) {
            stopDiscovery(null);
        }

        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth adapter bulunamadı", null);
            return;
        }

        // Keşif tamamlandığında ve yeni cihaz bulunduğunda tetiklenecek BroadcastReceiver
        discoveryReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    if (device != null) {
                        Map<String, Object> deviceMap = new HashMap<>();
                        deviceMap.put("name", device.getName());
                        deviceMap.put("address", device.getAddress());
                        deviceMap.put("type", device.getType());
                        deviceMap.put("bondState", device.getBondState());
                        
                        // Bağlı cihaz ise isConnected true olsun
                        boolean isConnected = connectedDevice != null && 
                                             device.getAddress().equals(connectedDevice.getAddress()) &&
                                             connectionState == CONNECTION_STATE_CONNECTED;
                        deviceMap.put("isConnected", isConnected);

                        // Flutter'a cihaz bulundu bildirimi gönder
                        mainHandler.post(() -> {
                            if (methodChannel != null) {
                                methodChannel.invokeMethod("onDeviceFound", deviceMap);
                            }
                        });
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                    isDiscovering = false;
                    
                    // Flutter'a keşfin tamamlandığını bildir
                    mainHandler.post(() -> {
                        if (methodChannel != null) {
                            methodChannel.invokeMethod("onDiscoveryFinished", null);
                        }
                    });
                    
                    // BroadcastReceiver'ı kaldır
                    try {
                        context.unregisterReceiver(this);
                    } catch (Exception e) {
                        Log.e(TAG, "Receiver unregister error: " + e.getMessage());
                    }
                }
            }
        };

        // Intent filtreleri
        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        
        // BroadcastReceiver'ı kaydet
        context.registerReceiver(discoveryReceiver, filter);

        // Keşfi başlat
        if (bluetoothAdapter.startDiscovery()) {
            isDiscovering = true;
            result.success(true);
        } else {
            result.error("DISCOVERY_FAILED", "Cihaz keşfi başlatılamadı", null);
        }
    }

    /**
     * Cihaz keşfini durdurur
     * @param result Sonuç callback'i (null olabilir)
     */
    private void stopDiscovery(final MethodChannel.Result result) {
        if (bluetoothAdapter != null && bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }

        isDiscovering = false;

        // BroadcastReceiver'ı kaldır
        if (discoveryReceiver != null) {
            try {
                context.unregisterReceiver(discoveryReceiver);
                discoveryReceiver = null;
            } catch (Exception e) {
                Log.e(TAG, "Receiver unregister error: " + e.getMessage());
            }
        }

        if (result != null) {
            result.success(true);
        }
    }

    /**
     * Cihazla eşleşme işlemini başlatır
     * Not: Android 4.4+ sistemlerde programatik eşleşme kısıtlı olduğundan
     * bu metod sadece eşleşme isteği gönderir, kullanıcı onayı gerekebilir
     * @param address Cihaz MAC adresi
     * @param result Sonuç callback'i
     */
    private void pairDevice(String address, final MethodChannel.Result result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth adapter bulunamadı", null);
            return;
        }

        try {
            BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
            if (device.getBondState() == BluetoothDevice.BOND_BONDED) {
                result.success(true);
                return;
            }

            // Eşleşme isteği gönder (Android 4.4+ sistemlerde kullanıcı onayı gerekebilir)
            device.getClass().getMethod("createBond").invoke(device);
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Pair error: " + e.getMessage());
            result.error("PAIR_FAILED", "Cihazla eşleşme başarısız: " + e.getMessage(), null);
        }
    }

    /**
     * Cihazla eşleşmeyi kaldırır
     * @param address Cihaz MAC adresi
     * @param result Sonuç callback'i
     */
    private void unpairDevice(String address, final MethodChannel.Result result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth adapter bulunamadı", null);
            return;
        }

        try {
            // Eğer bağlı cihaz ise önce bağlantıyı kes
            if (connectedDevice != null && connectedDevice.getAddress().equals(address)) {
                disconnect(null);
            }
            
            BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
            device.getClass().getMethod("removeBond").invoke(device);
            result.success(true);
        } catch (Exception e) {
            Log.e(TAG, "Unpair error: " + e.getMessage());
            result.error("UNPAIR_FAILED", "Cihazla eşleşme kaldırılamadı: " + e.getMessage(), null);
        }
    }
    
    /**
     * Bluetooth cihazına bağlanır
     * @param address Bağlanılacak cihazın MAC adresi
     * @param result Sonuç callback'i
     */
    private void connect(String address, final MethodChannel.Result result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_UNAVAILABLE", "Bluetooth adapter bulunamadı", null);
            return;
        }
        
        // Zaten bağlıysa veya bağlanıyorsa hata döndür
        if (connectionState == CONNECTION_STATE_CONNECTED || connectionState == CONNECTION_STATE_CONNECTING) {
            result.error("ALREADY_CONNECTING", "Zaten bir cihaza bağlı veya bağlanıyor", null);
            return;
        }
        
        // Önce keşif işlemini durdur (bağlantıyı engelleyebilir)
        if (bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }
        
        // Bağlantı durumunu güncelle
        updateConnectionState(CONNECTION_STATE_CONNECTING);
        
        // Bağlantıyı ayrı bir thread'de gerçekleştir
        executorService.execute(() -> {
            try {
                // Cihazı al
                BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
                
                // Soket oluştur ve bağlan
                bluetoothSocket = device.createRfcommSocketToServiceRecord(SPP_UUID);
                bluetoothSocket.connect();
                
                // Bağlantı başarılı
                connectedDevice = device;
                updateConnectionState(CONNECTION_STATE_CONNECTED);
                
                // Sonucu ana thread'de döndür
                mainHandler.post(() -> result.success(true));
                
            } catch (IOException e) {
                Log.e(TAG, "Connection error: " + e.getMessage());
                
                // Bağlantı hatası
                closeSocket();
                connectedDevice = null;
                updateConnectionState(CONNECTION_STATE_ERROR);
                
                // Sonucu ana thread'de döndür
                mainHandler.post(() -> result.error("CONNECTION_FAILED", "Bağlantı hatası: " + e.getMessage(), null));
            }
        });
    }
    
    /**
     * Bluetooth bağlantısını keser
     * @param result Sonuç callback'i (null olabilir)
     */
    private void disconnect(final MethodChannel.Result result) {
        // Bağlı değilse hata döndür
        if (connectionState != CONNECTION_STATE_CONNECTED) {
            if (result != null) {
                result.error("NOT_CONNECTED", "Bağlı bir cihaz yok", null);
            }
            return;
        }
        
        // Bağlantı durumunu güncelle
        updateConnectionState(CONNECTION_STATE_DISCONNECTING);
        
        // Bağlantıyı ayrı bir thread'de kes
        executorService.execute(() -> {
            closeSocket();
            connectedDevice = null;
            updateConnectionState(CONNECTION_STATE_DISCONNECTED);
            
            // Sonuç null değilse ana thread'de döndür
            if (result != null) {
                mainHandler.post(() -> result.success(true));
            }
        });
    }
    
    /**
     * Bluetooth soketini kapatır
     */
    private void closeSocket() {
        if (bluetoothSocket != null) {
            try {
                bluetoothSocket.close();
            } catch (IOException e) {
                Log.e(TAG, "Close socket error: " + e.getMessage());
            } finally {
                bluetoothSocket = null;
            }
        }
    }
    
    /**
     * Bağlantı durumunu günceller ve Flutter'a bildirir
     * @param state Yeni bağlantı durumu
     */
    private void updateConnectionState(int state) {
        if (connectionState != state) {
            connectionState = state;
            
            // Flutter'a bağlantı durumu değişikliğini bildir
            mainHandler.post(() -> {
                if (methodChannel != null) {
                    Map<String, Object> stateMap = new HashMap<>();
                    stateMap.put("state", state);
                    
                    if (connectedDevice != null) {
                        stateMap.put("address", connectedDevice.getAddress());
                    }
                    
                    methodChannel.invokeMethod("onConnectionStateChanged", stateMap);
                }
            });
        }
    }
    
    /**
     * Bağlantı durumu değişikliklerini dinleyen BroadcastReceiver'ı kaydeder
     */
    private void registerConnectionReceiver() {
        connectionReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                
                if (device == null) {
                    return;
                }
                
                // Cihaz bağlantı durumu değişiklikleri
                if (BluetoothDevice.ACTION_ACL_CONNECTED.equals(action)) {
                    if (connectedDevice != null && device.getAddress().equals(connectedDevice.getAddress())) {
                        updateConnectionState(CONNECTION_STATE_CONNECTED);
                    }
                } else if (BluetoothDevice.ACTION_ACL_DISCONNECTED.equals(action)) {
                    if (connectedDevice != null && device.getAddress().equals(connectedDevice.getAddress())) {
                        connectedDevice = null;
                        closeSocket();
                        updateConnectionState(CONNECTION_STATE_DISCONNECTED);
                    }
                }
            }
        };
        
        // Intent filtreleri
        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothDevice.ACTION_ACL_CONNECTED);
        filter.addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED);
        
        // BroadcastReceiver'ı kaydet
        context.registerReceiver(connectionReceiver, filter);
    }

    /**
     * Kaynakları temizler
     */
    public void dispose() {
        // Aktif tarama varsa durdur
        stopDiscovery(null);
        
        // Aktif bağlantı varsa kes
        if (connectionState == CONNECTION_STATE_CONNECTED) {
            disconnect(null);
        }
        
        // BroadcastReceiver'ları kaldır
        if (connectionReceiver != null) {
            try {
                context.unregisterReceiver(connectionReceiver);
                connectionReceiver = null;
            } catch (Exception e) {
                Log.e(TAG, "Connection receiver unregister error: " + e.getMessage());
            }
        }
        
        // Thread havuzunu kapat
        executorService.shutdown();
    }
}
