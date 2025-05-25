import 'dart:io';

import 'package:flutter/widgets.dart';

class PageTableDataModel {
  int numeroQuadroFisico;
  bool bitValido;
  bool bitAcesso;
  bool bitModificado;

  PageTableDataModel({
    required this.numeroQuadroFisico,
    required this.bitValido,
    required this.bitAcesso,
    required this.bitModificado,
  });

  factory PageTableDataModel.fromTxt(String text) {
    final parts = text.split(',');
    return PageTableDataModel(
      numeroQuadroFisico: int.parse(parts[0]),
      bitValido: parts[1] == '1',
      bitAcesso: parts[2] == '1',
      bitModificado: parts[3] == '1',
    );
  }
}

Future<List<PageTableDataModel>> loadPageTableData() async {
  final file = File('page_table.txt');
  final contents = await file.readAsString();
  final lines = contents.split('\n');
  return lines.map((line) => PageTableDataModel.fromTxt(line)).toList();
}

PageTableDataModel? buscarNaTabelaDePaginas(
  int pagVirtual,
  List<PageTableDataModel> dadosPageTable,
) {
  if (pagVirtual >= 0 && pagVirtual < dadosPageTable.length) {
    final entrada = dadosPageTable[pagVirtual];
    if (entrada.bitValido) {
      return entrada;
    }
  }
  return null;
}

// bool possuiNaTabelaDePaginas(
//   int pagVirtual,
//   List<PageTableDataModel> dadosPageTable,
// ) {
//   if (pagVirtual >= 0 && pagVirtual < dadosPageTable.length) {
//     final PageTableDataModel entrada = dadosPageTable[pagVirtual];

//     if (entrada.bitValido) {
//       return true;
//     }
//   }
//   return false;
// }
