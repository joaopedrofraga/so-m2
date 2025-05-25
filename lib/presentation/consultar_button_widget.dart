// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:so_m2/core/util_service.dart';
import 'package:so_m2/model/memory_data_model.dart';
import 'package:so_m2/model/page_table_data_model.dart';
import 'package:so_m2/model/tlb_data_model.dart';

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
    BuildContext context,
  ) {
    print('TLB HIT!');
    print('enderecoFisico: $enderecoFisico');
    final resultado = dadosMemoriaPrincipal[enderecoFisico];
    print('valor final: ${resultado.valor}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Endereço Físico: $enderecoFisico (0x${enderecoFisico.toRadixString(16).toUpperCase()})\n'
          'Valor: ${resultado.valor}',
        ),
      ),
    );
  }

  void encontrouNaTabelaDePaginas(
    List<MemoryDataModel> dadosMemoriaPrincipal,
    List<TlbDataModel> dadosTlb,
    PageTableDataModel resultadoPageTable,
    int enderecoFisico,
    BuildContext context,
  ) async {
    print('TLB MISS!');
    print('Page Table HIT!');
    final resultado = dadosMemoriaPrincipal[enderecoFisico];
    print('valor final: ${resultado.valor}');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Endereço Físico: $enderecoFisico (0x${enderecoFisico.toRadixString(16).toUpperCase()})\n'
          'Valor: ${resultado.valor}',
        ),
      ),
    );

    atualizarTlb(
      resultadoPageTable.numeroQuadroFisico,
      resultadoPageTable.numeroQuadroFisico,
      dadosTlb,
    );

    await reescreverTlb(dadosTlb);
  }

  // --- Funções Auxiliares (você precisará implementá-las ou adaptar) ---

  // Função para obter um quadro físico: seja um livre ou um após substituição.
  // Esta é uma função complexa que encapsula a lógica de gerenciamento de quadros.
  Future<int> obterQuadroFisicoParaNovaPagina({
    required List<PageTableDataModel> dadosPageTable,
    required List<MemoryDataModel> dadosMemoriaPrincipal,
    required List<MemoryDataModel> dadosBackingStore, // Para salvar página suja
    required int tamanhoDeslocamento, // Tamanho da página
    required Future<void> Function(List<PageTableDataModel>)
    persistirTabelaPaginas,
    // Adicione aqui a função para persistir o backing store se necessário
    // required Future<void> Function(List<MemoryDataModel>) persistirBackingStore,
  }) async {
    int numQuadrosFisicos = dadosMemoriaPrincipal.length ~/ tamanhoDeslocamento;
    List<bool> quadrosOcupados = List.filled(numQuadrosFisicos, false);

    for (final pte in dadosPageTable) {
      if (pte.bitValido &&
          pte.numeroQuadroFisico >= 0 &&
          pte.numeroQuadroFisico < numQuadrosFisicos) {
        quadrosOcupados[pte.numeroQuadroFisico] = true;
      }
    }

    for (int i = 0; i < numQuadrosFisicos; i++) {
      if (!quadrosOcupados[i]) {
        print(" quadro físico livre encontrado: $i");
        return i; // Encontrou um quadro livre
      }
    }

    // Se não há quadros livres, implemente a substituição de página.
    // Esta é uma SIMPLIFICAÇÃO. Um algoritmo real (ex: Relógio, LRU para frames) seria necessário.
    // Aqui, vamos escolher a primeira página válida encontrada como vítima (MUITO SIMPLES).
    print(
      "Nenhum quadro físico livre. Iniciando substituição de página (lógica simplificada)...",
    );
    int vitimaVPN = -1;
    PageTableDataModel? pteVitima;

    for (int i = 0; i < dadosPageTable.length; i++) {
      if (dadosPageTable[i].bitValido) {
        vitimaVPN = i; // Assumindo que o índice da PTE é o VPN
        pteVitima = dadosPageTable[i];
        break;
      }
    }

    if (pteVitima == null) {
      // Não deveria acontecer se a memória está "cheia" de páginas válidas.
      // Indica um problema ou que a memória não estava realmente cheia.
      throw Exception(
        "Não foi possível selecionar uma página vítima, mas a memória está cheia.",
      );
    }

    int quadroDaVitima = pteVitima.numeroQuadroFisico;
    print(
      "Página vítima para substituição: VPN $vitimaVPN no quadro físico $quadroDaVitima",
    );

    // Se a página vítima estiver suja (modificada), salve-a na backing store.
    if (pteVitima.bitModificado) {
      print(
        "Página vítima (VPN $vitimaVPN) está suja. Escrevendo para backing_store.txt...",
      );
      for (int offset = 0; offset < tamanhoDeslocamento; offset++) {
        int idxMemoria = (quadroDaVitima * tamanhoDeslocamento) + offset;
        int idxBackingStore =
            (vitimaVPN * tamanhoDeslocamento) +
            offset; // VPN como índice da página na BS

        if (idxMemoria < dadosMemoriaPrincipal.length &&
            idxBackingStore < dadosBackingStore.length) {
          dadosBackingStore[idxBackingStore] =
              dadosMemoriaPrincipal[idxMemoria];
        }
      }
      // await persistirBackingStore(dadosBackingStore); // Se necessário
    }

    // Invalide a entrada da tabela de páginas da vítima.
    pteVitima.bitValido = false;
    pteVitima.bitAcesso = false;
    pteVitima.bitModificado = false;
    // pteVitima.numeroQuadroFisico = -1; // Opcional, para indicar que não está em um quadro

    await persistirTabelaPaginas(
      dadosPageTable,
    ); // Persiste a alteração da PTE da vítima

    return quadroDaVitima; // Retorna o quadro que foi liberado
  }

  // --- Função Principal Refeita ---
  Future<void> buscarNaBackingStore(
    // Parâmetros que a função já recebia:
    int numeroPaginaVirtual,
    int deslocamento,
    List<MemoryDataModel> dadosBackingStore,
    List<PageTableDataModel> dadosPageTable,
    BuildContext context,
    // Parâmetros adicionais necessários:
    List<MemoryDataModel> dadosMemoriaPrincipal,
    int tamanhoDeslocamento, // Mesmo que o 'tamanhoPagina'
    List<TlbDataModel> dadosTlb,
    // Funções para atualizar e persistir TLB e Page Table (já definidas no seu código)
    // Future<void> Function(List<TlbDataModel>) reescreverTlb,
    // void Function(int, int, List<TlbDataModel>) atualizarTlb,
    // Future<void> Function(List<PageTableDataModel>) reescreverTabelaDePaginas,
    // void Function(int, int, List<PageTableDataModel>) atualizarTabelaDePaginasCorrigida,
  ) async {
    print('TLB MISS!');
    print('Page Table MISS! (Page FAULT)');
    print('Buscando página $numeroPaginaVirtual na Backing Store...');

    // 1. Obter um quadro físico na memória principal para carregar a nova página.
    //    Isso pode envolver a substituição de uma página existente se a memória estiver cheia.
    int quadroFisicoEscolhido = await obterQuadroFisicoParaNovaPagina(
      dadosPageTable: dadosPageTable,
      dadosMemoriaPrincipal: dadosMemoriaPrincipal,
      dadosBackingStore: dadosBackingStore,
      tamanhoDeslocamento: tamanhoDeslocamento,
      persistirTabelaPaginas:
          reescreverTabelaDePaginas, // Passando a função de persistência
    );
    print(
      "Página $numeroPaginaVirtual será carregada no quadro físico $quadroFisicoEscolhido.",
    );

    // 2. Carregar a página inteira da backing store para o quadro físico escolhido na memória principal.
    print(
      "Carregando dados da página $numeroPaginaVirtual do backing store para a memória principal (quadro $quadroFisicoEscolhido)...",
    );
    for (int i = 0; i < tamanhoDeslocamento; i++) {
      int indiceBackingStore = (numeroPaginaVirtual * tamanhoDeslocamento) + i;
      int indiceMemoriaPrincipal =
          (quadroFisicoEscolhido * tamanhoDeslocamento) + i;

      // Certifique-se de que os índices estão dentro dos limites
      if (indiceBackingStore < dadosBackingStore.length &&
          indiceMemoriaPrincipal < dadosMemoriaPrincipal.length) {
        // Assumindo que MemoryDataModel pode ser copiado diretamente.
        // Se for uma classe, você pode precisar de um método clone ou copiar campos.
        dadosMemoriaPrincipal[indiceMemoriaPrincipal] = MemoryDataModel(
          valor: dadosBackingStore[indiceBackingStore].valor,
        );
      } else {
        print(
          "Erro: Índice fora dos limites ao copiar da backing store para a memória principal.",
        );
        // Tratar erro adequadamente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erro ao carregar página: índice fora dos limites."),
          ),
        );
        return;
      }
    }
    // Se 'dadosMemoriaPrincipal' representa um arquivo que precisa ser salvo, faça aqui.

    // 3. Atualizar a Tabela de Páginas para a página recém-carregada.
    print(
      "Atualizando tabela de páginas para VPN $numeroPaginaVirtual -> QF $quadroFisicoEscolhido.",
    );
    atualizarTabelaDePaginasCorrigida(
      // Usa a versão corrigida da sua função
      numeroPaginaVirtual,
      quadroFisicoEscolhido,
      dadosPageTable,
    );
    await reescreverTabelaDePaginas(
      dadosPageTable,
    ); // Persiste a tabela de páginas

    // 4. Atualizar a TLB com a nova tradução.
    print(
      "Atualizando TLB para VPN $numeroPaginaVirtual -> QF $quadroFisicoEscolhido.",
    );
    atualizarTlb(
      // Sua função de atualizar TLB
      numeroPaginaVirtual,
      quadroFisicoEscolhido,
      dadosTlb,
    );
    await reescreverTlb(dadosTlb); // Sua função de persistir TLB

    // 5. Calcular o endereço físico final e ler o valor do dado solicitado.
    int enderecoFisicoFinal =
        (quadroFisicoEscolhido * tamanhoDeslocamento) + deslocamento;
    String valorFinalLido = "ERRO_LEITURA";

    if (enderecoFisicoFinal < dadosMemoriaPrincipal.length) {
      valorFinalLido =
          dadosMemoriaPrincipal[enderecoFisicoFinal].valor.toString();
    } else {
      print(
        "Erro: Endereço físico final $enderecoFisicoFinal fora dos limites da memória principal.",
      );
    }
    print(
      "Valor final lido da memória principal no endereço físico $enderecoFisicoFinal: $valorFinalLido",
    );

    // 6. Exibir resultados.
    String mensagem =
        "Page Fault Atendido!\n"
        "Página $numeroPaginaVirtual carregada da Backing Store.\n"
        "Alocada no Quadro Físico: $quadroFisicoEscolhido\n"
        "Endereço Físico do dado: $enderecoFisicoFinal (0x${enderecoFisicoFinal.toRadixString(16).toUpperCase()})\n"
        "Valor lido: $valorFinalLido";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 5)),
    );
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
              context,
            );
            return;
          }

          // Dentro do onPressed em ConsultarButtonWidget:
          // ... após verificar que é TLB miss e Page Table miss ...
          await buscarNaBackingStore(
            numeroPaginaVirtual,
            deslocamento,
            dadosBackingStore,
            dadosPageTable,
            context,
            // Novos parâmetros:
            dadosMemoriaPrincipal,
            tamanhoDeslocamento, // Já calculado no seu onPressed
            dadosTlb,
            // As funções de reescrita/atualização são globais ou precisam ser passadas se não forem
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


// if (possuiNaTlb(numeroPaginaVirtual, dadosTlb)) {
          //   print('TLB HIT!');
          //   // Se a página virtual está na TLB
          //   // Obter o quadro físico da TLB
          //   int numeroQuadroFisico =
          //       dadosTlb[numeroPaginaVirtual].numeroQuadroFisico;
          //   print('Valor: $numeroQuadroFisico');
          // } else if (possuiNaTabelaDePaginas(
          //   numeroPaginaVirtual,
          //   dadosPageTable,
          // )) {
          //   print('TLB MISS!');
          //   print('Page Table HIT!');
          //   // Se a página virtual está na tabela de páginas
          //   // Obter o quadro físico da tabela de páginas
          //   int numeroQuadroFisico =
          //       dadosPageTable[numeroPaginaVirtual].numeroQuadroFisico;
          //   print('Valor: $numeroQuadroFisico');
          // } else {
          //   print('TLB MISS!');
          //   print('Page FAULT!');
          //   // Se a página virtual não está na tabela de páginas
          //   // Carregar o quadro físico da backing store
          //   int numeroQuadroFisico =
          //       dadosBackingStore[numeroPaginaVirtual].valor;
          //   if (numeroQuadroFisico != -1) {
          //     // Atualizar a tabela de páginas
          //     dadosPageTable[numeroPaginaVirtual].bitValido = true;
          //     dadosPageTable[numeroPaginaVirtual].numeroQuadroFisico =
          //         numeroQuadroFisico;
          //     print('Valor: $numeroQuadroFisico');
          //   } else {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text(
          //           'Erro ao acessar a backing store para o quadro físico: $numeroQuadroFisico',
          //         ),
          //       ),
          //     );
          //     return;
          //   }
          //   print('---------------------------');
          // }


 // final resultado =
          //     'numeroPaginaVirtual: $numeroPaginaVirtual (0x${numeroPaginaVirtual.toRadixString(16).toUpperCase()}), deslocamento: $deslocamento (0x${deslocamento.toRadixString(16).toUpperCase()})';
          // print('--- Tradução de Endereço ---');
          // print('Endereço Virtual Fornecido: ${endereco.text}');
          // print('Endereço Virtual (Decimal): $enderecoDecimal');
          // print('Sistema de ${numeroBits} bits');
          // print(
          //   'Tamanho da Página/Deslocamento: $tamanhoDeslocamento Bytes ($bitsDeslocamento bits)',
          // );
          // print(
          //   'Máscara de deslocamento: 0x${mascaraDeslocamento.toRadixString(16).toUpperCase()}',
          // );
          // print('numeroPaginaVirtual (Decimal): $numeroPaginaVirtual');
          // print('numeroPaginaVirtual (Hexadecimal): 0x${numeroPaginaVirtual.toRadixString(16).toUpperCase()}');
          // print('deslocamento (Decimal): $deslocamento');
          // print(
          //   'deslocamento (Hexadecimal): 0x${deslocamento.toRadixString(16).toUpperCase()}',
          // );
          // print('--- Fim da Tradução ---');

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(resultado),
          //     duration: const Duration(seconds: 5), // Duração maior para ler
          //   ),
          // );