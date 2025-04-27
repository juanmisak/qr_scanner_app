part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object> get props => [];
}

// Evento para solicitar la carga del historial
class LoadHistory extends HistoryEvent {}

// Podrías añadir eventos para eliminar o limpiar si implementas esa funcionalidad
// class DeleteScan extends HistoryEvent {
//   final int id;
//   const DeleteScan(this.id);
//   @override List<Object> get props => [id];
// }
// class ClearHistory extends HistoryEvent {}
