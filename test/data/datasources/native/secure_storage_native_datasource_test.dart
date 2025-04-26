import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/core/constants/storage_keys.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Importa la API y tipos

// Crea Mocks para las APIs de Pigeon
class MockSecureStorageApi extends Mock implements SecureStorageApi {}

void main() {
  late SecureStorageNativeDataSourceImpl dataSource;
  late MockSecureStorageApi mockApi;

  setUp(() {
    mockApi = MockSecureStorageApi();
    dataSource = SecureStorageNativeDataSourceImpl(mockApi);
    // Registra un fallback para llamadas void que no devuelven nada
    registerFallbackValue(''); // Necesario para any() con String
    when(
      () => mockApi.write(any(), any()),
    ).thenAnswer((_) async => Future.value());
    when(() => mockApi.delete(any())).thenAnswer((_) async => Future.value());
  });

  const tPin = '1234';

  group('writePin', () {
    test(
      'should call SecureStorageApi.write with correct key and pin',
      () async {
        // arrange
        // El stub ya está en setUp para write

        // act
        await dataSource.writePin(tPin);

        // assert
        verify(() => mockApi.write(pinStorageKey, tPin)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test('should throw Exception when SecureStorageApi.write throws', () async {
      // arrange
      when(() => mockApi.write(any(), any())).thenThrow(Exception('API Error'));

      // act
      final call = dataSource.writePin;

      // assert
      await expectLater(() => call(tPin), throwsA(isA<Exception>()));
      verify(() => mockApi.write(pinStorageKey, tPin)).called(1);
      verifyNoMoreInteractions(mockApi);
    });
  });

  group('readPin', () {
    test(
      'should call SecureStorageApi.read with correct key and return pin',
      () async {
        // arrange
        when(() => mockApi.read(any())).thenAnswer((_) async => tPin);

        // act
        final result = await dataSource.readPin();

        // assert
        expect(result, tPin);
        verify(() => mockApi.read(pinStorageKey)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test(
      'should return null when SecureStorageApi.read returns null',
      () async {
        // arrange
        when(() => mockApi.read(any())).thenAnswer((_) async => null);
        // act
        final result = await dataSource.readPin();
        // assert
        expect(result, isNull);
        verify(() => mockApi.read(pinStorageKey)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test('should throw Exception when SecureStorageApi.read throws', () async {
      // arrange
      when(() => mockApi.read(any())).thenThrow(Exception('API Error'));
      // act
      final call = dataSource.readPin;
      // assert
      await expectLater(call, throwsA(isA<Exception>()));
      verify(() => mockApi.read(pinStorageKey)).called(1);
      verifyNoMoreInteractions(mockApi);
    });
  });

  group('hasPin', () {
    test(
      'should call SecureStorageApi.exists with correct key and return result',
      () async {
        // arrange
        when(() => mockApi.exists(any())).thenAnswer((_) async => true);
        // act
        final result = await dataSource.hasPin();
        // assert
        expect(result, true);
        verify(() => mockApi.exists(pinStorageKey)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );

    test(
      'should throw Exception when SecureStorageApi.exists throws',
      () async {
        // arrange
        when(() => mockApi.exists(any())).thenThrow(Exception('API Error'));
        // act
        final call = dataSource.hasPin;
        // assert
        await expectLater(call, throwsA(isA<Exception>()));
        verify(() => mockApi.exists(pinStorageKey)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );
  });

  group('deletePin', () {
    test('should call SecureStorageApi.delete with correct key', () async {
      // arrange
      // Stub en setUp
      // act
      await dataSource.deletePin();
      // assert
      verify(() => mockApi.delete(pinStorageKey)).called(1);
      verifyNoMoreInteractions(mockApi);
    });

    test(
      'should throw Exception when SecureStorageApi.delete throws',
      () async {
        // arrange
        when(() => mockApi.delete(any())).thenThrow(Exception('API Error'));
        // act
        final call = dataSource.deletePin;
        // assert
        await expectLater(call, throwsA(isA<Exception>()));
        verify(() => mockApi.delete(pinStorageKey)).called(1);
        verifyNoMoreInteractions(mockApi);
      },
    );
  });
}
