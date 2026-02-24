// To parse this JSON data, do
//
//     final dadosCorridas = dadosCorridasFromJson(jsonString);

import 'dart:convert';

List<DadosCorridas> dadosCorridasFromJson(String str) =>
    List<DadosCorridas>.from(
        json.decode(str).map((x) => DadosCorridas.fromJson(x)));

String dadosCorridasToJson(List<DadosCorridas> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DadosCorridas {
  DadosCorridas(
      {this.numSeq,
      this.codEmpresa,
      this.distance,
      this.qtdCorridas,
      this.indStatusCorrida,
      this.totalMotoristasOnline});

  int? numSeq;
  int? codEmpresa;
  double? distance;
  int? qtdCorridas;
  int? indStatusCorrida;
  int? totalMotoristasOnline;

  factory DadosCorridas.fromJson(Map<String, dynamic> json) => DadosCorridas(
        numSeq: json["numSeq"] == null ? null : json["numSeq"],
        codEmpresa: json["codEmpresa"] == null ? null : json["codEmpresa"],
        distance: json["distance"] == null || json["distance"] == 0
            ? null
            : json["distance"],
        qtdCorridas: json["qtdCorridas"] == null ? 0 : json["qtdCorridas"],
        indStatusCorrida:
            json["indStatusCorrida"] == null ? null : json["indStatusCorrida"],
        totalMotoristasOnline: json["totalMotoristasOnline"] == null
            ? null
            : json["totalMotoristasOnline"],
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq == null ? null : numSeq,
        "codEmpresa": codEmpresa == null ? null : codEmpresa,
        "distance": distance == null ? null : distance,
        "qtdCorridas": qtdCorridas == null ? null : qtdCorridas,
        "indStatusCorrida": indStatusCorrida == null ? null : indStatusCorrida,
        "totalMotoristasOnline":
            totalMotoristasOnline == null ? null : totalMotoristasOnline,
      };
}
