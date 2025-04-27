import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Importa QrScanResult de Pigeon

abstract class ScanRepository {
  // Inicia el escaneo y devuelve el resultado nativo
  Future<Either<Failure, QrScanResult>> startQrScan();
  // Guarda un resultado de escaneo en el almacenamiento local
  Future<Either<Failure, int>> saveScanResult(ScanResult scan);
  // Obtiene el historial de escaneos
  Future<Either<Failure, List<ScanResult>>> getScanHistory();
}
