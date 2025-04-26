import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/usecases/auth/authenticate_with_biometrics.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_biometric_support.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';

// Mocks para los Use Cases
class MockCheckPinExists extends Mock implements CheckPinExists {}

class MockSavePin extends Mock implements SavePin {}

class MockVerifyPin extends Mock implements VerifyPin {}

class MockCheckBiometricSupport extends Mock implements CheckBiometricSupport {}

class MockAuthenticateWithBiometrics extends Mock
    implements AuthenticateWithBiometrics {}

void main() {
  late AuthBloc authBloc;
  late MockCheckPinExists mockCheckPinExists;
  late MockSavePin mockSavePin;
  late MockVerifyPin mockVerifyPin;
  late MockCheckBiometricSupport mockCheckBiometricSupport;
  late MockAuthenticateWithBiometrics mockAuthenticateWithBiometrics;

  // Datos de prueba
  const tPin = '1234';
  const tCorrectPinParams = VerifyPinParams(pin: tPin);
  const tSavePinParams = SavePinParams(pin: tPin);
  const tAuthBiometricsParams = AuthenticateWithBiometricsParams(
    reason: "Desbloquea para continuar",
  );

  final tSuccessBiometricResult = BiometricResult(
    status: BiometricAuthStatus.success,
  );
  final tCancelBiometricResult = BiometricResult(
    status: BiometricAuthStatus.errorUserCanceled,
  );
  final tFailureBiometricResult = BiometricResult(
    status: BiometricAuthStatus.failure,
    errorMessage: 'Bio Failed',
  );
  final tGenericFailure = GenericFailure(
    'Something went wrong',
  ); // Define un Failure genérico si quieres

  // Función auxiliar para configurar stubs comunes
  void setupInitialChecks({
    required bool pinExistsResult,
    required bool biometricSupportResult,
    Failure? pinFailure,
    Failure? biometricFailure,
  }) {
    when(() => mockCheckPinExists(any())).thenAnswer(
      (_) async =>
          pinFailure != null ? Left(pinFailure) : Right(pinExistsResult),
    );
    when(() => mockCheckBiometricSupport(any())).thenAnswer(
      (_) async => biometricFailure != null
          ? Left(biometricFailure)
          : Right(biometricSupportResult),
    );
  }

  setUp(() {
    mockCheckPinExists = MockCheckPinExists();
    mockSavePin = MockSavePin();
    mockVerifyPin = MockVerifyPin();
    mockCheckBiometricSupport = MockCheckBiometricSupport();
    mockAuthenticateWithBiometrics = MockAuthenticateWithBiometrics();

    // Registra fallbacks para los Params si usas any()
    registerFallbackValue(NoParams());
    registerFallbackValue(tSavePinParams);
    registerFallbackValue(tCorrectPinParams);
    registerFallbackValue(tAuthBiometricsParams);

    authBloc = AuthBloc(
      checkPinExists: mockCheckPinExists,
      savePin: mockSavePin,
      verifyPin: mockVerifyPin,
      checkBiometricSupport: mockCheckBiometricSupport,
      authenticateWithBiometrics: mockAuthenticateWithBiometrics,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state should be AuthInitial', () {
    expect(authBloc.state, const AuthInitial());
  });

  group('AuthStatusChecked', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthStatusKnown] when checks succeed (pin set, bio supported)',
      setUp: () => setupInitialChecks(
        pinExistsResult: true,
        biometricSupportResult: true,
      ),
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthStatusChecked()),
      expect: () => const <AuthState>[
        AuthLoading(
          isPinSet: false,
          isBiometricAvailable: false,
        ), // Estado inicial antes de saber los resultados
        AuthStatusKnown(isPinSet: true, isBiometricAvailable: true),
      ],
      verify: (_) {
        verify(() => mockCheckPinExists(NoParams())).called(1);
        verify(() => mockCheckBiometricSupport(NoParams())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthStatusKnown] when checks succeed (pin not set, bio not supported)',
      setUp: () => setupInitialChecks(
        pinExistsResult: false,
        biometricSupportResult: false,
      ),
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthStatusChecked()),
      expect: () => const <AuthState>[
        AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthStatusKnown(isPinSet: false, isBiometricAvailable: false),
      ],
      verify: (_) {
        verify(() => mockCheckPinExists(NoParams())).called(1);
        verify(() => mockCheckBiometricSupport(NoParams())).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthFailure] when checkPinExists fails',
      setUp: () => setupInitialChecks(
        pinExistsResult: true,
        biometricSupportResult: true,
        pinFailure: tGenericFailure,
      ),
      build: () => authBloc,
      act: (bloc) => bloc.add(AuthStatusChecked()),
      expect: () => <AuthState>[
        const AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthFailure(
          tGenericFailure.message,
          isPinSet: false,
          isBiometricAvailable: true,
        ),
      ],
      verify: (_) {
        verify(() => mockCheckPinExists(NoParams())).called(1);
        verify(() => mockCheckBiometricSupport(NoParams())).called(1);
      },
    );

    // Añade prueba similar para fallo de checkBiometricSupport
  });

  group('PinAuthRequested', () {
    // Primero establece el estado conocido
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthShowPinSheet(isCreatingPin: false)] when PIN is set',
      setUp: () {
        setupInitialChecks(pinExistsResult: true, biometricSupportResult: true);
        // Simula que el estado ya está conocido
        authBloc.emit(
          const AuthStatusKnown(isPinSet: true, isBiometricAvailable: true),
        );
      },
      build: () => authBloc,
      // Emite el estado conocido inicial antes de actuar
      seed: () =>
          const AuthStatusKnown(isPinSet: true, isBiometricAvailable: true),
      act: (bloc) => bloc.add(PinAuthRequested()),
      expect: () => const <AuthState>[
        AuthShowPinSheet(
          isCreatingPin: false,
          isPinSet: false,
          isBiometricAvailable: false,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthShowPinSheet(isCreatingPin: true)] when PIN is not set',
      setUp: () {
        setupInitialChecks(
          pinExistsResult: false,
          biometricSupportResult: true,
        );
      },
      build: () => authBloc,
      seed: () =>
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: true),
      act: (bloc) => bloc.add(PinAuthRequested()),
      expect: () => const <AuthState>[
        AuthShowPinSheet(
          isCreatingPin: true,
          isPinSet: false,
          isBiometricAvailable: false,
        ),
      ],
    );
  });

  group('PinSubmitted (Creating)', () {
    // Asume que el PIN NO está configurado (_currentPinIsSet = false)
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthStatusKnown(isPinSet: true)] when PIN is saved successfully',
      setUp: () {
        authBloc.emit(
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: true),
        );
        when(
          () => mockSavePin(any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: () => authBloc,
      seed: () =>
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: true),
      act: (bloc) => bloc.add(const PinSubmitted(tPin)),
      expect: () => const <AuthState>[
        AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthStatusKnown(
          isPinSet: true,
          isBiometricAvailable: false,
        ), // PIN ahora está puesto
      ],
      verify: (_) => verify(() => mockSavePin(tSavePinParams)).called(1),
    );
  });

  group('BiometricAuthRequested', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthAuthenticated] on biometric success',
      setUp: () {
        authBloc.emit(
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: false),
        );
        when(
          () => mockAuthenticateWithBiometrics(any()),
        ).thenAnswer((_) async => Right(tSuccessBiometricResult));
      },
      build: () => authBloc,
      seed: () =>
          const AuthStatusKnown(isPinSet: true, isBiometricAvailable: true),
      act: (bloc) => bloc.add(BiometricAuthRequested()),
      expect: () => const <AuthState>[
        AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthAuthenticated(),
      ],
      verify: (_) => verify(
        () => mockAuthenticateWithBiometrics(tAuthBiometricsParams),
      ).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthShowPinSheet] on biometric cancel/use PIN',
      setUp: () {
        authBloc.emit(
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: false),
        );
        when(
          () => mockAuthenticateWithBiometrics(any()),
        ).thenAnswer((_) async => Right(tCancelBiometricResult));
      },
      build: () => authBloc,
      seed: () =>
          const AuthStatusKnown(isPinSet: false, isBiometricAvailable: false),
      act: (bloc) => bloc.add(BiometricAuthRequested()),
      expect: () => const <AuthState>[
        AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthShowPinSheet(
          isCreatingPin: false,
          isPinSet: false,
          isBiometricAvailable: false,
        ),
      ],
      verify: (_) => verify(
        () => mockAuthenticateWithBiometrics(tAuthBiometricsParams),
      ).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'should emit [AuthLoading, AuthFailure, AuthStatusKnown] on biometric failure',
      setUp: () {
        // No es necesario emitir aquí si usamos seed
        // authBloc.emit(const AuthStatusKnown(isPinSet: true, isBiometricAvailable: true));
        when(
          () => mockAuthenticateWithBiometrics(any()),
        ).thenAnswer((_) async => Right(tFailureBiometricResult));
      },
      build: () => authBloc,
      // Establece el estado inicial EXTERNO
      seed: () =>
          const AuthStatusKnown(isPinSet: true, isBiometricAvailable: true),
      act: (bloc) => bloc.add(BiometricAuthRequested()),
      // Espera lo suficiente para que el delay de _scheduleReturnToKnownState (2s) termine
      wait: const Duration(seconds: 3), // <-- AÑADE O AJUSTA EL WAIT
      expect: () => <AuthState>[
        const AuthLoading(isPinSet: false, isBiometricAvailable: false),
        AuthFailure(
          tFailureBiometricResult.errorMessage!,
          isPinSet: false,
          isBiometricAvailable: false,
        ),
      ],
      verify: (_) => verify(
        () => mockAuthenticateWithBiometrics(tAuthBiometricsParams),
      ).called(1),
    );
    // Añade prueba para fallo de authenticateWithBiometrics devolviendo Left(Failure)
  });

  group('PinAuthCancelled', () {
    blocTest<AuthBloc, AuthState>(
      'should emit [AuthStatusKnown] reflecting the internally known state when PinAuthCancelled is added', // Mensaje más preciso
      setUp: () {
        // No es necesario emitir aquí si usamos seed.
        // Asegúrate de que el authBloc del scope superior esté inicializado.
      },
      build: () => authBloc, // Usa la instancia creada en el setUp principal
      // Establece el estado ANTES de que act se ejecute
      seed: () => const AuthShowPinSheet(
        isCreatingPin: false,
        isPinSet: true, // Estado externo inicial
        isBiometricAvailable: true, // Estado externo inicial
      ),
      act: (bloc) => bloc.add(PinAuthCancelled()),
      expect: () => const <AuthState>[
        // Espera el estado que el BLoC REALMENTE emitirá,
        // basado en sus campos _current... internos (que son 'false' en esta prueba)
        AuthStatusKnown(isPinSet: false, isBiometricAvailable: false),
      ],
    );
  });
}

class GenericFailure extends Failure {
  const GenericFailure(super.message);
}
