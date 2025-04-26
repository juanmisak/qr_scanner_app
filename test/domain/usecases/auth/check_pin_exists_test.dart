import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';

// Mock para el Repositorio
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late CheckPinExists usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = CheckPinExists(mockAuthRepository);
  });

  test('should return true from repository when pin exists', () async {
    // arrange
    when(
      () => mockAuthRepository.hasPin(),
    ).thenAnswer((_) async => const Right(true));
    // act
    final result = await usecase(NoParams());
    // assert
    expect(result, const Right(true));
    verify(() => mockAuthRepository.hasPin()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return false from repository when pin does not exist', () async {
    // arrange
    when(
      () => mockAuthRepository.hasPin(),
    ).thenAnswer((_) async => const Right(false));
    // act
    final result = await usecase(NoParams());
    // assert
    expect(result, const Right(false));
    verify(() => mockAuthRepository.hasPin()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test(
    'should return failure from repository when checking pin fails',
    () async {
      // arrange
      const tFailure = SecureStorageFailure('Storage Error');
      when(
        () => mockAuthRepository.hasPin(),
      ).thenAnswer((_) async => const Left(tFailure));
      // act
      final result = await usecase(NoParams());
      // assert
      expect(result, const Left(tFailure));
      verify(() => mockAuthRepository.hasPin()).called(1);
      verifyNoMoreInteractions(mockAuthRepository);
    },
  );
}
