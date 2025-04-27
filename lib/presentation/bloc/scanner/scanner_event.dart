part of 'scanner_bloc.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object> get props => [];
}

// Evento disparado por la UI para iniciar el escaneo
class ScanRequested extends ScannerEvent {}

// Evento interno (o desde listener) para solicitar el guardado del código escaneado
// Es _ privado porque no debería ser añadido directamente por la UI en este diseño.
class _SaveScanRequested extends ScannerEvent {
  final String code;
  const _SaveScanRequested(this.code);
  @override
  List<Object> get props => [code];
}
