// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:so_m2/core/exibirresultados_service.dart';
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
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          final dadosTlb = await loadTlbData();
          final dadosMemoriaPrincipal = await loadDataMemory();
          final dadosBackingStore = await loadBackingStore();
          List<PageTableDataModel> dadosPageTable = await loadPageTableData();
          PageTableManager gerenciadorPt = PageTableManager(dadosPageTable);

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
            ExibirResultadosService().encontrouNaTlb(
              dadosMemoriaPrincipal,
              resultadoTlb,
              enderecoFisico,
              deslocamento,
              endereco,
              context,
            );
            return;
          }

          PageTableDataModel? resultadoPageTable = gerenciadorPt
              .buscarNaTabelaDePaginas(
                enderecoDecimal: enderecoDecimal,
                numeroBits: numeroBits,
                tamanhoPaginaBytes: tamanhoDeslocamento,
              );

          if (resultadoPageTable != null) {
            int enderecoFisico =
                (resultadoPageTable.numeroQuadroFisico * tamanhoDeslocamento) +
                deslocamento;

            ExibirResultadosService().encontrouNaTabelaDePaginas(
              dadosMemoriaPrincipal,
              dadosTlb,
              resultadoPageTable,
              enderecoFisico,
              deslocamento,
              bitsDeslocamento,
              enderecoDecimal,
              endereco,
              context,
            );
            return;
          }

          ExibirResultadosService().buscarNaBackingStore(
            numeroPaginaVirtual,
            deslocamento,
            dadosBackingStore,
            dadosPageTable,
            context,
            dadosMemoriaPrincipal,
            tamanhoDeslocamento,
            dadosTlb,
            endereco,
            enderecoDecimal,
            numeroBits,
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
