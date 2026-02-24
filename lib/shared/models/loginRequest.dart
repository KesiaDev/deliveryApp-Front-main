import 'dart:convert';

class LoginRequest {
  LoginRequest({
    required this.email,
    required this.senha,
    this.desTokenFcm,
    this.indLogado,
  });

  final String email;
  final String senha;
  final String? desTokenFcm;
  final bool? indLogado;

  LoginRequest copyWith({
    String? login,
    String? password,
    String? desTokenFcm,
    bool? indLogado,
  }) =>
      LoginRequest(
        email: login ?? this.email,
        senha: password ?? this.senha,
        desTokenFcm: desTokenFcm ?? this.desTokenFcm,
        indLogado: indLogado ?? this.indLogado,
      );

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        "username": email,
        "password": senha,
        "desTokenFcm": desTokenFcm,
        "indLogado": indLogado,
      };
}
