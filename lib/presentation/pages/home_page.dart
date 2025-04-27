// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_scanner_app/core/di/locator.dart';
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:qr_scanner_app/presentation/bloc/history/history_bloc.dart';
import 'package:qr_scanner_app/presentation/bloc/scanner/scanner_bloc.dart';
import 'package:qr_scanner_app/presentation/pages/scanner_page.dart';
import 'package:qr_scanner_app/presentation/widgets/pin_bottom_sheet_content.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Dispara el evento para verificar el estado inicial al cargar la página
    context.read<AuthBloc>().add(AuthStatusChecked());
  }

  void _showPinBottomSheet(BuildContext context, bool isCreatingPin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Importante para que el teclado no tape el sheet
      shape: const RoundedRectangleBorder(
        // Bordes redondeados
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        // Proporciona el mismo AuthBloc al BottomSheet
        return BlocProvider.value(
          value: BlocProvider.of<AuthBloc>(context),
          child: Padding(
            // Padding para evitar el teclado del sistema si aparece
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: PinBottomSheetContent(isCreatingPin: isCreatingPin),
          ),
        );
      },
    ).whenComplete(() {
      // Si el sheet se cierra sin autenticar o cancelar explícitamente,
      // podemos volver al estado 'Known' para evitar quedarnos en 'ShowPinSheet'
      final currentState = context.read<AuthBloc>().state;
      if (currentState is AuthShowPinSheet ||
          currentState is AuthPinIncorrect) {
        context.read<AuthBloc>().add(
          PinAuthCancelled(),
        ); // O AuthStatusChecked si prefieres re-verificar
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner App')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // --- Manejo de efectos secundarios (navegación, snackbars, bottom sheets) ---
          if (state is AuthShowPinSheet) {
            _showPinBottomSheet(context, state.isCreatingPin);
          } else if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Autenticación Exitosa!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navega a la siguiente pantalla (ej. ScannerPage)
            // En HomePage -> listener -> if (state is AuthAuthenticated)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  // Necesitas proveer los BLoCs a ScannerPage
                  providers: [
                    BlocProvider(create: (_) => locator<HistoryBloc>()),
                    BlocProvider(create: (_) => locator<ScannerBloc>()),
                  ],
                  child: const ScannerPage(),
                ),
              ),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthPinIncorrect) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIN Incorrecto'),
                backgroundColor: Colors.orange,
              ),
            );
            // El BLoC se encargará de volver a emitir AuthShowPinSheet si es necesario
          } else if (state is AuthStatusKnown &&
              ModalRoute.of(context)?.isCurrent != true) {
            // Si el PIN se acaba de crear y volvemos a AuthStatusKnown, podemos cerrar el modal si aún está abierto
            // (Esto es un manejo extra, usualmente el pop en el submit es suficiente)
            // Navigator.popUntil(context, (route) => route.isFirst); // Cuidado con esto
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading;
          bool isPinSetup = state.isPinSet ?? false;
          bool canUseBiometrics = state.isBiometricAvailable ?? false;

          // Determina si los botones deben estar activos
          bool canUsePin = state is! AuthInitial && state is! AuthAuthenticated;
          // La condición para biométrico es similar, a menos que quieras deshabilitarlo durante el PIN sheet, etc.
          bool canActivateBiometrics =
              state is! AuthInitial &&
              state is! AuthAuthenticated &&
              canUseBiometrics;

          // Si el estado es autenticado, no mostramos los botones
          if (state is AuthAuthenticated) {
            // Este return puede que ni se vea si la navegación es inmediata
            return const Center(child: Text("Autenticado! Redirigiendo..."));
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Botón Biométrico ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Iniciar con Biometría'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    // Habilita si NO está cargando Y canActivateBiometrics es true
                    onPressed: isLoading || !canActivateBiometrics
                        ? null
                        : () => context.read<AuthBloc>().add(
                            BiometricAuthRequested(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // --- Botón PIN ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pin),
                    label: Text(
                      isPinSetup ? 'Ingresar con PIN' : 'Configurar PIN',
                    ), // Usa isPinSetup
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed:
                        isLoading ||
                            !canUsePin // Usa canUsePin
                        ? null
                        : () =>
                              context.read<AuthBloc>().add(PinAuthRequested()),
                  ),
                  const SizedBox(height: 40),

                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }, // Fin del builder
      ),
    );
  }
}
