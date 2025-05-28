import 'dart:io';

class TlbDataModel {
  int numeroPaginaVirtual;
  int numeroQuadroFisico;
  bool bitValido;
  int contadorLRU;

  TlbDataModel({
    required this.numeroPaginaVirtual,
    required this.numeroQuadroFisico,
    required this.bitValido,
    required this.contadorLRU,
  });

  factory TlbDataModel.fromTxt(String text) {
    final parts = text.split(',');
    return TlbDataModel(
      numeroPaginaVirtual: int.parse(parts[0]),
      numeroQuadroFisico: int.parse(parts[1]),
      bitValido: parts[2] == '1',
      contadorLRU: int.parse(parts[3]),
    );
  }
}

Future<List<TlbDataModel>> loadTlbData() async {
  final file = File('tlb.txt');
  final contents = await file.readAsString();
  final lines = contents.split('\n');
  return lines.map((line) => TlbDataModel.fromTxt(line)).toList();
}

TlbDataModel? buscarNaTlb(int pagVirtual, List<TlbDataModel> dadosTlb) {
  for (var entrada in dadosTlb) {
    if (entrada.numeroPaginaVirtual == pagVirtual && entrada.bitValido) {
      entrada.contadorLRU = 0;
      return entrada;
    } else {
      entrada.contadorLRU++;
    }
  }
  return null;
}

void atualizarTlb(
  int pagVirtual,
  int quadroFisico,
  List<TlbDataModel> dadosTlb,
) {
  TlbDataModel vitima = dadosTlb.first;
  for (var entrada in dadosTlb) {
    if (entrada.numeroPaginaVirtual == -1) {
      entrada.numeroPaginaVirtual = pagVirtual;
      entrada.numeroQuadroFisico = quadroFisico;
      entrada.bitValido = true;
      entrada.contadorLRU = 0;
      return;
    } else if (entrada.contadorLRU > vitima.contadorLRU) {
      vitima = entrada;
    }
  }
  vitima.numeroPaginaVirtual = pagVirtual;
  vitima.numeroQuadroFisico = quadroFisico;
  vitima.bitValido = true;
  vitima.contadorLRU = 0;
}

Future<void> reescreverTlb(List<TlbDataModel> dadosTlb) async {
  final file = File('tlb.txt');
  final sink = file.openWrite();
  for (var entrada in dadosTlb) {
    sink.write(
      '${entrada.numeroPaginaVirtual},${entrada.numeroQuadroFisico},${entrada.bitValido ? 1 : 0},${entrada.contadorLRU}',
    );
    if (entrada != dadosTlb.last) {
      sink.write('\n');
    }
  }
  await sink.flush();
  await sink.close();
}

// bool possuiNaTlb(int pagVirtual, List<TlbDataModel> dadosTlb) {
//   for (var i = 0; i < dadosTlb.length; i++) {
//     if (dadosTlb[i].numeroPaginaVirtual == pagVirtual &&
//         dadosTlb[i].bitValido) {
//       return true;
//     }
//   }
//   return false;
// }
