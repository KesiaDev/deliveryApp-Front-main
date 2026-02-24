// To parse this JSON data, do
//
//     final dadosCorridas = dadosCorridasFromJson(jsonString);

import 'dart:convert';

List<TipoCorrida> getTipoCorrida() {
  List<TipoCorrida> listTipo = [];
  listTipo.add(TipoCorrida(indTipo: 1, desTipo: "Cartão", isSelected: true));
  listTipo.add(TipoCorrida(indTipo: 2, desTipo: "Dinheiro", isSelected: false));
  listTipo.add(TipoCorrida(indTipo: 3, desTipo: "Pix", isSelected: false));
  return listTipo;
}

String getTitleTipoCorrida(int indTipo) {
  if (indTipo != null) {
    for (var element in getTipoCorrida()) {
      if (element.indTipo == indTipo) return element.desTipo;
    }
  }
  return "";
}

class TipoCorrida {
  TipoCorrida({
    required this.indTipo,
    required this.desTipo,
    required this.isSelected,
  });

  int indTipo;
  String desTipo;
  bool isSelected;

  bool operator ==(o) =>
      o is TipoCorrida && indTipo == o.indTipo && desTipo == o.desTipo;
  @override
  int get hashCode => super.hashCode;
}
