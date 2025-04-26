// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:qr_scanner_app/presentation/widgets/pin_bottom_sheet_content.dart';
// Importa la página de Scanner cuando la tengas
// import 'scanner_page.dart';

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
            // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ScannerPage()));
            //print("Navegar a la pantalla principal de la app (Scanner)");
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
              !state.isPinSet &&
              ModalRoute.of(context)?.isCurrent != true) {
            // Si el PIN se acaba de crear y volvemos a AuthStatusKnown, podemos cerrar el modal si aún está abierto
            // (Esto es un manejo extra, usualmente el pop en el submit es suficiente)
            // Navigator.popUntil(context, (route) => route.isFirst); // Cuidado con esto
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading;
          bool isPinSetup = false;
          bool canUsePin = false;
          bool canUseBiometrics = false; // (Si implementas biometría)

          if (state is AuthLoading) {
            isPinSetup = state.isPinSet;
            // Podrías querer obtener canUseBiometrics de aquí también si AuthLoading lo tiene
          } else if (state is AuthStatusKnown) {
            isPinSetup = state.isPinSet;
            canUseBiometrics = state
                .isBiometricAvailable; // <-- ¡ASEGÚRATE QUE ESTA LÍNEA EXISTE!
          } else if (state is AuthShowPinSheet) {
            isPinSetup = state.isPinSet;
            // El estado conocido previo debería determinar canUseBiometrics
          } else if (state is AuthFailure) {
            isPinSetup = state.isPinSet;
            // El estado conocido previo debería determinar canUseBiometrics
          } else if (state is AuthPinIncorrect) {
            isPinSetup = state.isPinSet;
            // El estado conocido previo debería determinar canUseBiometrics
          }
          // Determina si el botón de PIN debe estar activo
          // Generalmente estará activo a menos que estemos autenticados o en el estado inicial.
          canUsePin = state is! AuthInitial && state is! AuthAuthenticated;
          // (Puedes ajustar esta lógica si necesitas deshabilitarlo en otros casos)

          // (Añade lógica similar para canUseBiometrics si es necesario)

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Iniciar con Biometría'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    // Habilita si no está cargando Y la biometría está disponible
                    onPressed: isLoading || !canUseBiometrics
                        ? null // Se deshabilita si canUseBiometrics es false
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
                    ), // <-- Usará el valor correcto de isPinSetup
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    // Habilita si no está cargando Y podemos usar PIN (según el estado)
                    onPressed:
                        isLoading ||
                            !canUsePin // <-- Usará el valor correcto de canUsePin
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
        },
      ),
    );
  }
}
