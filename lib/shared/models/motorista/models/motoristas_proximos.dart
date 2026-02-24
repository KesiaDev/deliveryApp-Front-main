class MotoristasProximos {
  int? codMotorista;
  String? desNome;
  String? desModelo;
  String? desPlaca;
  String? dthUltLocal;
  double? desLatitude;
  double? desLongitude;

  MotoristasProximos(
      {this.codMotorista,
      this.desNome,
      this.desModelo,
      this.desPlaca,
      this.dthUltLocal,
      this.desLatitude,
      this.desLongitude});

  factory MotoristasProximos.fromJson(Map<String, dynamic> json) {
    return MotoristasProximos(
      codMotorista: json['codMotorista'] as int?,
      desNome: json['desNome'] as String?,
      desModelo: json['desModelo'] as String?,
      desPlaca: json['desPlaca'] as String?,
      dthUltLocal: json['dthUltLocal'] as String?,
      desLatitude: json['desLatitude'] as double?,
      desLongitude: json['desLongitude'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codMotorista': codMotorista,
      'desNome': desNome,
      'desModelo': desModelo,
      'desPlaca': desPlaca,
      'dthUltLocal': dthUltLocal,
      'desLatitude': desLatitude,
      'desLongitude': desLongitude,
    };
  }
}
