import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';

class SavePin implements UseCase<Unit, SavePinParams> {
  final AuthRepository repository;

  SavePin(this.repository);

  @override
  Future<Either<Failure, Unit>> call(SavePinParams params) async {
    if (params.pin.length != 4) {
      return Left(AuthenticationFailure('PIN must be 4 digits long.'));
    }
    return await repository.savePin(params.pin);
  }
}

class SavePinParams extends Equatable {
  final String pin;
  const SavePinParams({required this.pin});
  @override
  List<Object?> get props => [pin];
}
