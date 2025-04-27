import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:qr_scanner_app/core/usecase/usecase.dart';
import 'package:qr_scanner_app/domain/entities/scan_result.dart' as domain;
import 'package:qr_scanner_app/domain/usecases/scan/save_scan_result.dart';
import 'package:qr_scanner_app/domain/usecases/scan/start_qr_scan.dart';

part '../scanner/scanner_event.dart';
part '../scanner/scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  final StartQrScan startQrScan;
  final SaveScanResult saveScanResult;

  ScannerBloc({required this.startQrScan, required this.saveScanResult})
    : super(ScannerInitial()) {
    on<ScanRequested>(_onScanRequested);
    on<_SaveScanRequested>(_onSaveScanRequested);
  }

  Future<void> _onScanRequested(
    ScanRequested event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScannerLoading());
    final failureOrScanResult = await startQrScan(NoParams());

    await failureOrScanResult.fold(
      (failure) async => emit(ScanFailure(failure.message)),
      (qrScanResult) async {
        if (qrScanResult.cancelled == true) {
          emit(ScanCancelled());
          // Vuelve al estado inicial después de un momento
          await Future.delayed(const Duration(milliseconds: 500));
          if (state is ScanCancelled) emit(ScannerInitial());
        } else if (qrScanResult.error != null) {
          emit(ScanFailure("Error del escáner nativo: ${qrScanResult.error}"));
        } else if (qrScanResult.code != null && qrScanResult.code!.isNotEmpty) {
          // Éxito - Primero emite éxito del escaneo
          emit(ScanSuccess(qrScanResult.code!));
          // Luego dispara el evento para guardar (podría hacerse vía listener en UI también)
          add(_SaveScanRequested(qrScanResult.code!));
        } else {
          emit(ScanFailure("Resultado de escaneo inválido recibido."));
        }
      },
    );
  }

  Future<void> _onSaveScanRequested(
    _SaveScanRequested event,
    Emitter<ScannerState> emit,
  ) async {
    emit(ScanSaveInProgress(event.code)); // Muestra que se está guardando
    final scanToSave = domain.ScanResult(
      content: event.code,
      timestamp: DateTime.now(),
    );
    final failureOrId = await saveScanResult(SaveScanParams(scan: scanToSave));

    failureOrId.fold(
      (failure) {
        // Error al guardar, pero el escaneo fue exitoso
        print("Error guardando escaneo: ${failure.message}");
        emit(
          ScanSaveFailure(event.code, failure.message),
        ); // Estado de fallo específico de guardado
        // Podrías volver a ScanSuccess o Initial después de un delay
        Future.delayed(const Duration(seconds: 2), () {
          if (state is ScanSaveFailure) {
            emit(ScanSuccess(event.code)); // Vuelve a mostrar éxito del scan
          }
        });
      },
      (id) {
        print("Escaneo guardado con ID: $id");
        emit(ScanSaveSuccess(event.code)); // Guardado exitoso
        // Podrías volver a Initial después de un delay
        Future.delayed(const Duration(seconds: 1), () {
          if (state is ScanSaveSuccess) emit(ScannerInitial());
        });
      },
    );
  }
}
