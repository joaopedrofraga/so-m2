import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SelecaoNumeroBitsWidget extends StatelessWidget {
  List<int> numeroBits = [16, 32];
  Function(int) onChanged;
  int numeroBitsSelecionado;

  SelecaoNumeroBitsWidget({
    super.key,
    required this.numeroBitsSelecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Selecione o número de Bits'),
        Row(
          children: [
            Expanded(
              child: RadioListTile(
                value: numeroBits[0],
                groupValue: numeroBitsSelecionado,
                onChanged: (novoValor) {
                  onChanged(novoValor!);
                },
                activeColor: Colors.red,
                title: Text(
                  '${numeroBits[0]} Bits',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: RadioListTile(
                value: numeroBits[1],
                groupValue: numeroBitsSelecionado,
                onChanged: (novoValor) {
                  onChanged(novoValor!);
                },
                activeColor: Colors.red,
                title: Text(
                  '${numeroBits[1]} Bits',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
