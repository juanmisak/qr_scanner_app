import 'package:qr_scanner_app/core/constants/storage_keys.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

// Interfaz del DataSource Nativo
abstract class SecureStorageNativeDataSource {
  Future<void> writePin(String pin);
  Future<String?> readPin();
  Future<void> deletePin();
  Future<bool> hasPin();
}

// Implementación usando Pigeon
class SecureStorageNativeDataSourceImpl
    implements SecureStorageNativeDataSource {
  final SecureStorageApi _api; // El cliente Pigeon generado

  SecureStorageNativeDataSourceImpl(this._api);

  @override
  Future<void> writePin(String pin) async {
    try {
      await _api.write(pinStorageKey, pin);
    } catch (e) {
      throw Exception('Failed to write PIN to secure storage: $e');
    }
  }

  @override
  Future<String?> readPin() async {
    try {
      return await _api.read(pinStorageKey);
    } catch (e) {
      throw Exception('Failed to read PIN from secure storage: $e');
    }
  }

  @override
  Future<void> deletePin() async {
    try {
      await _api.delete(pinStorageKey);
    } catch (e) {
      throw Exception('Failed to delete PIN from secure storage: $e');
    }
  }

  @override
  Future<bool> hasPin() async {
    try {
      return await _api.exists(pinStorageKey);
    } catch (e) {
      throw Exception('Failed to check PIN existence in secure storage: $e');
    }
  }
}
