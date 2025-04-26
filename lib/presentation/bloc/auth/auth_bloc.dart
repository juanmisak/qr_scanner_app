// ignore_for_file: avoid_print

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:qr_scanner_app/core/error/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_biometric_support.dart';
import 'package:qr_scanner_app/pigeon/messages.dart';
import 'package:qr_scanner_app/domain/usecases/auth/authenticate_with_biometrics.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckPinExists checkPinExists;
  final SavePin savePin;
  final VerifyPin verifyPin;
  final CheckBiometricSupport checkBiometricSupport;
  final AuthenticateWithBiometrics authenticateWithBiometrics;
  bool _currentPinIsSet = false;
  bool _currentBiometricSupported = false;

  AuthBloc({
    required this.checkPinExists,
    required this.savePin,
    required this.verifyPin,
    required this.checkBiometricSupport,
    required this.authenticateWithBiometrics,
  }) : super(AuthInitial()) {
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<PinAuthRequested>(_onPinAuthRequested);
    on<BiometricAuthRequested>(_onBiometricAuthRequested);
    on<PinSubmitted>(_onPinSubmitted);
    on<PinAuthCancelled>(_onPinAuthCancelled);
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      AuthLoading(
        isPinSet: _currentPinIsSet,
        isBiometricAvailable: _currentBiometricSupported,
      ),
    );
    final pinExistsFuture = checkPinExists(NoParams());
    final biometricSupportFuture = checkBiometricSupport(NoParams());

    final results = await Future.wait([
      pinExistsFuture,
      biometricSupportFuture,
    ]);

    final pinExistsResult = results[0];
    final biometricSupportResult = results[1];

    Failure? checkFailure;
    // Usa los valores internos como fallback en caso de error en la comprobación
    bool finalPinExists = _currentPinIsSet;
    bool finalBiometricSupported = _currentBiometricSupported;

    pinExistsResult.fold(
      (failure) => checkFailure ??= failure,
      (pinExists) => finalPinExists = pinExists,
    );
    biometricSupportResult.fold(
      (failure) => checkFailure ??= failure,
      (supported) =>
          finalBiometricSupported = supported, // <-- Guarda el resultado
    );

    if (checkFailure != null) {
      emit(
        AuthFailure(
          checkFailure!.message,
          isPinSet: finalPinExists,
          isBiometricAvailable: finalBiometricSupported,
        ),
      );
    } else {
      _currentPinIsSet = finalPinExists;
      _currentBiometricSupported = finalBiometricSupported;
      emit(
        AuthStatusKnown(
          isPinSet: _currentPinIsSet,
          isBiometricAvailable: _currentBiometricSupported,
        ),
      );
    }
  }
  // Dentro de la clase AuthBloc

  Future<void> _onBiometricAuthRequested(
    BiometricAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      AuthLoading(
        isPinSet: _currentPinIsSet,
        isBiometricAvailable: _currentBiometricSupported,
      ),
    );

    final result = await authenticateWithBiometrics(
      const AuthenticateWithBiometricsParams(
        reason: "Desbloquea para continuar",
      ),
    );

    result.fold(
      (failure) {
        //<- Caso de error en la llamada (Pigeon/Repo)
        emit(
          AuthFailure(
            failure.message,
            isPinSet: _currentPinIsSet,
            isBiometricAvailable: _currentBiometricSupported,
          ),
        );
        _scheduleReturnToKnownState(emit);
      },
      (biometricResult) {
        //<- Caso de éxito en la llamada (recibimos BiometricResult)
        // AGREGAR LOG PARA VER EL STATUS RECIBIDO:
        print(
          "AuthBloc: Received BiometricResult with status: ${biometricResult.status}",
        );

        if (biometricResult.status == BiometricAuthStatus.success) {
          print("AuthBloc: Biometric status is success.");
          emit(const AuthAuthenticated());
        } else if (biometricResult.status ==
            BiometricAuthStatus.errorUserCanceled) {
          // <-- ¿Está entrando aquí?
          print(
            "AuthBloc: Biometric status is errorUserCanceled. Showing PIN sheet.",
          );
          emit(
            AuthShowPinSheet(
              isCreatingPin: !_currentPinIsSet,
              isPinSet: _currentPinIsSet,
              isBiometricAvailable: _currentBiometricSupported,
            ),
          );
        } else {
          // <-- ¡ESTÁ ENTRANDO AQUÍ INCORRECTAMENTE!
          final errorMessage =
              biometricResult.errorMessage ??
              "Falló la autenticación biométrica (${biometricResult.status.name})";
          print(
            "AuthBloc: Biometric status is other failure ($errorMessage). Emitting AuthFailure.",
          ); // Este es el log que ves
          emit(
            AuthFailure(
              errorMessage,
              isPinSet: _currentPinIsSet,
              isBiometricAvailable: _currentBiometricSupported,
            ),
          );
          _scheduleReturnToKnownState(emit);
        }
      },
    );
  }

  // Helper para volver al estado conocido después de un fallo temporal (NO usar para cancelación)
  void _scheduleReturnToKnownState(Emitter<AuthState> emit) {
    Future.delayed(const Duration(seconds: 2), () {
      // Solo vuelve si AÚN estamos en un estado de fallo relevante
      final currentState = state; // Captura el estado actual
      if (!emit.isDone &&
          (currentState is AuthFailure ||
              currentState
                  is AuthLoading /*u otros estados temporales si los hubiera*/ )) {
        ("Volviendo a AuthStatusKnown desde $currentState");
        emit(
          AuthStatusKnown(
            isPinSet: _currentPinIsSet,
            isBiometricAvailable: _currentBiometricSupported,
          ),
        );
      }
    });
  }

  void _onPinAuthRequested(PinAuthRequested event, Emitter<AuthState> emit) {
    emit(
      AuthShowPinSheet(
        isCreatingPin: !_currentPinIsSet,
        isPinSet: _currentPinIsSet,
        isBiometricAvailable: _currentBiometricSupported,
      ),
    );
  }

  Future<void> _onPinSubmitted(
    PinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(
      AuthLoading(
        isPinSet: _currentPinIsSet,
        isBiometricAvailable: _currentBiometricSupported,
      ),
    ); // Pasa el estado actual
    // ... (resto de la lógica de _onPinSubmitted, asegurándose de pasar isPinSet a AuthFailure y AuthPinIncorrect) ...
    if (_currentPinIsSet) {
      // --- Verificar PIN existente ---
      final result = await verifyPin(VerifyPinParams(pin: event.pin));
      result.fold(
        (failure) => emit(
          AuthFailure(
            failure.message,
            isPinSet: _currentPinIsSet,
            isBiometricAvailable: _currentBiometricSupported,
          ),
        ),
        (isCorrect) async {
          if (isCorrect) {
            emit(AuthAuthenticated());
          } else {
            emit(
              AuthPinIncorrect(
                isPinSet: _currentPinIsSet,
                isBiometricAvailable: _currentBiometricSupported,
              ),
            ); // Pasa isPinSet
            await Future.delayed(const Duration(milliseconds: 500));
            if (!emit.isDone && state is AuthPinIncorrect) {
              emit(
                AuthShowPinSheet(
                  isCreatingPin: false,
                  isPinSet: _currentPinIsSet,
                  isBiometricAvailable: _currentBiometricSupported,
                ),
              );
            }
          }
        },
      );
    } else {
      // --- Crear nuevo PIN ---
      final result = await savePin(SavePinParams(pin: event.pin));
      result.fold(
        (failure) => emit(
          AuthFailure(
            failure.message,
            isPinSet: _currentPinIsSet,
            isBiometricAvailable: _currentBiometricSupported,
          ),
        ),
        (_) {
          _currentPinIsSet = true;
          // Vuelve al estado conocido, que ya incluye la info biométrica actualizada antes
          emit(
            AuthStatusKnown(
              isPinSet: _currentPinIsSet,
              isBiometricAvailable: _currentBiometricSupported,
            ),
          );
        },
      );
    }
  }

  void _onPinAuthCancelled(PinAuthCancelled event, Emitter<AuthState> emit) {
    emit(
      AuthStatusKnown(
        isPinSet: _currentPinIsSet,
        isBiometricAvailable: _currentBiometricSupported,
      ),
    );
  }
}
