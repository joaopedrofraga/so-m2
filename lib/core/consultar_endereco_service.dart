import 'package:so_m2/model/memory_data_model.dart';
import 'package:so_m2/model/page_table_data_model.dart';
import 'package:so_m2/model/tlb_data_model.dart';

class ConsultarEnderecoService {
  static final ConsultarEnderecoService _singleton =
      ConsultarEnderecoService._internal();

  factory ConsultarEnderecoService() {
    return _singleton;
  }

  ConsultarEnderecoService._internal();

  Future<void> consultarEndereco(
    int endereco,
    int numeroBits,
    int deslocamento,
  ) async {
    List<TlbDataModel> tlbData = await loadTlbData();
    List<PageTableDataModel> pageTableData = await loadPageTableData();
    List<MemoryDataModel> dataMemoryData = await loadDataMemory();
    List<MemoryDataModel> backingStoreData = await loadBackingStore();
    print('TLB Data: ${tlbData.length} entradas');
    print('Page Table Data: ${pageTableData.length} entradas');
    print('Data Memory Data: ${dataMemoryData.length} entradas');
    print('Backing Store Data: ${backingStoreData.length} entradas');
  }
}
