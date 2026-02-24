import 'dart:convert';

import 'lista_solicitacoes.dart';

class ListaSolicitacoesMotorista {
  List<SolicitacaoMotorista>? listaSolicitacoes;

  ListaSolicitacoesMotorista({this.listaSolicitacoes});


  List<SolicitacaoMotorista> solicitacaoMotoristaFromJson(String str) =>
      List<SolicitacaoMotorista>.from(
          json.decode(str).map((x) => SolicitacaoMotorista.fromJson(x)));

  String solicitacaoMotoristaToJson(List<SolicitacaoMotorista> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

  factory ListaSolicitacoesMotorista.fromJson(Map<String, dynamic> json) {
    return ListaSolicitacoesMotorista(
      listaSolicitacoes: (json['corridas'] as List<dynamic>?)
          ?.map((e) => SolicitacaoMotorista.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'corridas': listaSolicitacoes?.map((e) => e.toJson()).toList(),
    };
  }
}
