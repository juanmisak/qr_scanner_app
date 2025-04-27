import 'package:get_it/get_it.dart';
import 'package:qr_scanner_app/data/datasources/native/biometric_native_datasource.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_biometric_support.dart';
import 'package:qr_scanner_app/domain/usecases/auth/authenticate_with_biometrics.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/auth_repository_impl.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Asegúrate que esta es la importación correcta para SecureStorageApi
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:qr_scanner_app/data/datasources/local/scan_history_local_datasource.dart';
import 'package:qr_scanner_app/data/datasources/native/qr_scanner_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/scan_repository_impl.dart';
import 'package:qr_scanner_app/domain/repositories/scan_repository.dart';
import 'package:qr_scanner_app/domain/usecases/scan/get_scan_history.dart';
import 'package:qr_scanner_app/domain/usecases/scan/save_scan_result.dart';
import 'package:qr_scanner_app/domain/usecases/scan/start_qr_scan.dart';
import 'package:qr_scanner_app/presentation/bloc/history/history_bloc.dart';
import 'package:qr_scanner_app/presentation/bloc/scanner/scanner_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  // --- PRIMERO: Dependencias más básicas (Pigeon APIs / Clientes Nativos) ---
  locator.registerLazySingleton<SecureStorageApi>(() => SecureStorageApi());
  locator.registerLazySingleton<BiometricApi>(() => BiometricApi());
  locator.registerLazySingleton<QrScannerApi>(() => QrScannerApi());

  // --- SEGUNDO: Data Sources (Dependen de Pigeon APIs) ---
  locator.registerLazySingleton<SecureStorageNativeDataSource>(
    () => SecureStorageNativeDataSourceImpl(locator<SecureStorageApi>()),
  );
  locator.registerLazySingleton<BiometricNativeDataSource>(
    () => BiometricNativeDataSourceImpl(locator<BiometricApi>()),
  );
  locator.registerLazySingleton<QrScannerNativeDataSource>(
    () => QrScannerNativeDataSourceImpl(locator<QrScannerApi>()),
  );
  locator.registerLazySingleton<ScanHistoryLocalDataSource>(
    () => ScanHistoryLocalDataSourceImpl(),
  );

  // --- TERCERO: Repositories (Dependen de Data Sources) ---
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      biometricDataSource: locator<BiometricNativeDataSource>(),
      secureStorageDataSource: locator<SecureStorageNativeDataSource>(),
    ),
  );
  locator.registerLazySingleton<ScanRepository>(
    () => ScanRepositoryImpl(
      nativeDataSource: locator<QrScannerNativeDataSource>(),
      localDataSource: locator<ScanHistoryLocalDataSource>(),
    ),
  );

  // --- CUARTO: Use Cases (Dependen de Repositories) ---
  // Registra cases de PIN auth
  locator.registerLazySingleton(
    () => CheckPinExists(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(() => SavePin(locator<AuthRepository>()));
  locator.registerLazySingleton(() => VerifyPin(locator<AuthRepository>()));
  // Registra use cases de biometría
  locator.registerLazySingleton(
    () => CheckBiometricSupport(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => AuthenticateWithBiometrics(locator<AuthRepository>()),
  );
  // Registra use cases de Scanner
  locator.registerLazySingleton(
    () => GetScanHistory(locator<ScanRepository>()),
  );
  locator.registerLazySingleton(() => StartQrScan(locator<ScanRepository>()));
  locator.registerLazySingleton(
    () => SaveScanResult(locator<ScanRepository>()),
  );

  // --- QUINTO: BLoCs (Dependen de Use Cases) ---
  locator.registerSingleton<AuthBloc>(
    AuthBloc(
      checkPinExists: locator<CheckPinExists>(),
      savePin: locator<SavePin>(),
      verifyPin: locator<VerifyPin>(),
      checkBiometricSupport: locator<CheckBiometricSupport>(),
      authenticateWithBiometrics: locator<AuthenticateWithBiometrics>(),
    ),
  );
  locator.registerFactory<HistoryBloc>(
    () => HistoryBloc(getScanHistory: locator<GetScanHistory>()),
  );
  locator.registerFactory<ScannerBloc>(
    () => ScannerBloc(
      startQrScan: locator<StartQrScan>(),
      saveScanResult: locator<SaveScanResult>(),
    ),
  );
}
