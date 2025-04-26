import 'package:qr_scanner_app/pigeon/messages.dart';

abstract class BiometricNativeDataSource {
  Future<bool> isBiometricSupported();
  Future<BiometricResult> authenticate(String reason);
}

class BiometricNativeDataSourceImpl implements BiometricNativeDataSource {
  final BiometricApi _api; // Cliente Pigeon

  BiometricNativeDataSourceImpl(this._api);

  @override
  Future<bool> isBiometricSupported() async {
    try {
      return await _api.isBiometricSupported();
    } catch (e) {
      // Loggear error 'e'
      //print("Error checking biometric support: $e");
      return false; // Asumir no soportado en caso de error
    }
  }

  @override
  Future<BiometricResult> authenticate(String reason) async {
    try {
      return await _api.authenticate(reason);
    } catch (e) {
      // Loggear error 'e'
      //print("Error during biometric authentication: $e");
      // Devuelve un resultado de fallo genérico si la llamada a Pigeon falla
      return BiometricResult(
        status: BiometricAuthStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }
}
