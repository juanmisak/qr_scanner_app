import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/data/datasources/local/scan_history_local_datasource.dart';
import 'package:qr_scanner_app/data/datasources/native/qr_scanner_native_datasource.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart' as domain;
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

class ScanRepositoryImpl implements ScanRepository {
  final QrScannerNativeDataSource nativeDataSource;
  final ScanHistoryLocalDataSource localDataSource;

  ScanRepositoryImpl({
    required this.nativeDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, QrScanResult>> startQrScan() async {
    try {
      // Llama al datasource nativo
      final result = await nativeDataSource.scanQrCode();
      // Devuelve el resultado de Pigeon directamente (éxito o error/cancelación)
      return Right(result);
    } catch (e) {
      return Left(
        NativeCallFailure('Error al iniciar escaneo nativo: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> saveScanResult(domain.ScanResult scan) async {
    try {
      await localDataSource.initDb(); // Asegura que la DB esté lista
      final id = await localDataSource.addScan(scan);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Error al guardar escaneo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<domain.ScanResult>>> getScanHistory() async {
    try {
      await localDataSource.initDb(); // Asegura que la DB esté lista
      final scans = await localDataSource.getScans();
      return Right(scans);
    } catch (e) {
      return Left(
        DatabaseFailure('Error al obtener historial: ${e.toString()}'),
      );
    }
  }
}

// Define nuevos tipos de Failure si es necesario
class NativeCallFailure extends Failure {
  const NativeCallFailure(super.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}
