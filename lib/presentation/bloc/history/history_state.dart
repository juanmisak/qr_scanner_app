part of 'history_bloc.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object> get props => [];
}

// Estado inicial, antes de cargar nada
class HistoryInitial extends HistoryState {}

// Estado mientras se carga el historial desde la DB
class HistoryLoading extends HistoryState {}

// Estado cuando el historial se cargó exitosamente y contiene datos
class HistoryLoaded extends HistoryState {
  final List<ScanResult> scans;

  const HistoryLoaded(this.scans);

  @override
  List<Object> get props => [scans];
}

// Estado cuando el historial se cargó, pero está vacío
class HistoryEmpty extends HistoryState {}

// Estado cuando ocurrió un error al cargar el historial
class HistoryFailure extends HistoryState {
  final String message;

  const HistoryFailure(this.message);

  @override
  List<Object> get props => [message];
}
