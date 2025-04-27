import 'package:qr_scanner_app/pigeon/messages.dart';

abstract class QrScannerNativeDataSource {
  Future<QrScanResult> scanQrCode();
}

class QrScannerNativeDataSourceImpl implements QrScannerNativeDataSource {
  final QrScannerApi _api;

  QrScannerNativeDataSourceImpl(this._api);

  @override
  Future<QrScanResult> scanQrCode() async {
    try {
      return await _api.scanQrCode();
    } catch (e) {
      print("Error calling native scanQrCode: $e");
      // Devuelve un resultado de error si la llamada a Pigeon falla
      return QrScanResult(
        error: "Error al comunicarse con el módulo nativo: ${e.toString()}",
        cancelled: false,
      );
    }
  }
}
