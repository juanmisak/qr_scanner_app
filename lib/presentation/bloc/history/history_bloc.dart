import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart';
import 'package:qr_scanner_app/domain/usecases/scan/get_scan_history.dart';

part '../history/history_event.dart';
part '../history/history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistory getScanHistory;

  HistoryBloc({required this.getScanHistory}) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    final failureOrScans = await getScanHistory(NoParams());
    failureOrScans.fold((failure) => emit(HistoryFailure(failure.message)), (
      scans,
    ) {
      if (scans.isEmpty) {
        emit(HistoryEmpty());
      } else {
        emit(HistoryLoaded(scans));
      }
    });
  }
}
