// ignore_for_file: use_build_context_synchronously

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          final dadosTlb = await loadTlbData();
          final dadosPageTable = await loadPageTableData();
          final dadosMemoriaPrincipal = await loadMemoriaData();
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

          int bitsOffset;
          if (tamanhoDeslocamento == 256) {
            // 2^8
            bitsOffset = 8;
          } else if (tamanhoDeslocamento == 1024) {
            // 2^10
            bitsOffset = 10;
          } else if (tamanhoDeslocamento == 4096) {
            // 2^12
            bitsOffset = 12;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tamanho de deslocamento inválido: $tamanhoDeslocamento Bytes. Use 256, 1024 ou 4096.',
                ),
              ),
            );
            return;
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

          int offsetMask = (1 << bitsOffset) - 1;
          int offset = enderecoDecimal & offsetMask;

          int vpn = enderecoDecimal >> bitsOffset;

          if (possuiNaTlb(vpn, dadosTlb)) {
            print('achou');
            // Se a página virtual está na TLB
          } else if (possuiNaTabelaDePaginas(vpn, dadosPageTable)) {
            // Se a página virtual está na tabela de páginas
          } else {}
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
        child: const Text('Consultar'),
      ),
    );
  }

  loadMemoriaData() {}
}





 // final resultado =
          //     'VPN: $vpn (0x${vpn.toRadixString(16).toUpperCase()}), Offset: $offset (0x${offset.toRadixString(16).toUpperCase()})';
          // print('--- Tradução de Endereço ---');
          // print('Endereço Virtual Fornecido: ${endereco.text}');
          // print('Endereço Virtual (Decimal): $enderecoDecimal');
          // print('Sistema de ${numeroBits} bits');
          // print(
          //   'Tamanho da Página/Deslocamento: $tamanhoDeslocamento Bytes ($bitsOffset bits)',
          // );
          // print(
          //   'Máscara de Offset: 0x${offsetMask.toRadixString(16).toUpperCase()}',
          // );
          // print('VPN (Decimal): $vpn');
          // print('VPN (Hexadecimal): 0x${vpn.toRadixString(16).toUpperCase()}');
          // print('Offset (Decimal): $offset');
          // print(
          //   'Offset (Hexadecimal): 0x${offset.toRadixString(16).toUpperCase()}',
          // );
          // print('--- Fim da Tradução ---');

          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(resultado),
          //     duration: const Duration(seconds: 5), // Duração maior para ler
          //   ),
          // );