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
// ... (Otras APIs como BiometricApi, QrScannerApi) ...
// --- Secure Storage API ---
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
