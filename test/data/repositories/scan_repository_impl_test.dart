import 'package:const_date_time/const_date_time.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/data/datasources/local/scan_history_local_datasource.dart';
import 'package:qr_scanner_app/data/datasources/native/qr_scanner_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/scan_repository_impl.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

// Mocks para los DataSources
class MockQrScannerNativeDataSource extends Mock
    implements QrScannerNativeDataSource {}

class MockScanHistoryLocalDataSource extends Mock
    implements ScanHistoryLocalDataSource {}

void main() {
  late ScanRepositoryImpl repository;
  late MockQrScannerNativeDataSource mockNativeDataSource;
  late MockScanHistoryLocalDataSource mockLocalDataSource;

  setUp(() {
    mockNativeDataSource = MockQrScannerNativeDataSource();
    mockLocalDataSource = MockScanHistoryLocalDataSource();
    repository = ScanRepositoryImpl(
      nativeDataSource: mockNativeDataSource,
      localDataSource: mockLocalDataSource,
    );
    // Fallback si es necesario para otros métodos del repo que se prueben aquí
    const DateTime time = ConstDateTime(2025, 10, 27, 12, 34, 56, 789, 10);
    registerFallbackValue(
      const ScanResult(content: '', timestamp: time),
    ); // O un ScanResult válido
    registerFallbackValue(Uri()); // O lo que sea necesario
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
  final tException = Exception('DataSource Error');

  group('startQrScan', () {
    test(
      'should return Right(QrScanResult) when native data source succeeds',
      () async {
        // arrange
        when(
          () => mockNativeDataSource.scanQrCode(),
        ).thenAnswer((_) async => tSuccessQrScanResult);

        // act
        final result = await repository.startQrScan();

        // assert
        expect(result, Right(tSuccessQrScanResult));
        verify(() => mockNativeDataSource.scanQrCode()).called(1);
        verifyNoMoreInteractions(mockNativeDataSource);
        verifyZeroInteractions(
          mockLocalDataSource,
        ); // No debe interactuar con el local
      },
    );

    test(
      'should return Right(QrScanResult) when native data source returns cancelled',
      () async {
        // arrange
        when(
          () => mockNativeDataSource.scanQrCode(),
        ).thenAnswer((_) async => tCancelledQrScanResult);
        // act
        final result = await repository.startQrScan();
        // assert
        expect(result, Right(tCancelledQrScanResult));
        verify(() => mockNativeDataSource.scanQrCode()).called(1);
        verifyNoMoreInteractions(mockNativeDataSource);
        verifyZeroInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return Right(QrScanResult) when native data source returns error',
      () async {
        // arrange
        when(
          () => mockNativeDataSource.scanQrCode(),
        ).thenAnswer((_) async => tErrorQrScanResult);
        // act
        final result = await repository.startQrScan();
        // assert
        expect(result, Right(tErrorQrScanResult));
        verify(() => mockNativeDataSource.scanQrCode()).called(1);
        verifyNoMoreInteractions(mockNativeDataSource);
        verifyZeroInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return Left(NativeCallFailure) when native data source throws',
      () async {
        // arrange
        when(() => mockNativeDataSource.scanQrCode()).thenThrow(tException);

        // act
        final result = await repository.startQrScan();

        // assert
        expect(
          result,
          Left(
            NativeCallFailure(
              'Error al iniciar escaneo nativo: ${tException.toString()}',
            ),
          ),
        );
        verify(() => mockNativeDataSource.scanQrCode()).called(1);
        verifyNoMoreInteractions(mockNativeDataSource);
        verifyZeroInteractions(mockLocalDataSource);
      },
    );
  });

  // Puedes añadir aquí grupos de pruebas para saveScanResult y getScanHistory
  // mockeando mockLocalDataSource de forma similar.
}
