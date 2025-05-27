import 'package:flutter/material.dart';

class ExibirResultadosDialog {
  static void show(BuildContext context, {required String mensagem}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 173, 47, 38),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 330),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'RESULTADOS DA CONSULTA',
                        style: TextStyle(fontSize: 19),
                      ),
                      const Spacer(),
                      const CloseButton(color: Colors.white),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
