class SolicitacaoMotorista2 {
  int? codUsuario;
  String? dtaSolicitacao;
  int? indFinalizado;
  String? desNome;
  String? descricaoChamado;
  double? latitude;
  double? longitude;

  SolicitacaoMotorista2({
    this.codUsuario,
    this.dtaSolicitacao,
    this.indFinalizado,
    this.desNome,
    this.descricaoChamado,
    this.latitude,
    this.longitude,
  });

  factory SolicitacaoMotorista2.fromJson(Map<String, dynamic> json) {
    return SolicitacaoMotorista2(
      codUsuario: json['numSeq'] as int?,
      dtaSolicitacao: json['dthChamado'] as String?,
      indFinalizado: json['indFinalizado'] as int?,
      desNome: json['desNome'] as String?,
      descricaoChamado: json['descricaoChamado'] as String?,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numSeq': codUsuario,
      'dthChamado': dtaSolicitacao,
      'indFinalizado': indFinalizado,
    };
  }
}
