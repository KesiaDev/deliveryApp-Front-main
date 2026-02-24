class Cem {
  int? codCem;
  String? desNome;
  int? codUsuario;
  int? indAtivo;
  bool indAguardandoAutorizacao;
  String? desEmail;

  Cem({
    this.codCem,
    this.desNome,
    this.codUsuario,
    this.indAtivo,
    required this.indAguardandoAutorizacao,
    this.desEmail,
  });

  factory Cem.fromJson(Map<String, dynamic> json) {
    return Cem(
      codCem: json['codCem'] as int?,
      desNome: json['desNome'] as String?,
      codUsuario: json['codUsuario'] as int?,
      indAtivo: json['indAprovado'] as int?,
      indAguardandoAutorizacao: json['indAguardandoAutorizacao'] as bool,
      desEmail: json['desEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codCem': codCem,
      'desNome': desNome,
      'codUsuario': codUsuario,
      'indAprovado': indAtivo,
      'indAguardandoAutorizacao': indAguardandoAutorizacao,
      'desEmail': desEmail,
    };
  }

  Cem copyWith({
    int? codCem,
    String? desNome,
    int? codUsuario,
    int? indAtivo,
    bool? indAguardandoAutorizacao,
    String? desEmail,
  }) {
    return Cem(
      codCem: codCem ?? this.codCem,
      desNome: desNome ?? this.desNome,
      codUsuario: codUsuario ?? this.codUsuario,
      indAtivo: indAtivo ?? this.indAtivo,
      indAguardandoAutorizacao:
          indAguardandoAutorizacao ?? this.indAguardandoAutorizacao,
      desEmail: desEmail ?? this.desEmail,
    );
  }
}
