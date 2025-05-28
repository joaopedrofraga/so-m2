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
    required Future<void> Function(List<PageTableDataModel>)
    persistirTabelaPaginas,
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

    int vitimaVPN = -1;
    PageTableDataModel? entradaVitima;

    for (int i = 0; i < dadosPageTable.length; i++) {
      if (dadosPageTable[i].bitValido) {
        vitimaVPN = i;
        entradaVitima = dadosPageTable[i];
        break;
      }
    }

    if (entradaVitima == null) {
      throw Exception(
        "Não foi possível selecionar uma página vítima, mas a memória está cheia.",
      );
    }

    int quadroDaVitima = entradaVitima.numeroQuadroFisico;

    if (entradaVitima.bitModificado) {
      for (
        int deslocamento = 0;
        deslocamento < tamanhoDeslocamento;
        deslocamento++
      ) {
        int idxMemoria = (quadroDaVitima * tamanhoDeslocamento) + deslocamento;
        int idxBackingStore = (vitimaVPN * tamanhoDeslocamento) + deslocamento;

        if (idxMemoria < dadosMemoriaPrincipal.length &&
            idxBackingStore < dadosBackingStore.length) {
          dadosBackingStore[idxBackingStore] =
              dadosMemoriaPrincipal[idxMemoria];
        }
      }
      await reescreverBackingStore(dadosBackingStore);
    }

    entradaVitima.bitValido = false;
    entradaVitima.possuiSegundaChance = true;
    entradaVitima.bitModificado = false;

    await persistirTabelaPaginas(dadosPageTable);

    return quadroDaVitima;
  }
}
