part of 'auth_bloc.dart'; // Usa 'part of' para vincular con auth_bloc.dart

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Evento inicial para verificar el estado (PIN existe? Biometría disponible?)
class AuthStatusChecked extends AuthEvent {}

// Evento para solicitar el inicio de sesión con PIN (mostrar BottomSheet)
class PinAuthRequested extends AuthEvent {}

// Evento para solicitar el inicio de sesión con Biometría
class BiometricAuthRequested extends AuthEvent {}

// Evento cuando se ingresa un PIN completo (ya sea creando o verificando)
class PinSubmitted extends AuthEvent {
  final String pin;
  const PinSubmitted(this.pin);
  @override
  List<Object?> get props => [pin];
}

// Evento para cancelar la operación del PIN
class PinAuthCancelled extends AuthEvent {}

// TODO: Añadir eventos para flujo de biometría
