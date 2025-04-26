part of 'auth_bloc.dart'; // Usa 'part of' para vincular con auth_bloc.dart

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Estado inicial, antes de verificar nada
class AuthInitial extends AuthState {}

// Estado mientras se verifica el estado inicial o se procesa una autenticación
class AuthLoading extends AuthState {
  final bool isPinSet;
  const AuthLoading({required this.isPinSet});
  @override
  List<Object?> get props => [isPinSet];
}

// Estado después de la verificación inicial
class AuthStatusKnown extends AuthState {
  final bool isPinSet;
  final bool isBiometricAvailable; // Lo añadiremos luego

  const AuthStatusKnown({
    required this.isPinSet,
    this.isBiometricAvailable = false,
  });

  @override
  List<Object?> get props => [isPinSet, isBiometricAvailable];
}

// Estado para indicar que se debe mostrar el BottomSheet del PIN
class AuthShowPinSheet extends AuthState {
  final bool isCreatingPin; // true si no hay PIN, false si ya existe uno
  final bool isPinSet;

  const AuthShowPinSheet({required this.isCreatingPin, required this.isPinSet});
  @override
  List<Object?> get props => [isCreatingPin, isPinSet];
}

// Estado cuando la autenticación (PIN o Biometría) fue exitosa
class AuthAuthenticated extends AuthState {}

// Estado cuando ocurrió un error durante la autenticación o verificación
class AuthFailure extends AuthState {
  final String message;
  final bool isPinSet;
  const AuthFailure(this.message, {required this.isPinSet});
  @override
  List<Object?> get props => [message, isPinSet];
}

// Estado cuando el PIN introducido es incorrecto
class AuthPinIncorrect extends AuthState {
  final bool isPinSet;
  const AuthPinIncorrect({required this.isPinSet});
  @override
  List<Object?> get props => [isPinSet];
}

// TODO: Añadir estados para flujo de biometría (ej. AuthBiometricNotAvailable)
