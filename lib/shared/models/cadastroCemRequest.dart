import 'dart:convert';

class CadastroCemRequest {
  CadastroCemRequest({
    required this.email,
    required this.senha,
    required this.nome,
    required this.emailMotoristaAmigo,
    this.codCem,
    this.codMotorista,
    this.indAdicaoMotoristaCem,
    this.cor,
    this.carro,
    this.placa,
  });

  String email;
  final String senha;
  final String nome;
  String emailMotoristaAmigo;
  int? codCem;
  int? codMotorista;
  int? indAdicaoMotoristaCem;
  String? carro;
  String? cor;
  String? placa;

  CadastroCemRequest copyWith({
    String? login,
    String? password,
    String? nome,
    String? emailMotorista,
    int? codCem,
    int? codMotorista,
    int? indAdicaoMotoristaCem,
    String? carro,
    String? cor,
    String? placa,
  }) =>
      CadastroCemRequest(
        email: login ?? this.email,
        senha: password ?? this.senha,
        nome: nome ?? this.nome,
        emailMotoristaAmigo: emailMotorista ?? this.emailMotoristaAmigo,
        codCem: codCem ?? this.codCem,
        codMotorista: codMotorista ?? this.codMotorista,
        indAdicaoMotoristaCem:
            indAdicaoMotoristaCem ?? this.indAdicaoMotoristaCem,
        cor: cor ?? this.cor,
        carro: carro ?? this.carro,
        placa: placa ?? this.placa,
      );

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        "desEmail": email,
        "desSenha": senha,
        "desNome": nome,
        "desEmailMotorista": emailMotoristaAmigo,
        "codCem": codCem,
        "codMotorista": codMotorista,
        "indAdicaoMotoristaCem": indAdicaoMotoristaCem,
        "desCor": cor,
        "desModelo": carro,
        "desPlaca": placa,
      };
}
