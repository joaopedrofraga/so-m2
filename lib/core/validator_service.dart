class ValidatorService {
  static final ValidatorService _singleton = ValidatorService._internal();

  factory ValidatorService() {
    return _singleton;
  }

  ValidatorService._internal();

  bool validarEndereco(int endereco, int numeroBits) {
    if (numeroBits == 32) {
      return endereco >= 0 && endereco <= 4294967295;
    } else if (numeroBits == 16) {
      return endereco >= 0 && endereco <= 65535;
    } else {
      return false;
    }
  }
}
