import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SelecaoTamanhoDeslocamentoWidget extends StatelessWidget {
  List<int> deslocamento = [2048, 8192, 32768];
  int deslocamentoSelecionado;
  Function(int) onChanged;

  SelecaoTamanhoDeslocamentoWidget({
    super.key,
    required this.deslocamentoSelecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Selecione o tamanho do descolamento'),
        Row(
          children: [
            Expanded(
              child: RadioListTile(
                value: deslocamento[0],
                groupValue: deslocamentoSelecionado,
                onChanged: (novoValor) {
                  onChanged(novoValor!);
                },
                activeColor: Colors.red,
                title: Text('256 B', style: TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: RadioListTile(
                value: deslocamento[1],
                groupValue: deslocamentoSelecionado,
                onChanged: (novoValor) {
                  onChanged(novoValor!);
                },
                activeColor: Colors.red,
                title: Text('1 KB', style: TextStyle(color: Colors.white)),
              ),
            ),
            Expanded(
              child: RadioListTile(
                value: deslocamento[2],
                groupValue: deslocamentoSelecionado,
                onChanged: (novoValor) {
                  onChanged(novoValor!);
                },
                activeColor: Colors.red,
                title: Text('4 KB', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
