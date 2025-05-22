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
