// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_scanner_app/presentation/bloc/history/history_bloc.dart';
import 'package:qr_scanner_app/presentation/bloc/scanner/scanner_bloc.dart';
import 'package:intl/intl.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  @override
  void initState() {
    super.initState();
    // Carga el historial inicial
    context.read<HistoryBloc>().add(LoadHistory());
  }

  Future<void> _requestCameraPermissionAndScan() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Permiso concedido, inicia el escaneo
      context.read<ScannerBloc>().add(ScanRequested());
    } else if (status.isPermanentlyDenied) {
      // El usuario negó permanentemente, muestra diálogo para ir a ajustes
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Permiso Requerido"),
          content: const Text(
            "Se necesita acceso a la cámara para escanear códigos QR. Por favor, habilita el permiso en los ajustes de la aplicación.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text("Ajustes"),
            ),
          ],
        ),
      );
    } else {
      // Permiso denegado pero no permanentemente
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso de cámara denegado.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Escaneos')),
      body: MultiBlocListener(
        listeners: [
          // Listener para ScannerBloc (resultados, errores de escaneo/guardado)
          BlocListener<ScannerBloc, ScannerState>(
            listener: (context, state) {
              if (state is ScanSuccess) {
                // Muestra el resultado y que se está guardando
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('QR Escaneado: ${state.code}\nGuardando...'),
                  ),
                );
                // El BLoC dispara el guardado internamente
                // Pero necesitamos refrescar el historial DESPUÉS de guardar
              } else if (state is ScanSaveSuccess) {
                ScaffoldMessenger.of(
                  context,
                ).removeCurrentSnackBar(); // Quita el snackbar de "Guardando..."
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('QR Guardado: ${state.code}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // ¡Refresca el historial!
                context.read<HistoryBloc>().add(LoadHistory());
              } else if (state is ScanFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is ScanSaveFailure) {
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Escaneado: ${state.code}\nError al guardar: ${state.errorMessage}',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                // No refrescamos historial porque no se guardó
              } else if (state is ScanCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Escaneo cancelado')),
                );
              }
            },
          ),
          // Podrías tener listeners para HistoryBloc si necesitas mostrar errores de carga, etc.
        ],
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, historyState) {
            if (historyState is HistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (historyState is HistoryLoaded) {
              return ListView.builder(
                itemCount: historyState.scans.length,
                itemBuilder: (context, index) {
                  final scan = historyState.scans[index];
                  return ListTile(
                    leading: const Icon(Icons.qr_code_scanner),
                    title: Text(
                      scan.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(scan.timestamp),
                    ), // Formato de fecha
                  );
                },
              );
            } else if (historyState is HistoryEmpty) {
              return const Center(
                child: Text(
                  'No hay escaneos aún. ¡Presiona el botón para escanear!',
                ),
              );
            } else if (historyState is HistoryFailure) {
              return Center(
                child: Text(
                  'Error al cargar el historial:\n${historyState.message}',
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              // HistoryInitial
              return const Center(child: Text('Cargando historial...'));
            }
          },
        ),
      ),
      floatingActionButton: BlocBuilder<ScannerBloc, ScannerState>(
        // Deshabilita el FAB mientras escanea/guarda
        builder: (context, scanState) {
          final isScanningOrSaving =
              scanState is ScannerLoading || scanState is ScanSaveInProgress;
          return FloatingActionButton(
            onPressed: isScanningOrSaving
                ? null
                : _requestCameraPermissionAndScan,
            tooltip: 'Escanear QR',
            backgroundColor: isScanningOrSaving
                ? Colors.grey
                : Theme.of(context).colorScheme.secondary,
            child: isScanningOrSaving
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : const Icon(Icons.qr_code_scanner),
          );
        },
      ),
    );
  }
}
