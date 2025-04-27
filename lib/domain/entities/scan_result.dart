import 'package:equatable/equatable.dart';

class ScanResult extends Equatable {
  final int? id; // Nullable si aún no se ha guardado en la DB
  final String content;
  final DateTime timestamp;

  const ScanResult({this.id, required this.content, required this.timestamp});

  @override
  List<Object?> get props => [id, content, timestamp];
}
