// To parse this JSON data, do
//
//     final usuarioResponse = usuarioResponseFromJson(jsonString);

import 'dart:convert';

Usuario usuarioResponseFromJson(String str) =>
    Usuario.fromJson(json.decode(str));

String usuarioResponseToJson(Usuario data) => json.encode(data.toJson());

class Usuario {
  Usuario({
    this.jwt,
    this.codUsuario,
    this.desNome,
    this.usuario,
    this.desSenha,
    this.dataCriacao,
    this.indTipo,
    this.usuarioResp,
    this.indSucesso,
    this.indBloqueado,
    this.dthBloqueio,
    this.configSys,
    this.indOffline,
    this.desMsgErro,
  });

  String? jwt;
  int? codUsuario;
  String? desNome;
  String? desSenha;
  dynamic? dataCriacao;
  int? indTipo = 1;
  UsuarioResp? usuarioResp;
  String? usuario;
  int? indSucesso = 0;
  int? indBloqueado = 0;
  int? indOffline = 0;
  dynamic? dthBloqueio;
  ConfigSys? configSys;
  String? desMsgErro; // Mensagem de erro retornada pela API

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      return Usuario(
        jwt: json["jwt"] as String?,
        codUsuario: json["codUsuario"] is int 
            ? json["codUsuario"] as int?
            : (json["codUsuario"] is String && json["codUsuario"] != null)
                ? int.tryParse(json["codUsuario"] as String)
                : json["codUsuario"] as int?,
        desNome: json["desNome"] as String?,
        desSenha: json["senha"] as String?,
        dataCriacao: json["dataCriacao"],
        indTipo: json["tipPerfil"] is int
            ? json["tipPerfil"] as int?
            : (json["tipPerfil"] is String && json["tipPerfil"] != null)
                ? int.tryParse(json["tipPerfil"] as String)
                : json["tipPerfil"] as int?,
        indSucesso: json["indSucesso"] is int
            ? json["indSucesso"] as int?
            : (json["indSucesso"] is String && json["indSucesso"] != null)
                ? int.tryParse(json["indSucesso"] as String)
                : json["indSucesso"] as int? ?? 0,
        usuarioResp: json["usuarioResp"] != null
            ? UsuarioResp.fromJson(json["usuarioResp"] as Map<String, dynamic>)
            : null,
        usuario: json["usuario"] as String?,
        indOffline: json["indOffline"] is int
            ? json["indOffline"] as int?
            : (json["indOffline"] is String && json["indOffline"] != null)
                ? int.tryParse(json["indOffline"] as String)
                : json["indOffline"] as int? ?? 0,
        indBloqueado: json["indBloqueado"] is int
            ? json["indBloqueado"] as int?
            : (json["indBloqueado"] is String && json["indBloqueado"] != null)
                ? int.tryParse(json["indBloqueado"] as String)
                : json["indBloqueado"] as int? ?? 0,
        dthBloqueio: json["dthBloqueio"],
        configSys: json["configSys"] != null
            ? ConfigSys.fromJson(json["configSys"] as Map<String, dynamic>)
            : null,
        desMsgErro: json["desMsgErro"] as String? ?? 
                    json["msgErro"] as String? ??
                    json["message"] as String? ??
                    json["mensagem"] as String?,
      );
    } catch (e, stackTrace) {
      // Log detalhado do erro de parsing
      throw Exception('Erro ao fazer parse de Usuario: $e. JSON keys: ${json.keys.toList()}');
    }
  }

  Map<String, dynamic> toJson() => {
        "jwt": jwt ?? "",
        "codUsuario": codUsuario ?? "",
        "desNome": desNome ?? "",
        "usuario": usuario ?? "",
        "senha": desSenha ?? "",
        "dataCriacao": dataCriacao ?? "",
        "indSucesso": indSucesso ?? 0,
        "tipPerfil": indTipo ?? "",
        "usuarioResp": usuarioResp?.toJson() ?? "",
        "indBloqueado": indBloqueado ?? 0,
        "dthBloqueio": dthBloqueio,
        "configSys": configSys?.toJson() ?? "",
        "indOffline": indOffline ?? 0,
        "desMsgErro": desMsgErro,
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
    this.desLatitude,
    this.desLongitude,
    this.indBloqueado,
    this.dthBloqueio,
    this.indOffline,
  });

  int? codUsuario;
  String? desNome;
  String? usuario;
  String? senha;
  dynamic? reSenha;
  dynamic? dataCriacao;
  int? tipPerfil;
  List<Empresa>? empresas;
  List<Motorista>? motoristas;
  double? desLatitude;
  double? desLongitude;
  int? indBloqueado = 0;
  dynamic? dthBloqueio;
  int? indOffline;

  factory UsuarioResp.fromJson(Map<String, dynamic> json) => UsuarioResp(
        codUsuario: json["codUsuario"] is int
            ? json["codUsuario"] as int?
            : (json["codUsuario"] is String && json["codUsuario"] != null)
                ? int.tryParse(json["codUsuario"] as String)
                : json["codUsuario"] as int?,
        desNome: json["desNome"] as String?,
        usuario: json["usuario"] as String?,
        senha: json["senha"] as String?,
        reSenha: json["reSenha"],
        dataCriacao: json["dataCriacao"],
        tipPerfil: json["tipPerfil"] is int
            ? json["tipPerfil"] as int?
            : (json["tipPerfil"] is String && json["tipPerfil"] != null)
                ? int.tryParse(json["tipPerfil"] as String)
                : json["tipPerfil"] as int?,
        desLatitude: json["desLatitude"] is double
            ? json["desLatitude"] as double?
            : (json["desLatitude"] is String && json["desLatitude"] != null)
                ? double.tryParse(json["desLatitude"] as String)
                : (json["desLatitude"] is num)
                    ? (json["desLatitude"] as num).toDouble()
                    : json["desLatitude"] as double?,
        desLongitude: json["desLongitude"] is double
            ? json["desLongitude"] as double?
            : (json["desLongitude"] is String && json["desLongitude"] != null)
                ? double.tryParse(json["desLongitude"] as String)
                : (json["desLongitude"] is num)
                    ? (json["desLongitude"] as num).toDouble()
                    : json["desLongitude"] as double?,
        indBloqueado: json["indBloqueado"] is int
            ? json["indBloqueado"] as int?
            : (json["indBloqueado"] is String && json["indBloqueado"] != null)
                ? int.tryParse(json["indBloqueado"] as String)
                : json["indBloqueado"] as int? ?? 0,
        dthBloqueio: json["dthBloqueio"],
        indOffline: json["indOffline"] is int
            ? json["indOffline"] as int?
            : (json["indOffline"] is String && json["indOffline"] != null)
                ? int.tryParse(json["indOffline"] as String)
                : json["indOffline"] as int?,
        empresas: json["empresas"] != null && json["empresas"] is List
            ? List<Empresa>.from(
                (json["empresas"] as List).map((x) => Empresa.fromJson(x as Map<String, dynamic>)))
            : null,
        motoristas: json["motoristas"] != null && json["motoristas"] is List
            ? List<Motorista>.from(
                (json["motoristas"] as List).map((x) => Motorista.fromJson(x as Map<String, dynamic>)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "codUsuario": codUsuario ?? null,
        "desNome": desNome ?? "",
        "usuario": usuario ?? "",
        "senha": senha ?? "",
        "reSenha": reSenha ?? "",
        "dataCriacao": dataCriacao ?? null,
        "tipPerfil": tipPerfil ?? null,
        "desLongitude": desLongitude ?? null,
        "desLatitude": desLatitude ?? null,
        "indBloqueado": indBloqueado ?? 0,
        "dthBloqueio": dthBloqueio,
        "indOffline": indOffline,
        "empresas": empresas != null
            ? List<dynamic>.from(empresas!.map((x) => x.toJson()))
            : null,
        "motoristas": motoristas != null
            ? List<dynamic>.from(motoristas!.map((x) => x.toJson()))
            : null,
      };
}

class ConfigSys {
  ConfigSys({
    this.seq,
    this.vlrKmRodado,
    this.vlrPercentualDescontoMotorista,
    this.vlrTaxaApp,
    this.raioBuscaCorridas,
  });

  int? seq;
  double? vlrKmRodado;
  double? vlrPercentualDescontoMotorista;
  double? vlrTaxaApp;
  int? raioBuscaCorridas;

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
        raioBuscaCorridas: json["raioBuscaCorridas"],
      );

  Map<String, dynamic> toJson() => {
        "seq": seq,
        "vlrKmRodado": vlrKmRodado == null ? null : vlrKmRodado,
        "vlrPercentualDescontoMotorista": vlrPercentualDescontoMotorista == null
            ? null
            : vlrPercentualDescontoMotorista,
        "vlrTaxaApp": vlrTaxaApp == null ? null : vlrTaxaApp,
        "raioBuscaCorridas":
            raioBuscaCorridas == null ? null : raioBuscaCorridas,
      };
}

empresasFromJson(String str) =>
    List<Empresa>.from(json.decode(str).map((x) => Empresa.fromJson(x)));

class Empresa {
  Empresa({
    this.codEmpresa,
    this.desCpfCnpj,
    this.desNomeFantasia,
    this.desRazaoSocial,
    this.enderecos,
    this.contatos,
    this.user,
    this.desCartao,
    this.desNomeCartao,
    this.desFotoPerfil,
  });

  int? codEmpresa;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  String? desCartao;
  String? desNomeCartao;
  String? desFotoPerfil;
  List<Endereco>? enderecos;
  List<Contato>? contatos;
  Usuario? user;

  factory Empresa.fromJson(Map<String, dynamic> json) => Empresa(
        codEmpresa: json["codEmpresa"] is int
            ? json["codEmpresa"] as int?
            : (json["codEmpresa"] is String && json["codEmpresa"] != null)
                ? int.tryParse(json["codEmpresa"] as String)
                : json["codEmpresa"] as int?,
        desCpfCnpj: json["desCpfCnpj"] as String?,
        user: json["user"] == null ? null : Usuario.fromJson(json["user"] as Map<String, dynamic>),
        desNomeFantasia: json["desNomeFantasia"] as String?,
        desRazaoSocial: json["desRazaoSocial"] as String?,
        desCartao: json["desCartao"] as String?,
        desNomeCartao: json["desNomeCartao"] as String?,
        desFotoPerfil: json["desFotoPerfil"] as String?,
        enderecos: json["enderecos"] != null && json["enderecos"] is List
            ? List<Endereco>.from(
                (json["enderecos"] as List).map((x) => Endereco.fromJson(x as Map<String, dynamic>)))
            : null,
        contatos: json["contatos"] != null && json["contatos"] is List
            ? List<Contato>.from(
                (json["contatos"] as List).map((x) => Contato.fromJson(x as Map<String, dynamic>)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "codEmpresa": codEmpresa ?? "",
        "desCpfCnpj": desCpfCnpj ?? "",
        "desNomeFantasia": desNomeFantasia ?? "",
        "desRazaoSocial": desRazaoSocial ?? "",
        "desCartao": desCartao ?? "",
        "desNomeCartao": desNomeCartao ?? "",
        "desFotoPerfil": desFotoPerfil ?? "",
        "enderecos": enderecos != null
            ? List<dynamic>.from(enderecos!.map((x) => x.toJson()))
            : null,
        "contatos": contatos != null
            ? List<dynamic>.from(contatos!.map((x) => x.toJson()))
            : null,
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
        dtaEdicao: json["dtaEdicao"] == null
            ? null
            : DateTime.parse(json["dtaEdicao"]),
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq ?? "",
        "desNumero": desNumero ?? "",
        "desEmail": desEmail ?? "",
        "dtaEdicao": dtaEdicao?.toIso8601String() ?? null,
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
        desBairro: json["desBairro"] == null ? "" : json["desBairro"],
        imgComprovanteEnde: json["imgComprovanteEnde"],
        imgComprovanteDocumento: json["imgComprovanteDocumento"],
        dtaEdicao: json["dtaEdicao"],
        indInativo: json["indInativo"],
        desComplemento: json["desComplemento"],
      );

  Map<String, dynamic> toJson() => {
        "numSeq": numSeq ?? null,
        "desCep": desCep ?? "",
        "desCidade": desCidade ?? "",
        "desEstado": desEstado ?? "",
        "desNumero": desNumero ?? "",
        "desPais": desPais ?? "",
        "desRua": desRua ?? "",
        "desTelefone": desTelefone ?? "",
        "desBairro": desBairro == null ? null : desBairro,
        "imgComprovanteEnde": imgComprovanteEnde ?? "",
        "imgComprovanteDocumento": imgComprovanteDocumento ?? "",
        "dtaEdicao": dtaEdicao ?? null,
        "indInativo": indInativo ?? null,
        "desComplemento": desComplemento ?? "",
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
    this.user,
    this.desCarteira,
    this.desNomeCarteira,
    this.desCartao,
    this.desNomeCartao,
    this.desFotoPerfil,
    this.desTipoMoto,
    this.desCorMoto,
  });

  int? codMotorista;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  String? desPlaca;
  DateTime? dtaNascimento;
  String? desCarteira;
  String? desNomeCarteira;
  String? desCartao;
  String? desNomeCartao;
  String? desFotoPerfil;
  String? desTipoMoto;
  String? desCorMoto;
  List<Endereco>? enderecos;
  List<Contato>? contatos;
  Usuario? user;

  factory Motorista.fromJson(Map<String, dynamic> json) => Motorista(
        codMotorista: json["codMotorista"],
        desCpfCnpj: json["desCpfCnpj"],
        user: json["user"] == null ? null : Usuario.fromJson(json["user"]),
        desNomeFantasia: json["desNomeFantasia"],
        desRazaoSocial: json["desRazaoSocial"],
        desPlaca: json["desPlaca"],
        desCarteira: json["desCarteira"],
        desNomeCarteira: json["desNomeCarteira"],
        desCartao: json["desCartao"],
        desNomeCartao: json["desNomeCartao"],
        desFotoPerfil: json["desFotoPerfil"] as String?,
        desTipoMoto: json["desTipoMoto"] as String?,
        desCorMoto: json["desCorMoto"] as String?,
        dtaNascimento:
            json["dtaNascimento"] != null && json["dtaNascimento"] != ""
                ? DateTime.parse(json["dtaNascimento"])
                : null,
        enderecos: json["enderecos"] != null
            ? List<Endereco>.from(
                json["enderecos"].map((x) => Endereco.fromJson(x)))
            : null,
        contatos: json["contatos"] != null
            ? List<Contato>.from(
                json["contatos"].map((x) => Contato.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "codMotorista": codMotorista ?? null,
        "desCpfCnpj": desCpfCnpj ?? "",
        "desNomeFantasia": desNomeFantasia ?? "",
        "desRazaoSocial": desRazaoSocial ?? "",
        "desPlaca": desPlaca ?? "",
        "desCarteira": desCarteira ?? "",
        "desNomeCarteira": desNomeCarteira ?? "",
        "desCartao": desCartao ?? "",
        "desNomeCartao": desNomeCartao ?? "",
        "desFotoPerfil": desFotoPerfil ?? "",
        "desTipoMoto": desTipoMoto ?? "",
        "desCorMoto": desCorMoto ?? "",
        "dtaNascimento": dtaNascimento?.toIso8601String() ?? "",
        "enderecos": enderecos != null
            ? List<dynamic>.from(enderecos!.map((x) => x.toJson()))
            : null,
        "contatos": contatos != null
            ? List<dynamic>.from(contatos!.map((x) => x.toJson()))
            : null,
      };
}
