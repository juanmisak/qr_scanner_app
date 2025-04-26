// ignore_for_file: use_build_context_synchronously

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
          // --- Construcción de la UI basada en el estado ---
          bool isLoading = state is AuthLoading;
          bool canUseBiometrics = false; // Placeholder
          bool isPinSetup = false;
          bool canUsePin = false;

          if (state is AuthStatusKnown) {
            isPinSetup = state.isPinSet;
            canUseBiometrics = state.isBiometricAvailable;
            canUsePin = true; // Siempre se puede intentar configurar/usar PIN
          } else if (state is AuthInitial) {
            // Muestra loading inicial o botones deshabilitados
            isLoading = true;
          } else if (state is AuthAuthenticated) {
            // Podrías mostrar un mensaje o ya haber navegado
            return const Center(child: Text("Autenticado!"));
          }
          // Otros estados como AuthShowPinSheet no reconstruyen esta parte principal

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
                    // Habilita si no está cargando Y la biometría está disponible (cuando se implemente)
                    onPressed: isLoading || !canUseBiometrics
                        ? null
                        : () => context.read<AuthBloc>().add(
                            BiometricAuthRequested(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // --- Botón PIN ---
                  ElevatedButton.icon(
                    icon: const Icon(Icons.pin),
                    // Cambia el texto basado en si el PIN está configurado o no
                    label: Text(
                      isPinSetup ? 'Ingresar con PIN' : 'Configurar PIN',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    // Habilita si no está cargando Y el estado permite usar PIN
                    onPressed: isLoading || !canUsePin
                        ? null
                        : () =>
                              context.read<AuthBloc>().add(PinAuthRequested()),
                  ),
                  const SizedBox(height: 40),

                  // --- Indicador de Carga ---
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
