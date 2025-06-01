import 'dart:io';

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
    if (parts.length < 4) {
      return PageTableDataModel(
        numeroQuadroFisico: -1,
        bitValido: false,
        bitAcesso: false,
        bitModificado: false,
      );
    }
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
  try {
    final contents = await file.readAsString();
    final lines =
        contents.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return lines.map((line) => PageTableDataModel.fromTxt(line)).toList();
  } catch (e) {
    return [];
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
                '${entrada.numeroQuadroFisico},${entrada.bitValido ? 1 : 0},${entrada.bitAcesso ? 1 : 0},${entrada.bitModificado ? 1 : 0}',
          )
          .toList();
  await file.writeAsString(lines.join('\n'));
}

class PageTableManager {
  final List<PageTableDataModel> _pageTableEntries;

  PageTableManager(this._pageTableEntries);

  int _getBitsDeslocamento(int tamanhoPaginaBytes) {
    if (tamanhoPaginaBytes == 256) return 8;
    if (tamanhoPaginaBytes == 1024) return 10;
    if (tamanhoPaginaBytes == 4096) return 12;
    throw ArgumentError("Tamanho de página inválido: $tamanhoPaginaBytes");
  }

  PageTableDataModel? buscarNaTabelaDePaginas({
    required int enderecoDecimal,
    required int numeroBits,
    required int tamanhoPaginaBytes,
  }) {
    int bitsDeslocamento = _getBitsDeslocamento(tamanhoPaginaBytes);
    int indiceFinalNaTabela;

    if (numeroBits == 32 && tamanhoPaginaBytes == 4096) {
      int vpnGlobal = enderecoDecimal >> bitsDeslocamento;

      int p1Index = (vpnGlobal >> 10) & 0x3FF;
      int p2Index = vpnGlobal & 0x3FF;

      if (p1Index == 0 && p2Index >= 0 && p2Index < _pageTableEntries.length) {
        indiceFinalNaTabela = p2Index;
      } else {
        return null;
      }
    } else {
      int pagVirtualLinear = enderecoDecimal >> bitsDeslocamento;
      if (pagVirtualLinear >= 0 &&
          pagVirtualLinear < _pageTableEntries.length) {
        indiceFinalNaTabela = pagVirtualLinear;
      } else {
        return null;
      }
    }

    if (indiceFinalNaTabela >= 0 &&
        indiceFinalNaTabela < _pageTableEntries.length) {
      final entrada = _pageTableEntries[indiceFinalNaTabela];
      if (entrada.bitValido) {
        entrada.bitAcesso = true;
        return entrada;
      }
    }
    return null;
  }

  void atualizarTabelaDePaginas({
    required int enderecoDecimal,
    required int numeroBits,
    required int tamanhoPaginaBytes,
    required int quadroFisico,
  }) {
    int bitsDeslocamento = _getBitsDeslocamento(tamanhoPaginaBytes);
    int indiceFinalNaTabela;

    if (numeroBits == 32 && tamanhoPaginaBytes == 4096) {
      int vpnGlobal = enderecoDecimal >> bitsDeslocamento;
      int p1Index = (vpnGlobal >> 10) & 0x3FF;
      int p2Index = vpnGlobal & 0x3FF;

      if (p1Index == 0 && p2Index >= 0 && p2Index < _pageTableEntries.length) {
        indiceFinalNaTabela = p2Index;
      } else {
        return;
      }
    } else {
      int pagVirtualLinear = enderecoDecimal >> bitsDeslocamento;
      if (pagVirtualLinear >= 0 &&
          pagVirtualLinear < _pageTableEntries.length) {
        indiceFinalNaTabela = pagVirtualLinear;
      } else {
        return;
      }
    }

    if (indiceFinalNaTabela >= 0 &&
        indiceFinalNaTabela < _pageTableEntries.length) {
      PageTableDataModel entradaParaAtualizar =
          _pageTableEntries[indiceFinalNaTabela];
      entradaParaAtualizar.numeroQuadroFisico = quadroFisico;
      entradaParaAtualizar.bitValido = true;
      entradaParaAtualizar.bitAcesso = true;
      entradaParaAtualizar.bitModificado = false;
    } else {}
  }
}
