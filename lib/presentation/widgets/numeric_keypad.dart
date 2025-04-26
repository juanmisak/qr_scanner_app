import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onNumberPressed;
  final VoidCallback? onBackspacePressed;
  final VoidCallback? onDonePressed; // Opcional

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    this.onBackspacePressed,
    this.onDonePressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
      shape: const CircleBorder(),
      padding: const EdgeInsets.all(16),
    );

    Widget buildButton(String text, {VoidCallback? onPressed, IconData? icon}) {
      return TextButton(
        style: buttonStyle,
        onPressed: onPressed,
        child: icon != null ? Icon(icon, size: 28) : Text(text),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5, // Ajusta esto para el espaciado vertical
      children: [
        ...List.generate(9, (index) {
          final number = (index + 1).toString();
          return buildButton(number, onPressed: () => onNumberPressed(number));
        }),
        // Botón vacío o de "done"
        if (onDonePressed != null)
          buildButton(
            '',
            icon: Icons.check_circle_outline,
            onPressed: onDonePressed,
          )
        else // Espacio si no hay botón "done"
          Container(),
        // Botón 0
        buildButton('0', onPressed: () => onNumberPressed('0')),
        // Botón Backspace
        buildButton(
          '',
          icon: Icons.backspace_outlined,
          onPressed: onBackspacePressed,
        ),
      ],
    );
  }
}
