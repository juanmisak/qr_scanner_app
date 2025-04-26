import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

abstract class AuthRepository {
  /// Métodos de PIN
  Future<Either<Failure, bool>> hasPin();
  Future<Either<Failure, Unit>> savePin(String pin);
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, Unit>> deletePin();

  /// Métodos de Biometría
  Future<Either<Failure, bool>> isBiometricSupported();
  Future<Either<Failure, BiometricResult>> authenticateWithBiometrics(
    String reason,
  );
}
