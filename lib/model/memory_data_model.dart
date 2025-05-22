import 'dart:io';

class MemoryDataModel {
  int valor;

  MemoryDataModel({required this.valor});

  factory MemoryDataModel.fromTxt(String text) {
    final parts = text.split(',');
    return MemoryDataModel(valor: int.parse(parts[0]));
  }
}

Future<List<MemoryDataModel>> loadMemoryData() async {
  final file = File('memory.txt');
  final contents = await file.readAsString();
  final lines = contents.split('\n');
  return lines.map((line) => MemoryDataModel.fromTxt(line)).toList();
}
