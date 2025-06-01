import 'package:flutter/material.dart';
import 'package:so_m2/core/util_service.dart';
import 'package:so_m2/model/memory_data_model.dart';
import 'package:so_m2/model/page_table_data_model.dart';
import 'package:so_m2/model/tlb_data_model.dart';
import 'package:so_m2/presentation/exibirresultados_dialog.dart';

class ExibirResultadosService {
  static final ExibirResultadosService _singleton =
      ExibirResultadosService._internal();

  factory ExibirResultadosService() {
    return _singleton;
  }

  ExibirResultadosService._internal();

  void encontrouNaTlb(
    List<MemoryDataModel> dadosMemoriaPrincipal,
    TlbDataModel resultadoTlb,
    int enderecoFisico,
    int deslocamento,
    TextEditingController endereco,
    BuildContext context,
  ) {
    final resultado = dadosMemoriaPrincipal[enderecoFisico];

    final mensagem =
        'TLB HIT!\n'
        'Endereço Virtual: ${endereco.text}\n'
        'Número da Página Virtual: ${resultadoTlb.numeroPaginaVirtual}\n'
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
    int bitsDeslocamento,
    int enderecoDecimal,
    TextEditingController endereco,
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
        'TLB MISS!\n'
        'PAGE HIT!\n'
        'Endereço Virtual: ${endereco.text}\n'
        'Número da Página Virtual: ${enderecoDecimal >> bitsDeslocamento}\n'
        'Número do Quadro Físico: ${resultadoPageTable.numeroQuadroFisico}\n'
        'Deslocamento: $deslocamento\n'
        'Valor: ${resultado.valor}';

    ExibirResultadosDialog.show(context, mensagem: mensagem);
  }

  void buscarNaBackingStore(
    int numeroPaginaVirtual,
    int deslocamento,
    List<MemoryDataModel> dadosBackingStore,
    List<PageTableDataModel> dadosPageTable,
    BuildContext context,
    List<MemoryDataModel> dadosMemoriaPrincipal,
    int tamanhoDeslocamento,
    List<TlbDataModel> dadosTlb,
    TextEditingController endereco,
    int enderecoDecimal,
    int numeroBits,
  ) async {
    PageTableManager gerenciadorPt = PageTableManager(dadosPageTable);
    int quadroFisicoEscolhido = await UtilService()
        .obterQuadroFisicoParaNovaPagina(
          dadosPageTable: dadosPageTable,
          dadosMemoriaPrincipal: dadosMemoriaPrincipal,
          dadosBackingStore: dadosBackingStore,
          tamanhoDeslocamento: tamanhoDeslocamento,
        );

    // copiar pagina inteira
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

    gerenciadorPt.atualizarTabelaDePaginas(
      enderecoDecimal: enderecoDecimal,
      numeroBits: numeroBits,
      tamanhoPaginaBytes: tamanhoDeslocamento,
      quadroFisico: quadroFisicoEscolhido,
    );
    // Não se esqueça de persistir as alterações no arquivo
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
}
