// To parse this JSON data, do
//
//     final usuarioResponse = usuarioResponseFromJson(jsonString);

import 'dart:convert';

import 'package:delivery_front/shared/models/usuario.dart';

Usuario usuarioResponseFromJson(String str) =>
    Usuario.fromJson(json.decode(str));

String usuarioResponseToJson(Usuario data) => json.encode(data.toJson());

class Usuario {
  Usuario({
    this.jwt,
    this.codUsuario,
    this.desNome,
    this.desEmail,
    this.senha,
    this.dataCriacao,
    this.indTipo,
    this.usuarioResp,
    this.configSys,
  });

  String? jwt;
  int? codUsuario;
  String? desNome;
  String? desEmail;
  String? senha;
  dynamic? dataCriacao;
  int? indTipo;
  UsuarioResp? usuarioResp;
  ConfigSys? configSys;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        jwt: json["jwt"],
        codUsuario: json["codUsuario"],
        desNome: json["desNome"],
        desEmail: json["usuario"],
        senha: json["senha"],
        dataCriacao: json["dataCriacao"],
        indTipo: json["tipPerfil"],
        usuarioResp: UsuarioResp.fromJson(json["usuarioResp"]),
        configSys: json["configSys"] != null ? ConfigSys.fromJson(json["configSys"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "jwt": jwt,
        "codUsuario": codUsuario,
        "desNome": desNome,
        "usuario": desEmail,
        "senha": senha,
        "dataCriacao": dataCriacao,
        "tipPerfil": indTipo,
        "usuarioResp": usuarioResp!.toJson(),
        "configSys": configSys!.toJson(),
      };
}

class UsuarioResp {
  UsuarioResp({
    this.codUsuario,
    this.desNome,
    this.usuario,
    this.senha,
    this.reSenha,
    this.dataCriacao,
    this.tipPerfil,
    this.empresas,
    this.motoristas,
    this.indBloqueado,
    this.dthBloqueio,
  });

  int? codUsuario;
  String? desNome;
  String? usuario;
  String? senha;
  dynamic? reSenha;
  dynamic? dataCriacao;
  int? tipPerfil;
  int? indBloqueado = 0;
  dynamic? dthBloqueio;
  List<Empresa>? empresas;
  List<Motorista>? motoristas;

  factory UsuarioResp.fromJson(Map<String, dynamic> json) => UsuarioResp(
        codUsuario: json["codUsuario"],
        desNome: json["desNome"],
        usuario: json["usuario"],
        senha: json["senha"],
        reSenha: json["reSenha"],
        dataCriacao: json["dataCriacao"],
        tipPerfil: json["tipPerfil"],
        indBloqueado: json["indBloqueado"],
        dthBloqueio: json["dthBloqueio"],
        empresas: List<Empresa>.from(
            json["empresas"].map((x) => Empresa.fromJson(x))),
        motoristas: List<Motorista>.from(
            json["motoristas"].map((x) => Motorista.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "codUsuario": codUsuario,
        "desNome": desNome,
        "usuario": usuario,
        "senha": senha,
        "reSenha": reSenha,
        "dataCriacao": dataCriacao,
        "tipPerfil": tipPerfil,
        "indBloqueado": indBloqueado ?? 0,
        "dthBloqueio": dthBloqueio,
        "empresas": List<dynamic>.from(empresas!.map((x) => x.toJson())),
        "motoristas": List<dynamic>.from(motoristas!.map((x) => x.toJson())),
      };
}

class ConfigSys {
  ConfigSys({
    this.seq,
    this.vlrKmRodado,
    this.vlrPercentualDescontoMotorista,
    this.vlrTaxaApp,
  });

  int? seq;
  double? vlrKmRodado;
  double? vlrPercentualDescontoMotorista;
  double? vlrTaxaApp;

  factory ConfigSys.fromJson(Map<String, dynamic> json) => ConfigSys(
        seq: json["seq"],
        vlrKmRodado:
            json["vlrKmRodado"] == null ? null : json["vlrKmRodado"].toDouble(),
        vlrPercentualDescontoMotorista:
            json["vlrPercentualDescontoMotorista"] == null
                ? null
                : json["vlrPercentualDescontoMotorista"].toDouble(),
        vlrTaxaApp:
            json["vlrTaxaApp"] == null ? null : json["vlrTaxaApp"].toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "seq": seq,
        "vlrKmRodado": vlrKmRodado == null ? null : vlrKmRodado,
        "vlrPercentualDescontoMotorista": vlrPercentualDescontoMotorista == null
            ? null
            : vlrPercentualDescontoMotorista,
        "vlrTaxaApp": vlrTaxaApp == null ? null : vlrTaxaApp,
      };
}

class Empresa {
  Empresa({
    this.codEmpresa,
    this.desCpfCnpj,
    this.desNomeFantasia,
    this.desRazaoSocial,
    this.enderecos,
    this.contatos,
  });

  int? codEmpresa;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  List<Endereco>? enderecos;
  List<Contato>? contatos;

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        codEmpresa: json["codEmpresa"],
        desCpfCnpj: json["desCpfCnpj"],
        desNomeFantasia: json["desNomeFantasia"],
        desRazaoSocial: json["desRazaoSocial"],
        enderecos: List<Endereco>.from(
            json["enderecos"].map((x) => Endereco.fromJson(x))),
        contatos: List<Contato>.from(
            json["contatos"].map((x) => Contato.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "codEmpresa": codEmpresa,
        "desCpfCnpj": desCpfCnpj,
        "desNomeFantasia": desNomeFantasia,
        "desRazaoSocial": desRazaoSocial,
        "enderecos": List<dynamic>.from(enderecos!.map((x) => x.toJson())),
        "contatos": List<dynamic>.from(contatos!.map((x) => x.toJson())),
      };
}

class Contato {
  Contato({
    this.numSeq,
    this.desNumero,
    this.desEmail,
    this.dtaEdicao,
  });

  int? numSeq;
  String? desNumero;
  String? desEmail;
  DateTime? dtaEdicao;

  factory Contato.fromJson(Map<String, dynamic> json) => Contato(
        numSeq: json["numSeq"],
        desNumero: json["desNumero"],
        desEmail: json["desEmail"],
        dtaEdicao: DateTime.parse(json["dtaEdicao"]),
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq,
        "desNumero": desNumero,
        "desEmail": desEmail,
        "dtaEdicao": dtaEdicao!.toIso8601String(),
      };
}

class Endereco {
  Endereco({
    this.numSeq,
    this.desCep,
    this.desCidade,
    this.desEstado,
    this.desNumero,
    this.desPais,
    this.desRua,
    this.desTelefone,
    this.desBairro,
    this.imgComprovanteEnde,
    this.imgComprovanteDocumento,
    this.dtaEdicao,
    this.indInativo,
    this.desComplemento,
  });

  int? numSeq;
  String? desCep;
  String? desCidade;
  String? desEstado;
  String? desNumero;
  String? desPais;
  String? desRua;
  String? desTelefone;
  String? desBairro;
  dynamic? imgComprovanteEnde;
  dynamic? imgComprovanteDocumento;
  dynamic? dtaEdicao;
  int? indInativo;
  dynamic? desComplemento;

  factory Endereco.fromJson(Map<String, dynamic> json) => Endereco(
        numSeq: json["numSeq"],
        desCep: json["desCep"],
        desCidade: json["desCidade"],
        desEstado: json["desEstado"],
        desNumero: json["desNumero"],
        desPais: json["desPais"],
        desRua: json["desRua"],
        desTelefone: json["desTelefone"],
        desBairro: json["desBairro"] == null ? null : json["desBairro"],
        imgComprovanteEnde: json["imgComprovanteEnde"],
        imgComprovanteDocumento: json["imgComprovanteDocumento"],
        dtaEdicao: json["dtaEdicao"],
        indInativo: json["indInativo"],
        desComplemento: json["desComplemento"],
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq,
        "desCep": desCep,
        "desCidade": desCidade,
        "desEstado": desEstado,
        "desNumero": desNumero,
        "desPais": desPais,
        "desRua": desRua,
        "desTelefone": desTelefone,
        "desBairro": desBairro == null ? null : desBairro,
        "imgComprovanteEnde": imgComprovanteEnde,
        "imgComprovanteDocumento": imgComprovanteDocumento,
        "dtaEdicao": dtaEdicao,
        "indInativo": indInativo,
        "desComplemento": desComplemento,
      };
}

class Motorista {
  Motorista({
    this.codMotorista,
    this.desCpfCnpj,
    this.desNomeFantasia,
    this.desRazaoSocial,
    this.desPlaca,
    this.dtaNascimento,
    this.enderecos,
    this.contatos,
  });

  int? codMotorista;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  String? desPlaca;
  DateTime? dtaNascimento;
  List<Endereco>? enderecos;
  List<Contato>? contatos;

  factory Motorista.fromJson(Map<String, dynamic> json) => Motorista(
        codMotorista: json["codMotorista"],
        desCpfCnpj: json["desCpfCnpj"],
        desNomeFantasia: json["desNomeFantasia"],
        desRazaoSocial: json["desRazaoSocial"],
        desPlaca: json["desPlaca"],
        dtaNascimento: DateTime.parse(json["dtaNascimento"]),
        enderecos: List<Endereco>.from(
            json["enderecos"].map((x) => Endereco.fromJson(x))),
        contatos: List<Contato>.from(
            json["contatos"].map((x) => Contato.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "codMotorista": codMotorista,
        "desCpfCnpj": desCpfCnpj,
        "desNomeFantasia": desNomeFantasia,
        "desRazaoSocial": desRazaoSocial,
        "desPlaca": desPlaca,
        "dtaNascimento": dtaNascimento!.toIso8601String(),
        "enderecos": List<dynamic>.from(enderecos!.map((x) => x.toJson())),
        "contatos": List<dynamic>.from(contatos!.map((x) => x.toJson())),
      };
}
