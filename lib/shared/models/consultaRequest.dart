// To parse this JSON data, do
//
//     final consultaRequest = consultaRequestFromJson(jsonString);

import 'dart:convert';

import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';

ConsultaRequest consultaRequestFromJson(String str) =>
    ConsultaRequest.fromJson(json.decode(str));

String consultaRequestToJson(ConsultaRequest data) =>
    json.encode(data.toJson());

class ConsultaRequest {
  ConsultaRequest({
    this.numSeq,
    this.codEmpresa,
    this.codMotorista,
    this.dtaIni,
    this.dtaFim,
    this.inInfro,
  });

  int? numSeq;
  int? codEmpresa;
  int? codMotorista;
  DateTime? dtaIni;
  DateTime? dtaFim;
  String? inInfro;

  factory ConsultaRequest.fromJson(Map<String, dynamic> json) =>
      ConsultaRequest(
        numSeq: json["numSeq"],
        codEmpresa: json["codEmpresa"],
        codMotorista: json["codMotorista"],
        dtaIni: json["dtaIni"] == null ? null : json["dtaIni"],
        dtaFim: json["dtaFim"] == null ? null : json["dtaFim"],
        inInfro: json["inInfro"] == null ? null : json["inInfro"],
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq,
        "codEmpresa": codEmpresa,
        "codMotorista": codMotorista,
        "dtaIni": dtaIni == null
            ? null
            : dtaIni,
        "dtaFim": dtaFim == null
            ? null
            : dtaFim,
        "inInfro": inInfro == null ? null : inInfro,
      };
}
