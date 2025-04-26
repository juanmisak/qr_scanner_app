import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> hasPin();
  Future<Either<Failure, Unit>> savePin(String pin);
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, Unit>> deletePin();

  // Future<Either<Failure, bool>> isBiometricSupported();
  // Future<Either<Failure, bool>> authenticateWithBiometrics();
}
