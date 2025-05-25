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

  int calcularEnderecoFisicoBitwise({
    required int numeroQuadroFisico,
    required int deslocamento,
    required int bitsDeslocamento,
  }) {
    if (numeroQuadroFisico < 0) {
      throw ArgumentError(
        'O Número do Quadro Físico (PFN) não pode ser negativo. PFN recebido: $numeroQuadroFisico',
      );
    }
    if (deslocamento < 0) {
      throw ArgumentError(
        'O deslocamento (offset) não pode ser negativo. Offset recebido: $deslocamento',
      );
    }
    if (bitsDeslocamento <= 0) {
      throw ArgumentError(
        'O número de bits de offset deve ser positivo. Recebido: $bitsDeslocamento',
      );
    }
    if (deslocamento >= (1 << bitsDeslocamento)) {
      throw ArgumentError(
        'O deslocamento (offset) ($deslocamento) excede o limite para $bitsDeslocamento bits de offset (Máx: ${(1 << bitsDeslocamento) - 1}).',
      );
    }

    int enderecoFisico =
        (numeroQuadroFisico << bitsDeslocamento) | deslocamento;
    return enderecoFisico;
  }

  Future<void> salvarAlteracoesNoTxt(
    List<PageTableDataModel> pageTable,
  ) async {}
}
