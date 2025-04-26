import 'package:dartz/dartz.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageNativeDataSource nativeDataSource;

  AuthRepositoryImpl({required this.nativeDataSource});

  @override
  Future<Either<Failure, bool>> hasPin() async {
    try {
      final result = await nativeDataSource.hasPin();
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
      await nativeDataSource.writePin(pin);
      return const Right(unit);
    } catch (e) {
      return Left(SecureStorageFailure('Failed to save PIN: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final storedPin = await nativeDataSource.readPin();
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
      await nativeDataSource.deletePin();
      return const Right(unit);
    } catch (e) {
      return Left(
        SecureStorageFailure('Failed to delete PIN: ${e.toString()}'),
      );
    }
  }
}
