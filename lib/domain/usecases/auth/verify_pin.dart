import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';

class VerifyPin implements UseCase<bool, VerifyPinParams> {
  final AuthRepository repository;

  VerifyPin(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyPinParams params) async {
    if (params.pin.length != 4) {
      return const Right(false);
    }
    return await repository.verifyPin(params.pin);
  }
}

class VerifyPinParams extends Equatable {
  final String pin;
  const VerifyPinParams({required this.pin});
  @override
  List<Object?> get props => [pin];
}
