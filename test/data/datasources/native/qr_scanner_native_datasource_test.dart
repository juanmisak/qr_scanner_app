import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/data/datasources/native/qr_scanner_native_datasource.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Importa API y tipos

// Mock para la API de Pigeon
class MockQrScannerApi extends Mock implements QrScannerApi {}

void main() {
  late QrScannerNativeDataSourceImpl dataSource;
  late MockQrScannerApi mockApi;

  setUpAll(() {
    // Registra un valor fallback para QrScanResult si usas any() o capture()
    registerFallbackValue(QrScanResult(cancelled: false));
  });

  setUp(() {
    mockApi = MockQrScannerApi();
    dataSource = QrScannerNativeDataSourceImpl(mockApi);
  });

  final tSuccessQrScanResult = QrScanResult(
    code: 'test_code',
    cancelled: false,
  );
  final tCancelledQrScanResult = QrScanResult(
    code: null,
    cancelled: true,
    error: 'Escaneo cancelado',
  );
  final tErrorQrScanResult = QrScanResult(
    code: null,
    cancelled: false,
    error: 'Native Error',
  );
  final tException = Exception('Pigeon Call Failed');

  test(
    'should call QrScannerApi.scanQrCode and return the result on success',
    () async {
      // arrange
      when(
        () => mockApi.scanQrCode(),
      ).thenAnswer((_) async => tSuccessQrScanResult);

      // act
      final result = await dataSource.scanQrCode();

      // assert
      expect(result, tSuccessQrScanResult);
      verify(() => mockApi.scanQrCode()).called(1);
      verifyNoMoreInteractions(mockApi);
    },
  );

  test(
    'should call QrScannerApi.scanQrCode and return the result on cancellation',
    () async {
      // arrange
      when(
        () => mockApi.scanQrCode(),
      ).thenAnswer((_) async => tCancelledQrScanResult);
      // act
      final result = await dataSource.scanQrCode();
      // assert
      expect(result, tCancelledQrScanResult);
      verify(() => mockApi.scanQrCode()).called(1);
      verifyNoMoreInteractions(mockApi);
    },
  );

  test(
    'should call QrScannerApi.scanQrCode and return the result on native error',
    () async {
      // arrange
      when(
        () => mockApi.scanQrCode(),
      ).thenAnswer((_) async => tErrorQrScanResult);
      // act
      final result = await dataSource.scanQrCode();
      // assert
      expect(result, tErrorQrScanResult);
      verify(() => mockApi.scanQrCode()).called(1);
      verifyNoMoreInteractions(mockApi);
    },
  );

  test(
    'should return a default error QrScanResult when the api call throws',
    () async {
      // arrange
      when(() => mockApi.scanQrCode()).thenThrow(tException);

      // act
      final result = await dataSource.scanQrCode();

      // assert
      expect(result, isA<QrScanResult>());
      expect(result.error, isNotNull);
      expect(
        result.error,
        contains('Error al comunicarse con el módulo nativo'),
      );
      expect(result.code, isNull);
      expect(result.cancelled, false);
      verify(() => mockApi.scanQrCode()).called(1);
      verifyNoMoreInteractions(mockApi);
    },
  );
}
