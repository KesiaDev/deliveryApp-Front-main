// To parse this JSON data, do
//
//     final saldosCorrida = saldosCorridaFromJson(jsonString);

import 'dart:convert';

List<SaldosCorrida> saldosCorridaFromJson(String str) =>
    List<SaldosCorrida>.from(
        json.decode(str).map((x) => SaldosCorrida.fromJson(x)));

String saldosCorridaToJson(List<SaldosCorrida> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SaldosCorrida {
  SaldosCorrida({
    this.indStatusRecebimentoMotorista,
    this.indStatusPagamentoEstabelecimento,
    this.vlrTotal,
    this.vlrTotalRestaurante,
    this.corridaList,
  });

  int? indStatusRecebimentoMotorista;
  int? indStatusPagamentoEstabelecimento;
  double? vlrTotal;
  double? vlrTotalRestaurante;
  String? corridaList;

  factory SaldosCorrida.fromJson(Map<String, dynamic> json) => SaldosCorrida(
        indStatusRecebimentoMotorista:
            json["indStatusRecebimentoMotorista"] == null
                ? null
                : json["indStatusRecebimentoMotorista"],
        indStatusPagamentoEstabelecimento:
            json["indStatusPagamentoEstabelecimento"] == null
                ? null
                : json["indStatusPagamentoEstabelecimento"],
        vlrTotal: json["vlrTotal"] == null ? null : json["vlrTotal"].toDouble(),
        vlrTotalRestaurante: json["vlrTotalRestaurante"] == null
            ? null
            : json["vlrTotalRestaurante"].toDouble(),
        corridaList: json["corridaList"] == null ? null : json["corridaList"],
      );

  Map<String, dynamic> toJson() => {
        "indStatusRecebimentoMotorista": indStatusRecebimentoMotorista == null
            ? null
            : indStatusRecebimentoMotorista,
        "indStatusPagamentoEstabelecimento":
            indStatusPagamentoEstabelecimento == null
                ? null
                : indStatusPagamentoEstabelecimento,
        "vlrTotal": vlrTotal == null ? null : vlrTotal,
        "vlrTotalRestaurante":
            vlrTotalRestaurante == null ? null : vlrTotalRestaurante,
        "corridaList": corridaList == null ? null : corridaList,
      };
}
