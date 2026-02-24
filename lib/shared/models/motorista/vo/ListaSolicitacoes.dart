class ListaSolicitacoes{


  final int? numSeq;
  final int? codEmpresa;
  final int? codMotorista;
  final DateTime? dthSolicitacao;
  final DateTime? dthAceite;
  final DateTime? dthInicioCorrida;
  final DateTime? dthFinalizacaoCorrida;
  final int? indStatusCorrida;
  final int? indNotaCorrida;
  final String? desObsCorrida;
  final String? desLatitudeEntrega;
  final String? desLongitudeEntrega;
  final String? desEnderecoEntrega;
  final String? desNumeroEndereco;

  ListaSolicitacoes(this.numSeq, this.codEmpresa, this.codMotorista, this.dthSolicitacao, this.dthAceite, this.dthInicioCorrida, this.dthFinalizacaoCorrida, this.indStatusCorrida, this.indNotaCorrida, this.desObsCorrida, this.desLatitudeEntrega, this.desLongitudeEntrega, this.desEnderecoEntrega, this.desNumeroEndereco);

}