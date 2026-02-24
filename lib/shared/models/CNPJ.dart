import 'dart:convert';

/// Modelo para resposta da API BrasilAPI - Consulta CNPJ
/// https://brasilapi.com.br/api/cnpj/v1/{cnpj}
class CnpjResponse {
  String? cnpj;
  String? razaoSocial;
  String? nomeFantasia;
  String? descricaoSituacaoCadastral;
  String? descricaoTipoLogradouro;
  String? logradouro;
  String? numero;
  String? complemento;
  String? bairro;
  String? cep;
  String? uf;
  String? municipio;
  String? telefone;
  String? email;
  String? porte;
  String? abertura;
  String? naturezaJuridica;
  List<CnpjAtividade>? atividadesPrincipais;
  List<CnpjAtividade>? atividadesSecundarias;
  List<CnpjSocio>? socios;
  CnpjEndereco? endereco;

  CnpjResponse({
    this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.descricaoSituacaoCadastral,
    this.descricaoTipoLogradouro,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cep,
    this.uf,
    this.municipio,
    this.telefone,
    this.email,
    this.porte,
    this.abertura,
    this.naturezaJuridica,
    this.atividadesPrincipais,
    this.atividadesSecundarias,
    this.socios,
    this.endereco,
  });

  factory CnpjResponse.fromJson(Map<String, dynamic> json) {
    return CnpjResponse(
      cnpj: json["cnpj"],
      razaoSocial: json["razao_social"],
      nomeFantasia: json["nome_fantasia"],
      descricaoSituacaoCadastral: json["descricao_situacao_cadastral"],
      descricaoTipoLogradouro: json["descricao_tipo_logradouro"],
      logradouro: json["logradouro"],
      numero: json["numero"],
      complemento: json["complemento"],
      bairro: json["bairro"],
      cep: json["cep"],
      uf: json["uf"],
      municipio: json["municipio"],
      telefone: json["telefone"],
      email: json["email"],
      porte: json["porte"],
      abertura: json["abertura"],
      naturezaJuridica: json["natureza_juridica"],
      atividadesPrincipais: json["atividades_principais"] != null
          ? (json["atividades_principais"] as List)
              .map((e) => CnpjAtividade.fromJson(e))
              .toList()
          : null,
      atividadesSecundarias: json["atividades_secundarias"] != null
          ? (json["atividades_secundarias"] as List)
              .map((e) => CnpjAtividade.fromJson(e))
              .toList()
          : null,
      socios: json["socios"] != null
          ? (json["socios"] as List)
              .map((e) => CnpjSocio.fromJson(e))
              .toList()
          : null,
      endereco: json["endereco"] != null
          ? CnpjEndereco.fromJson(json["endereco"])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "cnpj": cnpj,
        "razao_social": razaoSocial,
        "nome_fantasia": nomeFantasia,
        "descricao_situacao_cadastral": descricaoSituacaoCadastral,
        "descricao_tipo_logradouro": descricaoTipoLogradouro,
        "logradouro": logradouro,
        "numero": numero,
        "complemento": complemento,
        "bairro": bairro,
        "cep": cep,
        "uf": uf,
        "municipio": municipio,
        "telefone": telefone,
        "email": email,
        "porte": porte,
        "abertura": abertura,
        "natureza_juridica": naturezaJuridica,
        "atividades_principais": atividadesPrincipais?.map((e) => e.toJson()).toList(),
        "atividades_secundarias": atividadesSecundarias?.map((e) => e.toJson()).toList(),
        "socios": socios?.map((e) => e.toJson()).toList(),
        "endereco": endereco?.toJson(),
      };
}

class CnpjAtividade {
  String? codigo;
  String? descricao;

  CnpjAtividade({this.codigo, this.descricao});

  factory CnpjAtividade.fromJson(Map<String, dynamic> json) => CnpjAtividade(
        codigo: json["codigo"],
        descricao: json["descricao"],
      );

  Map<String, dynamic> toJson() => {
        "codigo": codigo,
        "descricao": descricao,
      };
}

class CnpjSocio {
  String? nome;
  String? cpfCnpj;
  String? qualificacao;
  String? participacao;

  CnpjSocio({this.nome, this.cpfCnpj, this.qualificacao, this.participacao});

  factory CnpjSocio.fromJson(Map<String, dynamic> json) => CnpjSocio(
        nome: json["nome"],
        cpfCnpj: json["cpf_cnpj"],
        qualificacao: json["qualificacao"],
        participacao: json["participacao"],
      );

  Map<String, dynamic> toJson() => {
        "nome": nome,
        "cpf_cnpj": cpfCnpj,
        "qualificacao": qualificacao,
        "participacao": participacao,
      };
}

class CnpjEndereco {
  String? logradouro;
  String? numero;
  String? complemento;
  String? bairro;
  String? cep;
  String? uf;
  String? municipio;

  CnpjEndereco({
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cep,
    this.uf,
    this.municipio,
  });

  factory CnpjEndereco.fromJson(Map<String, dynamic> json) => CnpjEndereco(
        logradouro: json["logradouro"],
        numero: json["numero"],
        complemento: json["complemento"],
        bairro: json["bairro"],
        cep: json["cep"],
        uf: json["uf"],
        municipio: json["municipio"],
      );

  Map<String, dynamic> toJson() => {
        "logradouro": logradouro,
        "numero": numero,
        "complemento": complemento,
        "bairro": bairro,
        "cep": cep,
        "uf": uf,
        "municipio": municipio,
      };
}

