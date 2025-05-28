import 'package:flutter/material.dart';
import 'package:so_m2/core/util_service.dart';
import 'package:so_m2/model/memory_data_model.dart';
import 'package:so_m2/model/page_table_data_model.dart';
import 'package:so_m2/model/tlb_data_model.dart';
import 'package:so_m2/presentation/exibirresultados_dialog.dart';

class ConsultarButtonWidget extends StatelessWidget {
  final TextEditingController endereco;
  final int numeroBits; // 16 ou 32
  final int tamanhoDeslocamento; // 256, 1024, ou 4096 (bytes)

  const ConsultarButtonWidget({
    super.key,
    required this.endereco,
    required this.numeroBits,
    required this.tamanhoDeslocamento,
  });

  void encontrouNaTlb(
    List<MemoryDataModel> dadosMemoriaPrincipal,
    TlbDataModel resultadoTlb,
    int enderecoFisico,
    int deslocamento,
    BuildContext context,
  ) {
    final resultado = dadosMemoriaPrincipal[enderecoFisico];

    final mensagem =
        'TLB HIT!\n'
        'Endereço Virtual: ${endereco.text}\n'
        'Número do Quadro Físico: ${resultadoTlb.numeroQuadroFisico}\n'
        'Deslocamento: $deslocamento\n'
        'Valor: ${resultado.valor}';

    ExibirResultadosDialog.show(context, mensagem: mensagem);
  }

  void encontrouNaTabelaDePaginas(
    List<MemoryDataModel> dadosMemoriaPrincipal,
    List<TlbDataModel> dadosTlb,
    PageTableDataModel resultadoPageTable,
    int enderecoFisico,
    int deslocamento,
    BuildContext context,
  ) async {
    final resultado = dadosMemoriaPrincipal[enderecoFisico];

    atualizarTlb(
      resultadoPageTable.numeroQuadroFisico,
      resultadoPageTable.numeroQuadroFisico,
      dadosTlb,
    );

    await reescreverTlb(dadosTlb);

    final mensagem =
        'TLB HIT!\n'
        'Endereço Virtual: ${endereco.text}\n'
        'Número da Página Virtual: ${resultadoPageTable.numeroQuadroFisico}\n'
        'Deslocamento: $deslocamento\n'
        'Valor: ${resultado.valor}';

    ExibirResultadosDialog.show(context, mensagem: mensagem);
  }

  Future<void> buscarNaBackingStore(
    int numeroPaginaVirtual,
    int deslocamento,
    List<MemoryDataModel> dadosBackingStore,
    List<PageTableDataModel> dadosPageTable,
    BuildContext context,
    List<MemoryDataModel> dadosMemoriaPrincipal,
    int tamanhoDeslocamento,
    List<TlbDataModel> dadosTlb,
  ) async {
    int quadroFisicoEscolhido = await UtilService()
        .obterQuadroFisicoParaNovaPagina(
          dadosPageTable: dadosPageTable,
          dadosMemoriaPrincipal: dadosMemoriaPrincipal,
          dadosBackingStore: dadosBackingStore,
          tamanhoDeslocamento: tamanhoDeslocamento,
        );

    for (int i = 0; i < tamanhoDeslocamento; i++) {
      int indiceBackingStore = (numeroPaginaVirtual * tamanhoDeslocamento) + i;
      int indiceMemoriaPrincipal =
          (quadroFisicoEscolhido * tamanhoDeslocamento) + i;

      if (indiceBackingStore < dadosBackingStore.length &&
          indiceMemoriaPrincipal < dadosMemoriaPrincipal.length) {
        dadosMemoriaPrincipal[indiceMemoriaPrincipal] = MemoryDataModel(
          valor: dadosBackingStore[indiceBackingStore].valor,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao carregar página: índice fora dos limites."),
          ),
        );
        return;
      }
    }
    reescreverDataMemory(dadosMemoriaPrincipal);

    atualizarTabelaDePaginasCorrigida(
      numeroPaginaVirtual,
      quadroFisicoEscolhido,
      dadosPageTable,
    );
    await reescreverTabelaDePaginas(dadosPageTable);

    atualizarTlb(numeroPaginaVirtual, quadroFisicoEscolhido, dadosTlb);
    await reescreverTlb(dadosTlb);

    int enderecoFisicoFinal =
        (quadroFisicoEscolhido * tamanhoDeslocamento) + deslocamento;
    final valorFinalLido = dadosMemoriaPrincipal[enderecoFisicoFinal].valor;

    final mensagem =
        'TLB MISS!\n'
        'PAGE FAULT!\n'
        'Endereço Virtual: ${endereco.text}\n'
        'Número do Quadro Físico: $enderecoFisicoFinal\n'
        'Deslocamento: $deslocamento\n'
        'Valor: $valorFinalLido';

    ExibirResultadosDialog.show(context, mensagem: mensagem);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          final dadosTlb = await loadTlbData();
          final dadosPageTable = await loadPageTableData();
          final dadosMemoriaPrincipal = await loadDataMemory();
          final dadosBackingStore = await loadBackingStore();

          if (endereco.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Por favor, insira um endereço.')),
            );
            return;
          }

          int enderecoDecimal;
          try {
            enderecoDecimal = UtilService().converterParaDecimal(endereco.text);
            if (enderecoDecimal < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Endereço inválido ou erro na conversão: ${endereco.text}',
                  ),
                ),
              );
              return;
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao converter endereço: ${e.toString()}'),
              ),
            );
            return;
          }

          int bitsDeslocamento;
          if (tamanhoDeslocamento == 256) {
            // 2^8
            bitsDeslocamento = 8;
          } else if (tamanhoDeslocamento == 1024) {
            // 2^10
            bitsDeslocamento = 10;
          } else {
            // 2^12
            bitsDeslocamento = 12;
          }

          BigInt maxEnderecoPossivel = (BigInt.one << numeroBits) - BigInt.one;
          if (BigInt.from(enderecoDecimal) > maxEnderecoPossivel) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Endereço ${endereco.text} (Decimal: $enderecoDecimal) excede o limite para $numeroBits bits (Máx: $maxEnderecoPossivel).',
                ),
              ),
            );
            return;
          }

          int mascaraDeslocamento = (1 << bitsDeslocamento) - 1;
          int deslocamento = enderecoDecimal & mascaraDeslocamento;
          int numeroPaginaVirtual = enderecoDecimal >> bitsDeslocamento;

          final resultadoTlb = buscarNaTlb(numeroPaginaVirtual, dadosTlb);

          if (resultadoTlb != null) {
            int enderecoFisico =
                (resultadoTlb.numeroQuadroFisico * tamanhoDeslocamento) +
                deslocamento;
            encontrouNaTlb(
              dadosMemoriaPrincipal,
              resultadoTlb,
              enderecoFisico,
              deslocamento,
              context,
            );
            return;
          }

          final resultadoPageTable = buscarNaTabelaDePaginas(
            numeroPaginaVirtual,
            dadosPageTable,
          );

          if (resultadoPageTable != null) {
            int enderecoFisico =
                (resultadoPageTable.numeroQuadroFisico * tamanhoDeslocamento) +
                deslocamento;

            encontrouNaTabelaDePaginas(
              dadosMemoriaPrincipal,
              dadosTlb,
              resultadoPageTable,
              enderecoFisico,
              deslocamento,
              context,
            );
            return;
          }

          await buscarNaBackingStore(
            numeroPaginaVirtual,
            deslocamento,
            dadosBackingStore,
            dadosPageTable,
            context,
            dadosMemoriaPrincipal,
            tamanhoDeslocamento,
            dadosTlb,
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: const Text('Consultar'),
      ),
    );
  }
}
