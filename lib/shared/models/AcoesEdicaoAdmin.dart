// To parse this JSON data, do
//
//     final dadosCorridas = dadosCorridasFromJson(jsonString);

List<AcoesEdicaoAdmin> getTiposAcoesEmpresa() {
  List<AcoesEdicaoAdmin> listTipo = [];
  listTipo.add(AcoesEdicaoAdmin(indTipo: 1, desTipo: "Verificar valores"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 2, desTipo: "Editar"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 3, desTipo: "Bloquear/Desbloquear"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 4, desTipo: "Excluir"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 5, desTipo: "Ver cartão"));
  return listTipo;
}

List<AcoesEdicaoAdmin> getTiposAcoesMotorista() {
  List<AcoesEdicaoAdmin> listTipo = [];
  listTipo.add(AcoesEdicaoAdmin(indTipo: 1, desTipo: "Verificar valores"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 2, desTipo: "Editar"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 3, desTipo: "Bloquear/Desbloquear"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 4, desTipo: "Ver carteira"));
  listTipo.add(AcoesEdicaoAdmin(indTipo: 5, desTipo: "Ver cartão"));
  return listTipo;
}

String getTitleTipoCorridaEmpresa(int indTipo) {
  if (indTipo != null) {
    for (var element in getTiposAcoesEmpresa()) {
      if (element.indTipo == indTipo) return element.desTipo;
    }
  }
  return "";
}

String getTitleTipoCorridaMotorista(int indTipo) {
  if (indTipo != null) {
    for (var element in getTiposAcoesMotorista()) {
      if (element.indTipo == indTipo) return element.desTipo;
    }
  }
  return "";
}

class AcoesEdicaoAdmin {
  AcoesEdicaoAdmin({
    required this.indTipo,
    required this.desTipo,
  });

  int indTipo;
  String desTipo;

  bool operator ==(o) =>
      o is AcoesEdicaoAdmin && indTipo == o.indTipo && desTipo == o.desTipo;
  @override
  int get hashCode => super.hashCode;
}
