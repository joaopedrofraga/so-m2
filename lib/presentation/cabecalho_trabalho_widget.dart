import 'package:flutter/material.dart';

class CabecalhoTrabalhoWidget extends StatelessWidget {
  const CabecalhoTrabalhoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [Text('Professor:'), const Spacer(), Text('Felipe Viel')],
        ),
        const Divider(),
        Row(
          children: [
            Text('Alunos:'),
            const Spacer(),
            Text('João Pedro Tonatto Fraga\n   Maria Eduarda A. Martim'),
          ],
        ),
        const Divider(),
        Row(children: [Text('Data:'), const Spacer(), Text('03/06/2025')]),
      ],
    );
  }
}
