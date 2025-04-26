import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/data/datasources/native/biometric_native_datasource.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Importa API y tipos

// Mock para la API de Pigeon
class MockBiometricApi extends Mock implements BiometricApi {}

void main() {
  late BiometricNativeDataSourceImpl dataSource;
  late MockBiometricApi mockApi;

  setUp(() {
    mockApi = MockBiometricApi();
    dataSource = BiometricNativeDataSourceImpl(mockApi);
    registerFallbackValue(''); // Para any() con String
    registerFallbackValue(
      BiometricResult(status: BiometricAuthStatus.success),
    ); // Fallback para BiometricResult
  });

  const tReason = 'Test Reason';
  final tSuccessResult = BiometricResult(status: BiometricAuthStatus.success);
  final tFailureResult = BiometricResult(
    status: BiometricAuthStatus.failure,
    errorMessage: 'Failed',
  );

  group('isBiometricSupported', () {
    test(
      'should call BiometricApi.isBiometricSupported and return result',
      () async {
        // arrange
        when(
          () => mockApi.isBiometricSupported(),
        ).thenAnswer((_) async => true);
        // act
        final result = await dataSource.isBiometricSupported();
        // assert
        expect(result, true);
        verify(() => mockApi.isBiometricSupported()).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test(
      'should return false when BiometricApi.isBiometricSupported throws',
      () async {
        // arrange
        when(
          () => mockApi.isBiometricSupported(),
        ).thenThrow(Exception('API Error'));
        // act
        final result = await dataSource.isBiometricSupported();
        // assert
        expect(result, false); // Asumimos false en caso de error
        verify(() => mockApi.isBiometricSupported()).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );
  });

  group('authenticate', () {
    test(
      'should call BiometricApi.authenticate with correct reason and return result on success',
      () async {
        // arrange
        when(
          () => mockApi.authenticate(any()),
        ).thenAnswer((_) async => tSuccessResult);
        // act
        final result = await dataSource.authenticate(tReason);
        // assert
        expect(result, tSuccessResult);
        verify(() => mockApi.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test(
      'should call BiometricApi.authenticate and return result on failure status',
      () async {
        // arrange
        when(
          () => mockApi.authenticate(any()),
        ).thenAnswer((_) async => tFailureResult);
        // act
        final result = await dataSource.authenticate(tReason);
        // assert
        expect(result, tFailureResult);
        verify(() => mockApi.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test(
      'should return generic failure result when BiometricApi.authenticate throws',
      () async {
        // arrange
        final exception = Exception('API Error');
        when(() => mockApi.authenticate(any())).thenThrow(exception);
        // act
        final result = await dataSource.authenticate(tReason);
        // assert
        // Comprueba que devuelve un BiometricResult de fallo genérico
        expect(result.status, BiometricAuthStatus.failure);
        expect(result.errorMessage, exception.toString());
        verify(() => mockApi.authenticate(tReason)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );
  });
}
