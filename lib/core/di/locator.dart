import 'package:get_it/get_it.dart';
import 'package:qr_scanner_app/data/datasources/native/secure_storage_native_datasource.dart';
import 'package:qr_scanner_app/data/repositories/auth_repository_impl.dart';
import 'package:qr_scanner_app/domain/repositories/auth_repository.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';

final locator = GetIt.instance;

void setupLocator() {
  // --- BLoCs ---
  // Factory porque queremos una nueva instancia cada vez que se necesite (o cuando se navega a la pantalla)
  // O Singleton si quieres que el estado persista mientras la app vive. Para Auth, Singleton suele ser mejor.
  locator.registerSingleton<AuthBloc>(
    AuthBloc(
      checkPinExists: locator(),
      savePin: locator(),
      verifyPin: locator(),
      // Añade dependencias de biometría aquí
    ),
  );

  // --- Use Cases ---
  // Normalmente son Singleton o LazySingleton
  locator.registerLazySingleton(() => CheckPinExists(locator()));
  locator.registerLazySingleton(() => SavePin(locator()));
  locator.registerLazySingleton(() => VerifyPin(locator()));
  // Registra use cases de biometría

  // --- Repositories ---
  // LazySingleton para crear la instancia solo cuando se use por primera vez
  locator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(nativeDataSource: locator()),
  );

  // --- Data Sources ---
  locator.registerLazySingleton<SecureStorageNativeDataSource>(
    () => SecureStorageNativeDataSourceImpl(locator()),
  );
  // Registra otros datasources (Biometric, QR Scanner)

  // --- Pigeon APIs (Native Clients) ---
  // Registra los clientes generados por Pigeon. Son clases simples, Singleton está bien.
  locator.registerLazySingleton<SecureStorageApi>(() => SecureStorageApi());
  //locator.registerLazySingleton<BiometricApi>(() => BiometricApi());
  //locator.registerLazySingleton<QrScannerApi>(() => QrScannerApi());
}
