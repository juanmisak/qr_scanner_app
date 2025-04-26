import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qr_scanner_app/presentation/bloc/auth/auth_bloc.dart';
import 'numeric_keypad.dart';

class PinBottomSheetContent extends StatefulWidget {
  final bool isCreatingPin;

  const PinBottomSheetContent({super.key, required this.isCreatingPin});

  @override
  State<PinBottomSheetContent> createState() => _PinBottomSheetContentState();
}

class _PinBottomSheetContentState extends State<PinBottomSheetContent> {
  String _enteredPin = '';
  String _confirmPin = ''; // Solo para creación
  bool _isConfirming = false; // Solo para creación

  void _handleNumberInput(String number) {
    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += number;
        });
        // Si se completan los 4 dígitos de confirmación, verifica
        if (_confirmPin.length == 4) {
          _submitPin();
        }
      }
    } else {
      if (_enteredPin.length < 4) {
        setState(() {
          _enteredPin += number;
        });
        // Si es para ingresar (no crear) y se completan 4 dígitos, envía
        if (!widget.isCreatingPin && _enteredPin.length == 4) {
          _submitPin();
        }
        // Si es para crear y se completan 4 dígitos, pasa a confirmar
        else if (widget.isCreatingPin && _enteredPin.length == 4) {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    }
  }

  void _handleBackspace() {
    if (_isConfirming) {
      if (_confirmPin.isNotEmpty) {
        setState(() {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        });
      } else {
        // Si borra todo en confirmación, vuelve a pedir el primer PIN
        setState(() {
          _isConfirming = false;
          _enteredPin = ''; // Reinicia el primer PIN también por claridad
        });
      }
    } else {
      if (_enteredPin.isNotEmpty) {
        setState(() {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        });
      }
    }
  }

  void _submitPin() {
    if (widget.isCreatingPin) {
      if (_enteredPin.length == 4 && _confirmPin.length == 4) {
        if (_enteredPin == _confirmPin) {
          context.read<AuthBloc>().add(PinSubmitted(_enteredPin));
          Navigator.pop(context); // Cierra el bottom sheet
        } else {
          // Muestra error de que los PINs no coinciden
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los PINs no coinciden. Intenta de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
          // Reinicia el proceso de creación
          setState(() {
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Entrando un PIN existente
      if (_enteredPin.length == 4) {
        context.read<AuthBloc>().add(PinSubmitted(_enteredPin));
        Navigator.pop(context); // Cierra el bottom sheet
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    String pinToShow;

    if (widget.isCreatingPin) {
      title = _isConfirming ? 'Confirma tu PIN' : 'Crea un PIN de 4 dígitos';
      pinToShow = _isConfirming ? _confirmPin : _enteredPin;
    } else {
      title = 'Ingresa tu PIN';
      pinToShow = _enteredPin;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Para que el sheet no ocupe toda la pantalla
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          // Indicador visual del PIN (puntos)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < pinToShow.length
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade300,
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          // Teclado numérico
          NumericKeypad(
            onNumberPressed: _handleNumberInput,
            onBackspacePressed: _handleBackspace,
            // No usamos 'onDonePressed' aquí, la lógica está en _handleNumberInput
          ),
          const SizedBox(height: 10),
          // Botón Cancelar (Opcional)
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(PinAuthCancelled());
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
