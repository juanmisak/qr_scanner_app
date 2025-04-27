import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart';
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';

class GetScanHistory implements UseCase<List<ScanResult>, NoParams> {
  final ScanRepository repository;
  GetScanHistory(this.repository);

  @override
  Future<Either<Failure, List<ScanResult>>> call(NoParams params) async {
    return await repository.getScanHistory();
  }
}
