package com.example.qr_scanner_app.qr_scanner

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.ImageButton
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.common.util.concurrent.ListenableFuture
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.example.qr_scanner_app.R
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class QrScannerActivity : AppCompatActivity() {

    companion object {
        private const val TAG = "QrScannerActivity"
        const val EXTRA_SCAN_RESULT = "scan_result"
        const val EXTRA_SCAN_ERROR = "scan_error"
    }

    private lateinit var cameraProviderFuture: ListenableFuture<ProcessCameraProvider>
    private lateinit var cameraExecutor: ExecutorService
    private lateinit var previewView: PreviewView
    private var barcodeScanner: BarcodeScanner? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: Camera? = null
    private var isProcessing = false

    private val requestPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted: Boolean ->
            if (isGranted) {
                //Log.i(TAG, "Permiso de cámara concedido")
                startCamera()
            } else {
                //Log.e(TAG, "Permiso de cámara denegado")
                Toast.makeText(this, "Permiso de cámara requerido", Toast.LENGTH_SHORT).show()
                finishWithError("Permiso denegado")
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_qr_scanner)
        previewView = findViewById(R.id.previewView)
        cameraExecutor = Executors.newSingleThreadExecutor()

        requestCameraPermission()
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraExecutor.shutdown()
        barcodeScanner?.close()
        cameraProvider?.unbindAll()
    }

    private fun requestCameraPermission() {
        when {
            ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED -> {
                //Log.i(TAG, "Permiso ya concedido")
                startCamera()
            }
            shouldShowRequestPermissionRationale(Manifest.permission.CAMERA) -> {
                Toast.makeText(this, "Se necesita la cámara para escanear QRs", Toast.LENGTH_LONG).show()
                requestPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
            else -> {
                requestPermissionLauncher.launch(Manifest.permission.CAMERA)
            }
        }
    }

    private fun startCamera() {
        cameraProviderFuture = ProcessCameraProvider.getInstance(this)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindPreviewAndAnalysis(cameraProvider!!)
            } catch (e: Exception) {
                //Log.e(TAG, "Error al obtener CameraProvider", e)
                finishWithError("Error al iniciar cámara")
            }
        }, ContextCompat.getMainExecutor(this))
    }

    private fun bindPreviewAndAnalysis(cameraProvider: ProcessCameraProvider) {
        val preview: Preview = Preview.Builder().build()
        val cameraSelector: CameraSelector = CameraSelector.Builder()
            .requireLensFacing(CameraSelector.LENS_FACING_BACK)
            .build()

        preview.setSurfaceProvider(previewView.surfaceProvider)

        val imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            // Mantén la resolución si te funcionó, si no, puedes comentarla
            .setTargetResolution(android.util.Size(1280, 720))
            .build()

        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        barcodeScanner = BarcodeScanning.getClient(options)

        imageAnalysis.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(barcodeScanner!!, imageProxy)
        }

        try {
            cameraProvider.unbindAll()
            camera = cameraProvider.bindToLifecycle(
                this as LifecycleOwner,
                cameraSelector,
                preview,
                imageAnalysis
            )
        } catch (e: Exception) {
            //Log.e(TAG, "Fallo al vincular casos de uso de cámara", e)
            finishWithError("Error al vincular cámara")
        }
    }

    @SuppressLint("UnsafeOptInUsageError") // Necesario para imageProxy.image
    private fun processImageProxy(barcodeScanner: BarcodeScanner, imageProxy: ImageProxy) {
        //Log.v(TAG, "processImageProxy - Frame recibido: ${imageProxy.imageInfo.timestamp}")

        if (isProcessing) {
            //Log.v(TAG, "processImageProxy - Saltando frame, ya procesando.")
            imageProxy.close()
            return
        }

        val mediaImage = imageProxy.image
        if (mediaImage != null) {
            //Log.d(TAG, "processImageProxy - Obtenida MediaImage, rotación: ${imageProxy.imageInfo.rotationDegrees}")
            isProcessing = true // Marca como procesando ANTES de llamar a process
            val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

            //Log.d(TAG, "processImageProxy - Llamando a barcodeScanner.process()")

            barcodeScanner.process(image)
                .addOnSuccessListener { barcodes ->
                    var foundUsableBarcode = false
                    if (barcodes.isNotEmpty()) {
                        val barcode = barcodes.first()
                        val rawValue = barcode.rawValue // <-- Obtiene el contenido
                        if (rawValue != null) {
                            // ¡ÉXITO! Log y finaliza la actividad
                            //Log.i(TAG, "Código QR detectado: $rawValue") // <-- Log con el contenido
                            foundUsableBarcode = true
                            finishWithSuccess(rawValue) // <-- Finaliza con el contenido
                        } else {
                            //Log.w(TAG, "Código QR detectado pero sin valor raw.")
                            // No hacemos finish, permitimos re-escaneo
                        }
                    } else {
                        //Log.v(TAG, "processImageProxy - onSuccessListener - No barcodes in this frame.")
                        // No hacemos finish, permitimos re-escaneo
                    }

                    // Resetea el flag SOLO si no encontramos un código válido para finalizar
                    if (!foundUsableBarcode) {
                        isProcessing = false
                    }
                    imageProxy.close() // Cierra el proxy aquí después de procesar
                }
                .addOnFailureListener { e ->
                    //Log.e(TAG, "processImageProxy - onFailureListener", e)
                    isProcessing = false // Resetea en caso de error
                    imageProxy.close()
                }
                // No necesitas addOnCompleteListener si manejas close() y isProcessing en success/failure
        } else {
            //Log.w(TAG, "processImageProxy - MediaImage fue null")
            // Cierra si la imagen es null y no estabas procesando (aunque raro)
             if(!isProcessing) { imageProxy.close() }
        }
    }


    private fun finishWithSuccess(result: String) {
         if (!isFinishing) {
            //Log.d(TAG,"Finishing activity with SUCCESS: $result")
            val intent = Intent()
            intent.putExtra(EXTRA_SCAN_RESULT, result)
            setResult(Activity.RESULT_OK, intent)
            finish()
        }
    }

    private fun finishWithError(error: String) {
        if (!isFinishing) {
            //Log.d(TAG,"Finishing activity with ERROR: $error")
            val intent = Intent()
            intent.putExtra(EXTRA_SCAN_ERROR, error)
            setResult(Activity.RESULT_CANCELED, intent)
            finish()
        }
    }

    override fun onBackPressed() {
         if (!isFinishing) {
            //Log.i(TAG, "Escaneo cancelado por botón atrás")
            setResult(Activity.RESULT_CANCELED)
            finish()
        }
        super.onBackPressed()
    }

}