part of 'auth_bloc.dart'; // Usa 'part of' para vincular con auth_bloc.dart

abstract class AuthState extends Equatable {
  final bool? isPinSet;
  final bool? isBiometricAvailable;

  const AuthState({this.isPinSet, this.isBiometricAvailable});

  @override
  List<Object?> get props => [isPinSet, isBiometricAvailable];
}

// Estado inicial, antes de verificar nada
class AuthInitial extends AuthState {
  const AuthInitial() : super(isPinSet: null, isBiometricAvailable: null);
}

// Cargando, pero sabemos el estado previo
class AuthLoading extends AuthState {
  const AuthLoading({
    required bool isPinSet,
    required bool isBiometricAvailable,
  }) : super(isPinSet: isPinSet, isBiometricAvailable: isBiometricAvailable);
}

// Estado conocido después de la verificación inicial
class AuthStatusKnown extends AuthState {
  const AuthStatusKnown({
    required bool isPinSet,
    required bool isBiometricAvailable,
  }) : super(isPinSet: isPinSet, isBiometricAvailable: isBiometricAvailable);
}

// Estado para indicar que se debe mostrar el BottomSheet del PIN
class AuthShowPinSheet extends AuthState {
  final bool isCreatingPin;

  const AuthShowPinSheet({
    required this.isCreatingPin,
    required bool isPinSet,
    required bool isBiometricAvailable,
  }) : super(isPinSet: isPinSet, isBiometricAvailable: isBiometricAvailable);
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated() : super(isPinSet: null, isBiometricAvailable: null);
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(
    this.message, {
    required bool isPinSet,
    required bool isBiometricAvailable,
  }) : super(isPinSet: isPinSet, isBiometricAvailable: isBiometricAvailable);

  @override
  List<Object?> get props => [isPinSet, isBiometricAvailable, message];
}

// PIN Incorrecto, necesitamos saber el estado de fondo
class AuthPinIncorrect extends AuthState {
  const AuthPinIncorrect({
    required bool isPinSet,
    required bool isBiometricAvailable,
  }) : super(isPinSet: isPinSet, isBiometricAvailable: isBiometricAvailable);
}
