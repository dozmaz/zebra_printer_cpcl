package com.sameetdmr.zebra_printer;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;

/**
 * Helper to verify Bluetooth permissions for Android 10 (API 29) to Android 17 (API 37+).
 */
public class BluetoothPermissionHelper {

    /**
     * Checks if scanning permission is granted.
     * - Android 12+ (API 31+): BLUETOOTH_SCAN
     * - Android 10-11 (API 29-30): ACCESS_FINE_LOCATION
     */
    public static boolean hasBluetoothScanPermission(Context context) {
        if (context == null) return false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return context.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED;
        } else {
            return context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }
    }

    /**
     * Checks if connect permission is granted.
     * - Android 12+ (API 31+): BLUETOOTH_CONNECT
     * - Android 10-11 (API 29-30): BLUETOOTH
     */
    public static boolean hasBluetoothConnectPermission(Context context) {
        if (context == null) return false;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
        } else {
            return context.checkSelfPermission(Manifest.permission.BLUETOOTH) == PackageManager.PERMISSION_GRANTED;
        }
    }

    /**
     * Checks if both Bluetooth scan and connect permissions are granted.
     */
    public static boolean hasBluetoothPermissions(Context context) {
        return hasBluetoothScanPermission(context) && hasBluetoothConnectPermission(context);
    }
}
