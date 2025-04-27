import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart' as domain;
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';

class SaveScanResult implements UseCase<int, SaveScanParams> {
  final ScanRepository repository;

  SaveScanResult(this.repository);

  @override
  Future<Either<Failure, int>> call(SaveScanParams params) async {
    // Llama al método del repositorio para guardar el resultado
    return await repository.saveScanResult(params.scan);
  }
}

// Parámetros para el Use Case
class SaveScanParams extends Equatable {
  final domain.ScanResult scan;

  const SaveScanParams({required this.scan});

  @override
  List<Object?> get props => [scan];
}
