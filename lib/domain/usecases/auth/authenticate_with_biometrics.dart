import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Importa BiometricResult

class AuthenticateWithBiometrics
    implements UseCase<BiometricResult, AuthenticateWithBiometricsParams> {
  final AuthRepository repository;

  AuthenticateWithBiometrics(this.repository);

  @override
  Future<Either<Failure, BiometricResult>> call(
    AuthenticateWithBiometricsParams params,
  ) async {
    return await repository.authenticateWithBiometrics(params.reason);
  }
}

class AuthenticateWithBiometricsParams extends Equatable {
  final String reason;
  const AuthenticateWithBiometricsParams({required this.reason});
  @override
  List<Object?> get props => [reason];
}
