package com.example.qr_scanner_app

import android.app.Activity
import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import com.example.qr_scanner_app.securestorage.SecureStorageHelper
import com.example.qr_scanner_app.biometric.BiometricAuthHelper
import com.example.qr_scanner_app.qr_scanner.QrScannerActivity
import com.example.qr_scanner_app.pigeon.SecureStorageApi
import com.example.qr_scanner_app.pigeon.BiometricApi
import com.example.qr_scanner_app.pigeon.QrScannerApi
import com.example.qr_scanner_app.pigeon.QrScanResult
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext


class MainActivity : FlutterFragmentActivity() {

    private val job = SupervisorJob()
    private val scope = CoroutineScope(Dispatchers.Main + job)
    // Mantenemos el completer a nivel de clase para asociarlo con el launcher
    private var scanCompleterCallback: ((Result<QrScanResult>) -> Unit)? = null

    private val scanQrLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
         // Obtiene el callback asociado a esta petición
         val callback = scanCompleterCallback
         scanCompleterCallback = null // Resetea para la próxima

         if (callback == null) return@registerForActivityResult // No había petición activa

         // Calcula el resultado
         val qrScanResult = if (result.resultCode == Activity.RESULT_OK) {
             val scannedCode = result.data?.getStringExtra(QrScannerActivity.EXTRA_SCAN_RESULT)
             if (scannedCode != null) {
                 QrScanResult(code = scannedCode, cancelled = false)
             } else {
                 QrScanResult(error = "No se recibió código del escáner", cancelled = false)
             }
         } else {
             val errorMsg = result.data?.getStringExtra(QrScannerActivity.EXTRA_SCAN_ERROR)
             if (errorMsg != null) {
                 QrScanResult(error = errorMsg, cancelled = false)
             } else {
                 QrScanResult(error = "Escaneo cancelado", cancelled = true)
             }
         }
        // Llama al callback de Pigeon con el resultado
         callback(Result.success(qrScanResult))
         // Nota: Usamos Result.success aquí porque pudimos *obtener* un resultado (aunque sea de error/cancelación).
         // Result.failure se usaría si ocurriera una excepción al *intentar* realizar la operación.
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val context = applicationContext
        val activity = this

        // Setup SecureStorageApi
        SecureStorageApi.setUp(flutterEngine.dartExecutor.binaryMessenger, SecureStorageHelper(context))

        // Setup BiometricApi
        BiometricApi.setUp(flutterEngine.dartExecutor.binaryMessenger, BiometricAuthHelper(activity))

        // Setup QrScannerApi
        QrScannerApi.setUp(flutterEngine.dartExecutor.binaryMessenger, NativeQrScannerApi(this))
    }

     override fun onDestroy() {
        super.onDestroy()
        job.cancel()
    }

    // Implementación interna de la API de Pigeon
     inner class NativeQrScannerApi(private val activity: Activity) : QrScannerApi {

         // Implementa la firma con CALLBACK esperada por Pigeon
         override fun scanQrCode(callback: (Result<QrScanResult>) -> Unit) {
            // Asigna el callback recibido a la variable de la clase
            // para que el launcher pueda encontrarlo cuando vuelva el resultado.
            this@MainActivity.scanCompleterCallback = callback

             try {
                // Lanza la Activity de escaneo usando el launcher registrado
                val intent = Intent(activity, QrScannerActivity::class.java)
                scanQrLauncher.launch(intent)
                // NO esperamos aquí. El resultado llegará al launcher de forma asíncrona,
                // y el launcher llamará al 'callback' que acabamos de guardar.
             } catch(e: Exception) {
                // Si hay un error al *intentar* lanzar la actividad, llamamos al callback con failure
                 this@MainActivity.scanCompleterCallback = null // Limpia el callback
                 callback(Result.failure(e))
             }
        }
     }
}