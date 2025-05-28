import 'package:so_m2/model/memory_data_model.dart';
import 'package:so_m2/model/page_table_data_model.dart';

class UtilService {
  static final UtilService _singleton = UtilService._internal();

  factory UtilService() {
    return _singleton;
  }

  UtilService._internal();

  int converterParaDecimal(String valor) {
    final decimalRegex = RegExp(r'^[0-9]+$');
    final hexadecimalRegex = RegExp(r'^[0-9A-Fa-f]+$');

    if (decimalRegex.hasMatch(valor)) {
      return int.parse(valor);
    } else if (hexadecimalRegex.hasMatch(valor)) {
      return int.parse(valor, radix: 16);
    } else {
      throw FormatException(
        'Valor inválido. Use apenas dígitos decimais ou hexadecimais.',
      );
    }
  }

  Future<int> obterQuadroFisicoParaNovaPagina({
    required List<PageTableDataModel> dadosPageTable,
    required List<MemoryDataModel> dadosMemoriaPrincipal,
    required List<MemoryDataModel> dadosBackingStore,
    required int tamanhoDeslocamento,
  }) async {
    int numQuadrosFisicos = dadosMemoriaPrincipal.length ~/ tamanhoDeslocamento;
    List<bool> quadrosOcupados = List.filled(numQuadrosFisicos, false);

    for (final entrada in dadosPageTable) {
      if (entrada.bitValido &&
          entrada.numeroQuadroFisico >= 0 &&
          entrada.numeroQuadroFisico < numQuadrosFisicos) {
        quadrosOcupados[entrada.numeroQuadroFisico] = true;
      }
    }
    for (int i = 0; i < numQuadrosFisicos; i++) {
      if (!quadrosOcupados[i]) {
        return i;
      }
    }

    for (int i = 0; i < dadosPageTable.length; i++) {
      PageTableDataModel candidata = dadosPageTable[i];
      if (candidata.bitValido && !candidata.bitAcesso) {
        int quadroDaVitima = candidata.numeroQuadroFisico;
        int vitimaVPN = i;
        if (candidata.bitModificado) {
          for (
            int deslocamento = 0;
            deslocamento < tamanhoDeslocamento;
            deslocamento++
          ) {
            int idxMemoria =
                (quadroDaVitima * tamanhoDeslocamento) + deslocamento;
            int idxBackingStore =
                (vitimaVPN * tamanhoDeslocamento) + deslocamento;
            if (idxMemoria < dadosMemoriaPrincipal.length &&
                idxBackingStore < dadosBackingStore.length) {
              dadosBackingStore[idxBackingStore] =
                  dadosMemoriaPrincipal[idxMemoria];
            }
          }
          reescreverBackingStore(dadosBackingStore);
        }
        candidata.bitValido = false;
        await reescreverTabelaDePaginas(dadosPageTable);
        return quadroDaVitima;
      }
    }

    for (int i = 0; i < dadosPageTable.length; i++) {
      PageTableDataModel candidata = dadosPageTable[i];
      if (candidata.bitValido) {
        candidata.bitAcesso = false;

        int quadroDaVitima = candidata.numeroQuadroFisico;
        int vitimaVPN = i;

        if (candidata.bitModificado) {
          for (
            int deslocamento = 0;
            deslocamento < tamanhoDeslocamento;
            deslocamento++
          ) {
            int idxMemoria =
                (quadroDaVitima * tamanhoDeslocamento) + deslocamento;
            int idxBackingStore =
                (vitimaVPN * tamanhoDeslocamento) + deslocamento;
            if (idxMemoria < dadosMemoriaPrincipal.length &&
                idxBackingStore < dadosBackingStore.length) {
              dadosBackingStore[idxBackingStore] =
                  dadosMemoriaPrincipal[idxMemoria];
            }
          }
          await reescreverBackingStore(dadosBackingStore);
        }
        candidata.bitValido = false;
        await reescreverTabelaDePaginas(dadosPageTable);
        return quadroDaVitima;
      }
    }

    throw Exception(
      "Lógica de substituição falhou: não encontrou quadro livre nem página válida para substituir.",
    );
  }
}
