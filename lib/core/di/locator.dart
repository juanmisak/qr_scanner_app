import 'package:get_it/get_it.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/auth_repository_impl.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';
import 'package:qr_scanner_app/pigeon/messages.dart'; // Asegúrate que esta es la importación correcta para SecureStorageApi
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  // --- PRIMERO: Dependencias más básicas (Pigeon APIs / Clientes Nativos) ---
  locator.registerLazySingleton<SecureStorageApi>(() => SecureStorageApi());
  //locator.registerLazySingleton<BiometricApi>(() => BiometricApi());
  //locator.registerLazySingleton<QrScannerApi>(() => QrScannerApi());

  // --- SEGUNDO: Data Sources (Dependen de Pigeon APIs) ---
  locator.registerLazySingleton<SecureStorageNativeDataSource>(
    // Esta función pide locator<SecureStorageApi>() - ¡Ya registrada arriba!
    () => SecureStorageNativeDataSourceImpl(
      locator<SecureStorageApi>(),
    ), // Mejor ser explícito con el tipo
  );
  // Registra otros datasources (Biometric, QR Scanner)

  // --- TERCERO: Repositories (Dependen de Data Sources) ---
  locator.registerLazySingleton<AuthRepository>(
    // Esta función pide locator<SecureStorageNativeDataSource>() - ¡Ya registrada arriba!
    () => AuthRepositoryImpl(
      nativeDataSource: locator<SecureStorageNativeDataSource>(),
    ), // Mejor ser explícito
  );

  // --- CUARTO: Use Cases (Dependen de Repositories) ---
  locator.registerLazySingleton(
    () => CheckPinExists(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(() => SavePin(locator<AuthRepository>()));
  locator.registerLazySingleton(() => VerifyPin(locator<AuthRepository>()));
  // Registra use cases de biometría

  // --- QUINTO: BLoCs (Dependen de Use Cases) ---
  locator.registerSingleton<AuthBloc>(
    AuthBloc(
      checkPinExists: locator<CheckPinExists>(), // Mejor ser explícito
      savePin: locator<SavePin>(),
      verifyPin: locator<VerifyPin>(),
    ),
  );
}
