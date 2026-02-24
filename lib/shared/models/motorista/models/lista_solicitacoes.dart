// To parse this JSON data, do
//
//     final solicitacaoMotorista = solicitacaoMotoristaFromJson(jsonString);

import 'dart:convert';

import 'package:delivery_front/shared/models/usuario.dart';
import 'package:delivery_front/shared/models/destino_corrida.dart';

class SolicitacaoMotorista {
  int? numSeq;
  int? codEmpresa;
  int? codMotorista;
  DateTime? dthSolicitacao;
  DateTime? dthAceite;
  DateTime? dthInicioCorrida;
  DateTime? dthFinalizacaoCorrida;
  DateTime? dthAgendamento; // Data/hora agendada para corrida futura
  int? indStatusCorrida;
  int? indNotaCorrida;
  String? desObsCorrida;
  double? desLatitudeEntrega;
  double? desLongitudeEntrega;
  String? desEnderecoEntrega;
  String? desNumeroEndereco;
  DbEmpresasByCodEmpresa? dbEmpresasByCodEmpresa;
  DbMotoristasByCodMotorista? dbMotoristasByCodMotorista;
  List<DbLocalizacoesUsuariosByNumSeq>? dbLocalizacoesUsuariosByNumSeq;
  double? qtdKmCorrida;
  String? enderecoEmpresa;

  double? vlrTotalMotorista;
  double? vlrTaxaRestaurante;

  double? vlrKmRodado;
  //Distancia até o restaurante para ir buscar pedido
  double? distance;
  double? vlrTaxaApp;
  String? desComplemento;
  int? indTipoCorrida;
  String? desTelefone;
  List<DestinoCorrida>? destinos; // Lista de destinos para corridas com múltiplos destinos

  SolicitacaoMotorista({
    this.numSeq,
    this.codEmpresa,
    this.codMotorista,
    this.dthSolicitacao,
    this.dthAceite,
    this.dthInicioCorrida,
    this.dthFinalizacaoCorrida,
    this.dthAgendamento,
    this.indStatusCorrida,
    this.indNotaCorrida,
    this.desObsCorrida,
    this.desLatitudeEntrega,
    this.desLongitudeEntrega,
    this.desEnderecoEntrega,
    this.desNumeroEndereco,
    this.dbEmpresasByCodEmpresa,
    this.dbMotoristasByCodMotorista,
    this.dbLocalizacoesUsuariosByNumSeq,
    this.qtdKmCorrida,
    this.vlrTotalMotorista,
    this.vlrTaxaRestaurante,
    this.vlrKmRodado,
    this.distance,
    this.enderecoEmpresa,
    this.vlrTaxaApp,
    this.desComplemento,
    this.indTipoCorrida,
    this.desTelefone,
    this.destinos,
  });

  List<SolicitacaoMotorista> solicitacaoMotoristaFromJson(String str) =>
      List<SolicitacaoMotorista>.from(
          json.decode(str).map((x) => SolicitacaoMotorista.fromJson(x)));

  String solicitacaoMotoristaToJson(List<SolicitacaoMotorista> data) =>
      json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

  SolicitacaoMotorista.fromJson(Map<String, dynamic> json) {
    numSeq = json['numSeq'];
    codEmpresa = json['codEmpresa'];
    codMotorista = json['codMotorista'];
    dthSolicitacao = DateTime.parse(json['dthSolicitacao']);
    dthAceite =
        json['dthAceite'] != null ? DateTime.parse(json['dthAceite']) : null;
    dthInicioCorrida = json['dthInicioCorrida'] != null
        ? DateTime.parse(json['dthInicioCorrida'])
        : null;
    dthFinalizacaoCorrida = json['dthFinalizacaoCorrida'] != null
        ? DateTime.parse(json['dthFinalizacaoCorrida'])
        : null;
    dthAgendamento = json['dthAgendamento'] != null
        ? DateTime.parse(json['dthAgendamento'])
        : null;
    indStatusCorrida = json['indStatusCorrida'];
    indNotaCorrida = json['indNotaCorrida'];
    desObsCorrida = json['desObsCorrida'];
    desLatitudeEntrega =
        json['desLatitudeEntrega'] != null ? json["desLatitudeEntrega"] : null;
    desLongitudeEntrega = json['desLongitudeEntrega'] != null
        ? json['desLongitudeEntrega']
        : null;
    desEnderecoEntrega = json['desEnderecoEntrega'];
    desNumeroEndereco = json['desNumeroEndereco'];
    dbEmpresasByCodEmpresa = json['dbEmpresasByCodEmpresa'] != null
        ? new DbEmpresasByCodEmpresa.fromJson(json['dbEmpresasByCodEmpresa'])
        : null;
    dbMotoristasByCodMotorista = json['dbMotoristasByCodMotorista'] != null
        ? new DbMotoristasByCodMotorista.fromJson(
            json['dbMotoristasByCodMotorista'])
        : null;

    enderecoEmpresa = json['enderecoEmpresa'];
    desComplemento = json['desComplemento'];
    desTelefone = json['desTelefone'];

    // Carrega lista de destinos se existir
    if (json['destinos'] != null) {
      destinos = (json['destinos'] as List)
          .map((v) => DestinoCorrida.fromJson(v as Map<String, dynamic>))
          .toList();
    } else {
      // Se não tiver lista de destinos, cria um destino único a partir dos campos antigos
      // (compatibilidade com API antiga)
      if (desEnderecoEntrega != null && desEnderecoEntrega!.isNotEmpty) {
        destinos = [
          DestinoCorrida(
            desEnderecoEntrega: desEnderecoEntrega,
            desNumeroEndereco: desNumeroEndereco,
            desComplemento: desComplemento,
            desLatitudeEntrega: desLatitudeEntrega,
            desLongitudeEntrega: desLongitudeEntrega,
            desTelefone: desTelefone,
            ordem: 1,
          ),
        ];
      }
    }

    qtdKmCorrida = json['qtdKmCorrida'];
    vlrTaxaApp = json['vlrTaxaApp'];
    vlrTotalMotorista = json['vlrTotalMotorista'];
    vlrTaxaRestaurante = json['vlrTaxaRestaurante'];
    vlrKmRodado = json['vlrKmRodado'];
    indTipoCorrida = json['indTipoCorrida'];
    distance = json['distance'];
    if (json['dbLocalizacoesUsuariosByNumSeq'] != null) {
      dbLocalizacoesUsuariosByNumSeq = <DbLocalizacoesUsuariosByNumSeq>[];
      json['dbLocalizacoesUsuariosByNumSeq'].forEach((v) {
        dbLocalizacoesUsuariosByNumSeq!
            .add(new DbLocalizacoesUsuariosByNumSeq.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['numSeq'] = this.numSeq;
    data['codEmpresa'] = this.codEmpresa;
    data['codMotorista'] = this.codMotorista;
    data['dthSolicitacao'] = this.dthSolicitacao;
    data['dthAceite'] = this.dthAceite;
    data['dthInicioCorrida'] = this.dthInicioCorrida;
    data['dthFinalizacaoCorrida'] = this.dthFinalizacaoCorrida;
    data['dthAgendamento'] = this.dthAgendamento;
    data['indStatusCorrida'] = this.indStatusCorrida;
    data['indNotaCorrida'] = this.indNotaCorrida;
    data['desObsCorrida'] = this.desObsCorrida;
    data['desLatitudeEntrega'] = this.desLatitudeEntrega;
    data['desLongitudeEntrega'] = this.desLongitudeEntrega;
    data['desEnderecoEntrega'] = this.desEnderecoEntrega;
    data['desNumeroEndereco'] = this.desNumeroEndereco;
    data['qtdKmCorrida'] = this.qtdKmCorrida;
    data['vlrTotalMotorista'] = this.vlrTotalMotorista;
    data['vlrTaxaRestaurante'] = this.vlrTaxaRestaurante;
    data['vlrKmRodado'] = this.vlrKmRodado;
    data['distance'] = this.distance;
    data['vlrTaxaApp'] = this.vlrTaxaApp;
    data['enderecoEmpresa'] = this.enderecoEmpresa;
    data['desComplemento'] = this.desComplemento;
    data['indTipoCorrida'] = this.indTipoCorrida;
    data['desTelefone'] = this.desTelefone;
    if (this.destinos != null) {
      data['destinos'] = this.destinos!.map((v) => v.toJson()).toList();
    }
    if (this.dbEmpresasByCodEmpresa != null) {
      data['dbEmpresasByCodEmpresa'] = this.dbEmpresasByCodEmpresa!.toJson();
    }
    if (this.dbMotoristasByCodMotorista != null) {
      data['dbMotoristasByCodMotorista'] =
          this.dbMotoristasByCodMotorista!.toJson();
    }
    if (this.dbLocalizacoesUsuariosByNumSeq != null) {
      data['dbLocalizacoesUsuariosByNumSeq'] =
          this.dbLocalizacoesUsuariosByNumSeq!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DbEmpresasByCodEmpresa {
  int? codEmpresa;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  List<Endereco>? enderecos;
  Null? contatos;
  double? desLatitude;
  double? desLongitude;

  DbEmpresasByCodEmpresa(
      {this.codEmpresa,
      this.desCpfCnpj,
      this.desNomeFantasia,
      this.desRazaoSocial,
      this.enderecos,
      this.contatos,
      this.desLatitude,
      this.desLongitude});

  DbEmpresasByCodEmpresa.fromJson(Map<String, dynamic> json) {
    codEmpresa = json['codEmpresa'];
    desCpfCnpj = json['desCpfCnpj'];
    desNomeFantasia = json['desNomeFantasia'];
    desRazaoSocial = json['desRazaoSocial'];
    enderecos =
        List<Endereco>.from(json["enderecos"].map((x) => Endereco.fromJson(x)));
    contatos = json['contatos'];
    desLatitude = json['desLatitude'];
    desLongitude = json['desLongitude'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codEmpresa'] = this.codEmpresa;
    data['desCpfCnpj'] = this.desCpfCnpj;
    data['desNomeFantasia'] = this.desNomeFantasia;
    data['desRazaoSocial'] = this.desRazaoSocial;
    data['enderecos'] = enderecos != null
        ? List<dynamic>.from(enderecos!.map((x) => x.toJson()))
        : null;
    data['contatos'] = this.contatos;
    data['desLatitude'] = this.desLatitude;
    data['desLongitude'] = this.desLongitude;
    return data;
  }
}

class DbMotoristasByCodMotorista {
  int? codMotorista;
  String? desCpfCnpj;
  String? desNomeFantasia;
  String? desRazaoSocial;
  String? desPlaca;
  String? dtaNascimento;
  Null? enderecos;
  Null? contatos;

  DbMotoristasByCodMotorista(
      {this.codMotorista,
      this.desCpfCnpj,
      this.desNomeFantasia,
      this.desRazaoSocial,
      this.desPlaca,
      this.dtaNascimento,
      this.enderecos,
      this.contatos});

  DbMotoristasByCodMotorista.fromJson(Map<String, dynamic> json) {
    codMotorista = json['codMotorista'];
    desCpfCnpj = json['desCpfCnpj'];
    desNomeFantasia = json['desNomeFantasia'];
    desRazaoSocial = json['desRazaoSocial'];
    desPlaca = json['desPlaca'];
    dtaNascimento = json['dtaNascimento'];
    enderecos = json['enderecos'];
    contatos = json['contatos'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codMotorista'] = this.codMotorista;
    data['desCpfCnpj'] = this.desCpfCnpj;
    data['desNomeFantasia'] = this.desNomeFantasia;
    data['desRazaoSocial'] = this.desRazaoSocial;
    data['desPlaca'] = this.desPlaca;
    data['dtaNascimento'] = this.dtaNascimento;
    data['enderecos'] = this.enderecos;
    data['contatos'] = this.contatos;
    return data;
  }
}

class DbLocalizacoesUsuariosByNumSeq {
  int? codUsuario;
  String? desLatitude;
  String? desLongitude;
  int? numSeqCorrida;
  DateTime? dthHorarioLocalizacao;

  DbLocalizacoesUsuariosByNumSeq(
      {this.codUsuario,
      this.desLatitude,
      this.desLongitude,
      this.numSeqCorrida,
      this.dthHorarioLocalizacao});

  DbLocalizacoesUsuariosByNumSeq.fromJson(Map<String, dynamic> json) {
    codUsuario = json['codUsuario'];
    desLatitude = json['desLatitude'];
    desLongitude = json['desLongitude'];
    numSeqCorrida = json['numSeqCorrida'];
    dthHorarioLocalizacao = json['dthHorarioLocalizacao'] != null
        ? DateTime.parse(json['dthHorarioLocalizacao'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codUsuario'] = this.codUsuario;
    data['desLatitude'] = this.desLatitude;
    data['desLongitude'] = this.desLongitude;
    data['numSeqCorrida'] = this.numSeqCorrida;
    data['dthHorarioLocalizacao'] = this.dthHorarioLocalizacao;
    return data;
  }
}
