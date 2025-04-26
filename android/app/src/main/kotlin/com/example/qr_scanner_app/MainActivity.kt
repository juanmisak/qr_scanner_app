package com.example.qr_scanner_app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.qr_scanner_app.securestorage.SecureStorageHelper
import com.example.qr_scanner_app.biometric.BiometricAuthHelper
import com.example.qr_scanner_app.pigeon.SecureStorageApi
import com.example.qr_scanner_app.pigeon.BiometricApi

class MainActivity : FlutterFragmentActivity() { 

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val context = applicationContext
        val activity = this

        SecureStorageApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            SecureStorageHelper(context)
        )

        BiometricApi.setUp(
             flutterEngine.dartExecutor.binaryMessenger,
             BiometricAuthHelper(activity)
        )
    }
}