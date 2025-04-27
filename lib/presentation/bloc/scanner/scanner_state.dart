part of 'scanner_bloc.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => []; // Permite null si alguna propiedad lo es
}

// Estado inicial, listo para escanear
class ScannerInitial extends ScannerState {}

// Estado mientras se inicia el escáner nativo o se espera el resultado
class ScannerLoading extends ScannerState {}

// Estado cuando el escaneo nativo fue exitoso
class ScanSuccess extends ScannerState {
  final String code;
  const ScanSuccess(this.code);
  @override
  List<Object> get props => [code];
}

// Estado cuando el usuario canceló el escaneo nativo
class ScanCancelled extends ScannerState {}

// Estado cuando ocurrió un error durante el proceso de escaneo nativo
class ScanFailure extends ScannerState {
  final String message;
  const ScanFailure(this.message);
  @override
  List<Object> get props => [message];
}

// Estado mientras se guarda el resultado del escaneo en la DB
class ScanSaveInProgress extends ScannerState {
  final String code; // Mantenemos el código para mostrarlo si es necesario
  const ScanSaveInProgress(this.code);
  @override
  List<Object> get props => [code];
}

// Estado cuando el guardado en la DB fue exitoso
class ScanSaveSuccess extends ScannerState {
  final String code; // Mantenemos el código para posible feedback
  const ScanSaveSuccess(this.code);
  @override
  List<Object> get props => [code];
}

// Estado cuando falló el guardado en la DB (pero el escaneo fue exitoso)
class ScanSaveFailure extends ScannerState {
  final String code; // El código que se intentó guardar
  final String errorMessage; // El error de la base de datos
  const ScanSaveFailure(this.code, this.errorMessage);
  @override
  List<Object> get props => [code, errorMessage];
}
