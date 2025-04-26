import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/usecases/auth/check_pin_exists.dart';
import 'package:qr_scanner_app/domain/usecases/auth/save_pin.dart';
import 'package:qr_scanner_app/domain/usecases/auth/verify_pin.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckPinExists checkPinExists;
  final SavePin savePin;
  final VerifyPin verifyPin;

  bool _currentPinIsSet = false;

  AuthBloc({
    required this.checkPinExists,
    required this.savePin,
    required this.verifyPin,
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
    emit(AuthLoading(isPinSet: _currentPinIsSet));
    final pinExistsResult = await checkPinExists(NoParams());

    pinExistsResult.fold(
      (failure) =>
          emit(AuthFailure(failure.message, isPinSet: _currentPinIsSet)),
      (pinExists) {
        _currentPinIsSet = pinExists;
        emit(
          AuthStatusKnown(
            isPinSet: _currentPinIsSet /* isBiometricAvailable: ... */,
          ),
        );
      },
    );
  }

  void _onPinAuthRequested(PinAuthRequested event, Emitter<AuthState> emit) {
    emit(
      AuthShowPinSheet(
        isCreatingPin: !_currentPinIsSet,
        isPinSet: _currentPinIsSet,
      ),
    );
  }

  Future<void> _onPinSubmitted(
    PinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(isPinSet: _currentPinIsSet));

    if (_currentPinIsSet) {
      // --- Verificar PIN existente ---
      final result = await verifyPin(VerifyPinParams(pin: event.pin));
      // 'await' aquí asegura que esperamos el resultado de la verificación
      result.fold(
        (failure) =>
            emit(AuthFailure(failure.message, isPinSet: _currentPinIsSet)),
        // Este callback (lambda) también debe ser 'async' si usa 'await' adentro
        (isCorrect) async {
          // <-- MARCA ESTE LAMBDA COMO ASYNC
          if (isCorrect) {
            emit(AuthAuthenticated());
          } else {
            // PIN Incorrecto
            emit(AuthPinIncorrect(isPinSet: _currentPinIsSet));
            // AHORA SÍ: Espera a que el retraso termine ANTES de continuar
            await Future.delayed(
              const Duration(milliseconds: 500),
            ); // <-- AÑADE AWAIT AQUÍ

            // Después del retraso, verifica si el estado sigue siendo el esperado (buena práctica)
            // y luego emite el nuevo estado. Como hemos esperado, el manejador sigue activo.
            if (!emit.isDone) {
              // Es buena práctica comprobar si el emitter sigue activo
              // Comprueba el estado actual por si acaso algo más lo cambió durante el delay
              if (state is AuthPinIncorrect) {
                emit(
                  AuthShowPinSheet(
                    isCreatingPin: false,
                    isPinSet: _currentPinIsSet,
                  ),
                );
              }
            }
          }
        },
      );
    } else {
      // --- Crear nuevo PIN ---
      final result = await savePin(SavePinParams(pin: event.pin));
      result.fold(
        (failure) =>
            emit(AuthFailure(failure.message, isPinSet: _currentPinIsSet)),
        (_) {
          _currentPinIsSet = true; // Actualiza el estado interno
          // Podrías re-emitir AuthStatusKnown o directamente ir a AuthAuthenticated
          // O quizás volver a la pantalla inicial para que el usuario inicie sesión
          emit(
            AuthStatusKnown(isPinSet: _currentPinIsSet),
          ); // Vuelve al estado conocido
          // Podrías mostrar un SnackBar indicando "PIN Creado" en la UI
        },
      );
    }
  }

  void _onPinAuthCancelled(PinAuthCancelled event, Emitter<AuthState> emit) {
    // Simplemente vuelve al estado conocido anterior
    emit(AuthStatusKnown(isPinSet: _currentPinIsSet));
  }

  Future<void> _onBiometricAuthRequested(
    BiometricAuthRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading(isPinSet: _currentPinIsSet));
    // TODO: Implementar llamada al UseCase de biometría
    // final result = await authenticateWithBiometrics(NoParams());
    // result.fold(
    //   (failure) => emit(AuthFailure(failure.message)),
    //   (success) {
    //      if (success) {
    //          emit(AuthAuthenticated());
    //      } else {
    //          // Podría ser cancelado por el usuario o fallo real
    //          emit(AuthStatusKnown(isPinSet: _currentPinIsSet, /* isBiometricAvailable: ... */)); // Vuelve al estado conocido
    //      }
    //   }
    // );
    // Placeholder:
    await Future.delayed(const Duration(seconds: 1)); // Simula carga
    emit(
      AuthFailure("Biometría no implementada aún", isPinSet: _currentPinIsSet),
    ); // Temporal
    await Future.delayed(const Duration(seconds: 2));
    emit(
      AuthStatusKnown(isPinSet: _currentPinIsSet),
    ); // Vuelve al estado conocido
  }
}
