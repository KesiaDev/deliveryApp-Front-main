class AlteracaoSenhaRequest {
  final String senhaAtual;
  final String novaSenha;
  final String confirmacaoSenha;

  AlteracaoSenhaRequest({
    required this.senhaAtual,
    required this.novaSenha,
    required this.confirmacaoSenha,
  });

  Map<String, dynamic> toJson() {
    return {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
      'confirmacaoSenha': confirmacaoSenha,
    };
  }

  factory AlteracaoSenhaRequest.fromJson(Map<String, dynamic> json) {
    return AlteracaoSenhaRequest(
      senhaAtual: json['senhaAtual'] as String,
      novaSenha: json['novaSenha'] as String,
      confirmacaoSenha: json['confirmacaoSenha'] as String,
    );
  }
}
