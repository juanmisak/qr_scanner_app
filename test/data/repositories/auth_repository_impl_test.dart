import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/data/datasources/native/biometric_native_datasource.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/auth_repository_impl.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

// Mocks para los DataSources
class MockSecureStorageNativeDataSource extends Mock
    implements SecureStorageNativeDataSource {}

class MockBiometricNativeDataSource extends Mock
    implements BiometricNativeDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockSecureStorageNativeDataSource mockSecureStorageDataSource;
  late MockBiometricNativeDataSource mockBiometricDataSource;

  setUp(() {
    mockSecureStorageDataSource = MockSecureStorageNativeDataSource();
    mockBiometricDataSource = MockBiometricNativeDataSource();
    repository = AuthRepositoryImpl(
      secureStorageDataSource: mockSecureStorageDataSource,
      biometricDataSource: mockBiometricDataSource,
    );
    // Register fallbacks for stubbing void methods or methods with simple types
    registerFallbackValue(''); // For String
    registerFallbackValue(
      BiometricResult(status: BiometricAuthStatus.success),
    ); // For BiometricResult
    // Stub void methods
    when(
      () => mockSecureStorageDataSource.writePin(any()),
    ).thenAnswer((_) async => Future.value());
    when(
      () => mockSecureStorageDataSource.deletePin(),
    ).thenAnswer((_) async => Future.value());
  });

  const tPin = '1234';
  const tReason = 'Test Reason';
  final tSuccessBiometricResult = BiometricResult(
    status: BiometricAuthStatus.success,
  );
  final tCancelBiometricResult = BiometricResult(
    status: BiometricAuthStatus.errorUserCanceled,
  );
  final tException = Exception('DataSource Error');

  group('hasPin', () {
    test('should return true when datasource returns true', () async {
      // arrange
      when(
        () => mockSecureStorageDataSource.hasPin(),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.hasPin();
      // assert
      expect(result, const Right(true));
      verify(() => mockSecureStorageDataSource.hasPin()).called(1);
      verifyNoMoreInteractions(mockSecureStorageDataSource);
      verifyZeroInteractions(mockBiometricDataSource);
    });

    test('should return SecureStorageFailure when datasource throws', () async {
      // arrange
      when(() => mockSecureStorageDataSource.hasPin()).thenThrow(tException);
      // act
      final result = await repository.hasPin();
      // assert
      expect(
        result,
        Left(
          SecureStorageFailure(
            'Failed to check PIN existence: ${tException.toString()}',
          ),
        ),
      );
      verify(() => mockSecureStorageDataSource.hasPin()).called(1);
      verifyNoMoreInteractions(mockSecureStorageDataSource);
      verifyZeroInteractions(mockBiometricDataSource);
    });
  });

  group('savePin', () {
    test(
      'should return Right(unit) when datasource saves successfully',
      () async {
        // arrange
        // Stub para writePin está en setUp
        // act
        final result = await repository.savePin(tPin);
        // assert
        expect(result, const Right(unit));
        verify(() => mockSecureStorageDataSource.writePin(tPin)).called(1);
        verifyNoMoreInteractions(mockSecureStorageDataSource);
        verifyZeroInteractions(mockBiometricDataSource);
      },
    );

    test('should return SecureStorageFailure when datasource throws', () async {
      // arrange
      when(
        () => mockSecureStorageDataSource.writePin(any()),
      ).thenThrow(tException);
      // act
      final result = await repository.savePin(tPin);
      // assert
      expect(
        result,
        Left(
          SecureStorageFailure('Failed to save PIN: ${tException.toString()}'),
        ),
      );
      verify(() => mockSecureStorageDataSource.writePin(tPin)).called(1);
      verifyNoMoreInteractions(mockSecureStorageDataSource);
      verifyZeroInteractions(mockBiometricDataSource);
    });
  });

  group('verifyPin', () {
    const tCorrectPin = '1234';
    const tIncorrectPin = '4321';

    test(
      'should return Right(true) when stored pin matches input pin',
      () async {
        // arrange
        when(
          () => mockSecureStorageDataSource.readPin(),
        ).thenAnswer((_) async => tCorrectPin);
        // act
        final result = await repository.verifyPin(tCorrectPin);
        // assert
        expect(result, const Right(true));
        verify(() => mockSecureStorageDataSource.readPin()).called(1);
        verifyNoMoreInteractions(mockSecureStorageDataSource);
      },
    );

    test(
      'should return Right(false) when stored pin does not match input pin',
      () async {
        // arrange
        when(
          () => mockSecureStorageDataSource.readPin(),
        ).thenAnswer((_) async => tCorrectPin);
        // act
        final result = await repository.verifyPin(tIncorrectPin);
        // assert
        expect(result, const Right(false));
        verify(() => mockSecureStorageDataSource.readPin()).called(1);
        verifyNoMoreInteractions(mockSecureStorageDataSource);
      },
    );

    test(
      'should return AuthenticationFailure when stored pin is null',
      () async {
        // arrange
        when(
          () => mockSecureStorageDataSource.readPin(),
        ).thenAnswer((_) async => null);
        // act
        final result = await repository.verifyPin(tCorrectPin);
        // assert
        expect(
          result,
          const Left(AuthenticationFailure('PIN not set. Cannot verify.')),
        );
        verify(() => mockSecureStorageDataSource.readPin()).called(1);
        verifyNoMoreInteractions(mockSecureStorageDataSource);
      },
    );

    test('should return SecureStorageFailure when datasource throws', () async {
      // arrange
      when(() => mockSecureStorageDataSource.readPin()).thenThrow(tException);
      // act
      final result = await repository.verifyPin(tCorrectPin);
      // assert
      expect(
        result,
        Left(
          SecureStorageFailure(
            'Failed to verify PIN: ${tException.toString()}',
          ),
        ),
      );
      verify(() => mockSecureStorageDataSource.readPin()).called(1);
      verifyNoMoreInteractions(mockSecureStorageDataSource);
    });
  });

  // --- Pruebas Biométricas ---

  group('isBiometricSupported', () {
    test('should return Right(true) when datasource returns true', () async {
      // arrange
      when(
        () => mockBiometricDataSource.isBiometricSupported(),
      ).thenAnswer((_) async => true);
      // act
      final result = await repository.isBiometricSupported();
      // assert
      expect(result, const Right(true));
      verify(() => mockBiometricDataSource.isBiometricSupported()).called(1);
      verifyNoMoreInteractions(mockBiometricDataSource);
      verifyZeroInteractions(mockSecureStorageDataSource);
    });

    test(
      'should return Left(BiometricFailure) when datasource throws',
      () async {
        // arrange
        when(
          () => mockBiometricDataSource.isBiometricSupported(),
        ).thenThrow(tException);
        // act
        final result = await repository.isBiometricSupported();
        // assert
        expect(
          result,
          Left(
            BiometricFailure(
              'Failed to check biometric support: ${tException.toString()}',
            ),
          ),
        );
        verify(() => mockBiometricDataSource.isBiometricSupported()).called(1);
        verifyNoMoreInteractions(mockBiometricDataSource);
        verifyZeroInteractions(mockSecureStorageDataSource);
      },
    );
  });

  group('authenticateWithBiometrics', () {
    test(
      'should return Right(BiometricResult) with success when datasource returns success',
      () async {
        // arrange
        when(
          () => mockBiometricDataSource.authenticate(any()),
        ).thenAnswer((_) async => tSuccessBiometricResult);
        // act
        final result = await repository.authenticateWithBiometrics(tReason);
        // assert
        expect(result, Right(tSuccessBiometricResult));
        verify(() => mockBiometricDataSource.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockBiometricDataSource);
        verifyZeroInteractions(mockSecureStorageDataSource);
      },
    );

    test(
      'should return Right(BiometricResult) with cancel status when datasource returns cancel',
      () async {
        // arrange
        when(
          () => mockBiometricDataSource.authenticate(any()),
        ).thenAnswer((_) async => tCancelBiometricResult);
        // act
        final result = await repository.authenticateWithBiometrics(tReason);
        // assert
        expect(result, Right(tCancelBiometricResult));
        verify(() => mockBiometricDataSource.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockBiometricDataSource);
        verifyZeroInteractions(mockSecureStorageDataSource);
      },
    );

    test(
      'should return Left(BiometricFailure) when datasource throws',
      () async {
        // arrange
        when(
          () => mockBiometricDataSource.authenticate(any()),
        ).thenThrow(tException);
        // act
        final result = await repository.authenticateWithBiometrics(tReason);
        // assert
        expect(
          result,
          Left(
            BiometricFailure(
              'Failed to authenticate with biometrics: ${tException.toString()}',
            ),
          ),
        );
        verify(() => mockBiometricDataSource.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockBiometricDataSource);
        verifyZeroInteractions(mockSecureStorageDataSource);
      },
    );
  });
}
