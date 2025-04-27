import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

class StartQrScan implements UseCase<QrScanResult, NoParams> {
  final ScanRepository repository;

  StartQrScan(this.repository);

  @override
  Future<Either<Failure, QrScanResult>> call(NoParams params) async {
    return await repository.startQrScan();
  }
}
