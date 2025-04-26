package com.example.qr_scanner_app.securestorage

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.example.qr_scanner_app.pigeon.SecureStorageApi 

class SecureStorageHelper(private val context: Context) : SecureStorageApi { // <-- IMPLEMENTACIÓN AÑADIDA

    private fun getEncryptedPrefs(): SharedPreferences {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        return EncryptedSharedPreferences.create(
            context,
            "qr_scanner_secure_prefs", // filename
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    override fun write(key: String, value: String, callback: (Result<Unit>) -> Unit) {
        try {
            getEncryptedPrefs().edit().putString(key, value).apply()
            callback(Result.success(Unit)) // Llama al callback con éxito
        } catch (e: Exception) {
            callback(Result.failure(e)) // Llama al callback con el error
        }
    }

    override fun read(key: String, callback: (Result<String?>) -> Unit) {
        try {
            val value = getEncryptedPrefs().getString(key, null)
            callback(Result.success(value)) // Llama al callback con el valor (puede ser null)
        } catch (e: Exception) {
            callback(Result.failure(e)) // Llama al callback con el error
        }
    }

    override fun delete(key: String, callback: (Result<Unit>) -> Unit) {
        try {
            getEncryptedPrefs().edit().remove(key).apply()
            callback(Result.success(Unit)) // Llama al callback con éxito
        } catch (e: Exception) {
            callback(Result.failure(e)) // Llama al callback con el error
        }
    }

    override fun exists(key: String, callback: (Result<Boolean>) -> Unit) {
        try {
            val exists = getEncryptedPrefs().contains(key)
            callback(Result.success(exists)) // Llama al callback con el resultado booleano
        } catch (e: Exception) {
            callback(Result.failure(e)) // Llama al callback con el error
        }
    }
}