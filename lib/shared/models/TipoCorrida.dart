// To parse this JSON data, do
//
//     final dadosCorridas = dadosCorridasFromJson(jsonString);

import 'dart:convert';

/// Todos os tipos disponíveis na plataforma
List<TipoCorrida> getTipoCorrida() {
  return [
    TipoCorrida(indTipo: 1, desTipo: "Cartão", isSelected: true),
    TipoCorrida(indTipo: 2, desTipo: "Dinheiro", isSelected: false),
    TipoCorrida(indTipo: 3, desTipo: "Pix", isSelected: false),
    TipoCorrida(indTipo: 4, desTipo: "Boleto", isSelected: false),
    TipoCorrida(indTipo: 5, desTipo: "Carteira Fool", isSelected: false),
  ];
}

/// Filtra tipos de acordo com os métodos aceitos pela empresa
/// acceptedKeys: ['cartao','dinheiro','pix','boleto','carteira']
List<TipoCorrida> getTipoCorridaFiltrado(List<String> acceptedKeys) {
  final all = getTipoCorrida();
  if (acceptedKeys.isEmpty) return all;
  final map = {
    'cartao': 1, 'dinheiro': 2, 'pix': 3, 'boleto': 4, 'carteira': 5,
  };
  final allowed = acceptedKeys.map((k) => map[k]).whereType<int>().toSet();
  return all.where((t) => allowed.contains(t.indTipo)).toList();
}

String getTitleTipoCorrida(int indTipo) {
  for (var element in getTipoCorrida()) {
    if (element.indTipo == indTipo) return element.desTipo;
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
