import 'dart:async';

import 'package:delivery_front/bussiness/repository/admin_repository.dart';
import 'package:delivery_front/shared/models/usuario.dart';

class AdminService {
  AdminRespository _adminRepository = AdminRespository();
  final _userDataController = StreamController<Empresa>();

  StreamSink<Empresa> get chuckDataSink => _userDataController.sink;

  Stream<Empresa> get chuckDataStream => _userDataController.stream;

  void dispose() {
    _userDataController.close();
  }

  Future<List<Empresa>> findEmpresas() async {
    var result = await _adminRepository.buscaEmpresas();
    return result;
  }

  Future<List<Motorista>> findMotoristas() async {
    var result = await _adminRepository.buscaMotoristas();
    return result;
  }

  Future<void> changeStatusUser(int? codUsuario, int indStatus) async {
    await _adminRepository.atualizaBloqueio(codUsuario, indStatus);
  }

  /// Tenta excluir uma empresa permanentemente
  /// Retorna true se conseguiu excluir, false caso contrário
  Future<bool> excluirEmpresa(int? codUsuario, int? codEmpresa) async {
    return await _adminRepository.excluirEmpresa(codUsuario, codEmpresa);
  }

  /// Tenta excluir um motorista permanentemente
  /// Retorna true se conseguiu excluir, false caso contrário
  Future<bool> excluirMotorista(int? codUsuario, int? codMotorista) async {
    return await _adminRepository.excluirMotorista(codUsuario, codMotorista);
  }

  Future<List<ValoresTaxas>> buscaVlrTaxas() async {
    return await _adminRepository.buscaConfigTaxas();
  }

  Future<void> saveTaxa(ValoresTaxas item) async {
    await _adminRepository.saveTaxa(item);
  }
}

class ValoresTaxas {
  ValoresTaxas({
    this.kmIni,
    this.kmFim,
    this.vlrTaxa,
    this.numSeq,
  });

  double? kmIni;
  double? kmFim;
  double? vlrTaxa;
  int? numSeq;

  factory ValoresTaxas.fromJson(Map<String, dynamic> json) => ValoresTaxas(
        kmIni: json["kmIni"],
        kmFim: json["kmFim"],
        vlrTaxa: json["vlrTaxa"],
        numSeq: json["numSeq"],
      );

  Map<String, dynamic> toJson() => {
        "vlrTaxa": vlrTaxa ?? 0,
        "kmIni": kmIni ?? 0,
        "kmFim": kmFim ?? 0,
        "numSeq": numSeq ?? 0,
      };
}
