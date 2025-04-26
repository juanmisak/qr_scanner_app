package com.example.qr_scanner_app.biometric

import android.os.Build
import android.util.Log
import androidx.fragment.app.FragmentActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
// Importa los tipos de Pigeon
import com.example.qr_scanner_app.pigeon.BiometricApi
import com.example.qr_scanner_app.pigeon.BiometricAuthStatus
import com.example.qr_scanner_app.pigeon.BiometricResult
import java.util.concurrent.Executor

class BiometricAuthHelper(
    private val activity: FragmentActivity
) : BiometricApi {

    private val executor: Executor = ContextCompat.getMainExecutor(activity)
    private val biometricManager = BiometricManager.from(activity)

    companion object {
        private const val TAG = "BiometricAuthHelper"
    }

    override fun isBiometricSupported(callback: (Result<Boolean>) -> Unit) {
        try {
            val canAuthenticate = biometricManager.canAuthenticate(BIOMETRIC_STRONG)
            val result = when (canAuthenticate) {
                BiometricManager.BIOMETRIC_SUCCESS -> true
                else -> {
                    Log.w(TAG, "Biometría no soportada o no configurada. Código: $canAuthenticate")
                    false
                }
            }
            callback(Result.success(result))
        } catch (e: Exception) {
            Log.e(TAG, "Error al verificar soporte biométrico", e)
            callback(Result.failure(e))
        }
    }

    override fun authenticate(reason: String, callback: (Result<BiometricResult>) -> Unit) {
        try {
            val promptInfo = BiometricPrompt.PromptInfo.Builder()
                .setTitle("Autenticación Requerida")
                .setSubtitle(reason)
                .setNegativeButtonText("Usar PIN")
                .setAllowedAuthenticators(BIOMETRIC_STRONG)
                .build()

            val biometricPrompt = BiometricPrompt(activity, executor,
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        super.onAuthenticationSucceeded(result)
                        Log.i(TAG, "Autenticación biométrica exitosa")
                        // ¡CORREGIDO! Usa BiometricAuthStatus.success
                        callback(Result.success(BiometricResult(status = BiometricAuthStatus.SUCCESS)))
                    }

                    override fun onAuthenticationFailed() {
                        super.onAuthenticationFailed()
                        Log.w(TAG, "Autenticación biométrica fallida")
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        super.onAuthenticationError(errorCode, errString)
                        Log.e(TAG, "Error de autenticación biométrica: $errorCode - $errString")
                        val status = mapErrorCodeToStatus(errorCode) // Esta función ya usa el enum correctamente
                        callback(Result.success(BiometricResult(status = status, errorMessage = errString.toString())))
                    }
                })

            biometricPrompt.authenticate(promptInfo)

        } catch (e: Exception) {
             Log.e(TAG, "Error al iniciar la autenticación biométrica", e)
             callback(Result.failure(e))
        }
    }

    private fun mapErrorCodeToStatus(errorCode: Int): BiometricAuthStatus {
        return when (errorCode) {
            BiometricPrompt.ERROR_HW_UNAVAILABLE -> BiometricAuthStatus.ERROR_HW_UNAVAILABLE
            BiometricPrompt.ERROR_UNABLE_TO_PROCESS,
            BiometricPrompt.ERROR_TIMEOUT -> BiometricAuthStatus.ERROR_TIMEOUT
            BiometricPrompt.ERROR_LOCKOUT -> BiometricAuthStatus.ERROR_LOCKOUT
            BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> BiometricAuthStatus.ERROR_LOCKOUT_PERMANENT
            BiometricPrompt.ERROR_USER_CANCELED -> BiometricAuthStatus.ERROR_USER_CANCELED
            BiometricPrompt.ERROR_NO_BIOMETRICS -> BiometricAuthStatus.ERROR_NO_BIOMETRICS
            BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> BiometricAuthStatus.ERROR_NO_DEVICE_CREDENTIAL
            BiometricPrompt.ERROR_SECURITY_UPDATE_REQUIRED -> BiometricAuthStatus.ERROR_SECURITY_UPDATE_REQUIRED
            else -> BiometricAuthStatus.ERROR_UNKNOWN
        }
    }
}