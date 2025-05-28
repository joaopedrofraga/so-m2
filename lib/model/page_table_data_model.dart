import 'dart:io';

class PageTableDataModel {
  int numeroQuadroFisico;
  bool bitValido;
  bool possuiSegundaChance;
  bool bitModificado;

  PageTableDataModel({
    required this.numeroQuadroFisico,
    required this.bitValido,
    required this.possuiSegundaChance,
    required this.bitModificado,
  });

  factory PageTableDataModel.fromTxt(String text) {
    final parts = text.split(',');
    return PageTableDataModel(
      numeroQuadroFisico: int.parse(parts[0]),
      bitValido: parts[1] == '1',
      possuiSegundaChance: parts[2] == '1',
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
    if (entrada.bitValido && !entrada.possuiSegundaChance) {
      entrada.possuiSegundaChance = true;
      return entrada;
    }
  }
  return null;
}

void atualizarTabelaDePaginasCorrigida(
  int pagVirtual,
  int quadroFisico,
  List<PageTableDataModel> dadosPageTable,
) {
  if (pagVirtual >= 0 && pagVirtual < dadosPageTable.length) {
    PageTableDataModel entradaParaAtualizar = dadosPageTable[pagVirtual];

    entradaParaAtualizar.numeroQuadroFisico = quadroFisico;
    entradaParaAtualizar.bitValido = true;
    entradaParaAtualizar.possuiSegundaChance = true;
    entradaParaAtualizar.bitModificado = false;
  } else {
    print(
      "Erro: Número da página virtual $pagVirtual está fora dos limites da tabela de páginas (0-${dadosPageTable.length - 1}).",
    );
  }
}

Future<void> reescreverTabelaDePaginas(
  List<PageTableDataModel> dadosPageTable,
) async {
  final file = File('page_table.txt');
  final lines =
      dadosPageTable
          .map(
            (entrada) =>
                '${entrada.numeroQuadroFisico},${entrada.bitValido ? 1 : 0},${entrada.possuiSegundaChance ? 1 : 0},${entrada.bitModificado ? 1 : 0}',
          )
          .toList();

  await file.writeAsString(lines.join('\n'));
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
