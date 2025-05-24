import 'dart:io';

class MemoryDataModel {
  int valor;

  MemoryDataModel({required this.valor});

  factory MemoryDataModel.fromTxt(String text) {
    //final parts = text.split(',');
    //print(text);
    return MemoryDataModel(valor: int.parse(text));
  }
}

Future<List<MemoryDataModel>> loadDataMemory() async {
  final file = File('data_memory.txt');
  final contents = await file.readAsString();
  final lines = contents.split('\n');
  return lines.map((line) => MemoryDataModel.fromTxt(line)).toList();
}

Future<List<MemoryDataModel>> loadBackingStore() async {
  final file = File('backing_store.txt');
  final contents = await file.readAsString();
  final lines = contents.split('\n');
  return lines.map((line) => MemoryDataModel.fromTxt(line)).toList();
}

int getValorNaMemoria(
  int endereco,
  List<MemoryDataModel> dadosMemoriaPrincipal,
) {
  if (endereco >= 0 && endereco < dadosMemoriaPrincipal.length) {
    return dadosMemoriaPrincipal[endereco].valor;
  }
  return -1;
}
