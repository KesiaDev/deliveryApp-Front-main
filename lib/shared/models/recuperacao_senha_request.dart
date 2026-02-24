class RecuperacaoSenhaRequest {
  final String email;

  RecuperacaoSenhaRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  factory RecuperacaoSenhaRequest.fromJson(Map<String, dynamic> json) {
    return RecuperacaoSenhaRequest(
      email: json['email'] as String,
    );
  }
}
