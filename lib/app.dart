import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:so_m2/core/consultar_endereco_service.dart';
import 'package:so_m2/presentation/cabecalho_trabalho_widget.dart';
import 'package:so_m2/presentation/consultar_button_widget.dart';
import 'package:so_m2/presentation/endereco_textformfield_widget.dart';
import 'package:so_m2/presentation/selecao_numero_bits_widget.dart';
import 'package:so_m2/presentation/selecao_tamanho_deslocamento_widget.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

void calcularEnderecoVirtual(int endereco, int tamanhoPagina) {
  int numeroPagina = endereco ~/ tamanhoPagina;
  int deslocamento = endereco % tamanhoPagina;

  // print('Endereço virtual: $endereco');
  // print('Tamanho da página: $tamanhoPagina bytes');
  // print('Número da página: $numeroPagina');
  // print('Deslocamento na página: $deslocamento');
}

class _AppState extends State<App> {
  TextEditingController enderecontroller = TextEditingController();
  int numeroBitsSelecionado = 32;
  int deslocamentoSelecionado = 256;

  void alterarNumeroBits(int novoValor) {
    setState(() {
      numeroBitsSelecionado = novoValor;
    });
  }

  void alterarTamanhoDeslocamento(int novoValor) {
    setState(() {
      deslocamentoSelecionado = novoValor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
        scaffoldBackgroundColor: const Color.fromARGB(255, 27, 27, 27),
        textTheme: GoogleFonts.soraTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            //displayColor: Colors.white,
          ),
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Card(
            color: Colors.red.shade900,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'M2 - Sistemas Operacionais',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Card(
                    color: const Color.fromARGB(255, 27, 27, 27),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CabecalhoTrabalhoWidget(),
                            const Divider(thickness: 4, height: 40),
                            SelecaoNumeroBitsWidget(
                              numeroBitsSelecionado: numeroBitsSelecionado,
                              onChanged: alterarNumeroBits,
                            ),
                            const Divider(height: 30),
                            SelecaoTamanhoDeslocamentoWidget(
                              deslocamentoSelecionado: deslocamentoSelecionado,
                              onChanged: alterarTamanhoDeslocamento,
                            ),
                            const Divider(height: 30),
                            const SizedBox(height: 5),
                            EnderecoTextformfieldWidget(
                              enderecontroller: enderecontroller,
                            ),
                            const SizedBox(height: 30),
                            ConsultarButtonWidget(
                              endereco: enderecontroller,
                              numeroBits: numeroBitsSelecionado,
                              tamanhoDeslocamento: deslocamentoSelecionado,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
