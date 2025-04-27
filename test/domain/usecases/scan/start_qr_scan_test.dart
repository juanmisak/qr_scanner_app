import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/data/repositories/scan_repository_impl.dart';
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';
import 'package:qr_scanner_app/domain/usecases/scan/start_qr_scan.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';

// Mock para el Repositorio
class MockScanRepository extends Mock implements ScanRepository {}

void main() {
  late StartQrScan usecase;
  late MockScanRepository mockScanRepository;

  setUp(() {
    mockScanRepository = MockScanRepository();
    usecase = StartQrScan(mockScanRepository);
  });

  final tSuccessQrScanResult = QrScanResult(
    code: 'test_code',
    cancelled: false,
  );
  const tFailure = NativeCallFailure('Repo Error');

  test(
    'should call ScanRepository.startQrScan and return its result',
    () async {
      // arrange
      when(
        () => mockScanRepository.startQrScan(),
      ).thenAnswer((_) async => Right(tSuccessQrScanResult));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, Right(tSuccessQrScanResult));
      verify(() => mockScanRepository.startQrScan()).called(1);
      verifyNoMoreInteractions(mockScanRepository);
    },
  );

  test(
    'should call ScanRepository.startQrScan and return its failure',
    () async {
      // arrange
      when(
        () => mockScanRepository.startQrScan(),
      ).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await usecase(NoParams());

      // assert
      expect(result, const Left(tFailure));
      verify(() => mockScanRepository.startQrScan()).called(1);
      verifyNoMoreInteractions(mockScanRepository);
    },
  );
}
