import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/data/datasources/native/biometric_native_datasource.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

class AuthRepositoryImpl implements AuthRepository {
  //final SecureStorageNativeDataSource nativeDataSource;
  final SecureStorageNativeDataSource
  secureStorageDataSource; // Renombrado para claridad
  final BiometricNativeDataSource biometricDataSource; // <-- Añade el nuevo DS

  AuthRepositoryImpl({
    //required this.nativeDataSource,
    required this.biometricDataSource,
    required this.secureStorageDataSource,
  });

  @override
  Future<Either<Failure, bool>> hasPin() async {
    try {
      final result = await secureStorageDataSource.hasPin();
      return Right(result);
    } catch (e) {
      return Left(
        SecureStorageFailure('Failed to check PIN existence: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> savePin(String pin) async {
    try {
      await secureStorageDataSource.writePin(pin);
      return const Right(unit);
    } catch (e) {
      return Left(SecureStorageFailure('Failed to save PIN: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final storedPin = await secureStorageDataSource.readPin();
      if (storedPin == null) {
        return const Left(AuthenticationFailure('PIN not set. Cannot verify.'));
      }
      if (storedPin == pin) {
        return const Right(true); // PIN correcto
      } else {
        return const Right(false); // PIN incorrecto
      }
    } catch (e) {
      return Left(
        SecureStorageFailure('Failed to verify PIN: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePin() async {
    try {
      await secureStorageDataSource.deletePin();
      return const Right(unit);
    } catch (e) {
      return Left(
        SecureStorageFailure('Failed to delete PIN: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> isBiometricSupported() async {
    try {
      final result = await biometricDataSource.isBiometricSupported();
      return Right(result);
    } catch (e) {
      return Left(
        BiometricFailure('Failed to check biometric support: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, BiometricResult>> authenticateWithBiometrics(
    String reason,
  ) async {
    try {
      final result = await biometricDataSource.authenticate(reason);
      // Aquí podrías mapear ciertos status a Failure si lo deseas,
      // pero por ahora devolvemos el BiometricResult completo en caso de éxito de la llamada.
      if (result.status == BiometricAuthStatus.success) {
        return Right(result);
      } else {
        // Consideramos cualquier otro status como un 'fallo' en el flujo de autenticación,
        // aunque la llamada a la API nativa haya sido exitosa.
        // Devolvemos el BiometricResult para que el BLoC decida qué hacer.
        // Alternativamente, podrías retornar Left(BiometricAuthFailure(result)) aquí.
        return Right(result);
      }
    } catch (e) {
      return Left(
        BiometricFailure(
          'Failed to authenticate with biometrics: ${e.toString()}',
        ),
      );
    }
  }
}

// Define un Failure específico para Biometría si quieres
class BiometricFailure extends Failure {
  const BiometricFailure(String message) : super(message);
}
