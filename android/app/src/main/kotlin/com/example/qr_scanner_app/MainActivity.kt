package com.example.qr_scanner_app
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.qr_scanner_app.securestorage.SecureStorageHelper
import com.example.qr_scanner_app.pigeon.SecureStorageApi

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val context = applicationContext
        // val activity = this

        // Setup SecureStorageApi 
        SecureStorageApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureStorageHelper(context)
        )

        // Ejemplo si tuvieras BiometricApi:
        // Pigeon.BiometricApi.setUp(
        //     flutterEngine.dartExecutor.binaryMessenger,
        //     BiometricAuthHelper(this) // Biometric necesita Activity
        // )

         // Ejemplo si tuvieras QrScannerApi:
        // Pigeon.QrScannerApi.setUp(
        //     flutterEngine.dartExecutor.binaryMessenger,
        //     QrScannerHelper(this) // QR Scanner probablemente necesite Activity/Context
        // )
    }
}