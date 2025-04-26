part of 'auth_bloc.dart'; // Usa 'part of' para vincular con auth_bloc.dart

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Estado inicial, antes de verificar nada
class AuthInitial extends AuthState {}

// Estado mientras se verifica el estado inicial o se procesa una autenticación
class AuthLoading extends AuthState {}

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

  const AuthShowPinSheet({required this.isCreatingPin});

  @override
  List<Object?> get props => [isCreatingPin];
}

// Estado cuando la autenticación (PIN o Biometría) fue exitosa
class AuthAuthenticated extends AuthState {}

// Estado cuando ocurrió un error durante la autenticación o verificación
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// Estado cuando el PIN introducido es incorrecto
class AuthPinIncorrect extends AuthState {}

// TODO: Añadir estados para flujo de biometría (ej. AuthBiometricNotAvailable)
