// api.dart o pigeon/schema.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'com.example.qr_scanner_app',
    dartOut: 'lib/pigeon/messages.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/example/qr_scanner_app/pigeon/Pigeon.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.qr_scanner_app.pigeon'),
  ),
)
enum BiometricAuthStatus {
  // Éxito
  success,
  // Fallos genéricos
  failure, // Error inesperado o no especificado
  // Errores específicos de BiometricPrompt (mapeados desde las constantes ERROR_...)
  errorHwUnavailable, // Hardware no disponible
  errorNoBiometrics, // No hay datos biométricos registrados
  errorNoDeviceCredential, // No hay PIN/Patrón/Contraseña de respaldo configurado
  errorSecurityUpdateRequired, // Actualización de seguridad necesaria
  // Acciones del usuario o del sistema
  errorUserCanceled, // El usuario canceló
  errorTimeout, // Tiempo de espera agotado
  errorLockout, // Demasiados intentos fallidos (temporal)
  errorLockoutPermanent, // Demasiados intentos fallidos (permanente)
  // Otros
  errorUnknown, // Un código de error no mapeado
}

// Clase para devolver el resultado de la autenticación
class BiometricResult {
  late BiometricAuthStatus status;
  String? errorMessage; // Mensaje adicional en caso de error
}

@HostApi()
abstract class BiometricApi {
  // Verifica si la biometría está disponible y configurada
  @async
  bool isBiometricSupported();

  // Inicia el prompt de autenticación
  @async
  BiometricResult authenticate(String reason); // 'reason' es el texto mostrado en el prompt
}

@HostApi()
abstract class SecureStorageApi {
  @async
  void write(String key, String value);
  @async
  String? read(String key);
  @async
  void delete(String key);
  // Método conveniente para verificar existencia sin leer el valor
  @async
  bool exists(String key);
}

// Constante para la clave del PIN
const String pinStorageKey = 'user_pin';
