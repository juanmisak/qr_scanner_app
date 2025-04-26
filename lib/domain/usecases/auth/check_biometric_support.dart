import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';

class CheckBiometricSupport implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  CheckBiometricSupport(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.isBiometricSupported();
  }
}
