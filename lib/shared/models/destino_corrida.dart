/// Modelo para representar um destino de entrega em uma corrida
class DestinoCorrida {
  final String? id; // ID único para identificar o destino
  final String? desEnderecoEntrega;
  final String? desNumeroEndereco;
  final String? desComplemento;
  final double? desLatitudeEntrega;
  final double? desLongitudeEntrega;
  final String? desTelefone;
  final String? desObsEntrega; // Observações específicas deste destino
  final int ordem; // Ordem de entrega (1, 2, 3...)

  DestinoCorrida({
    this.id,
    this.desEnderecoEntrega,
    this.desNumeroEndereco,
    this.desComplemento,
    this.desLatitudeEntrega,
    this.desLongitudeEntrega,
    this.desTelefone,
    this.desObsEntrega,
    required this.ordem,
  });

  /// Cria um DestinoCorrida a partir de um JSON
  factory DestinoCorrida.fromJson(Map<String, dynamic> json) {
    return DestinoCorrida(
      id: json['id'] as String?,
      desEnderecoEntrega: json['desEnderecoEntrega'] as String?,
      desNumeroEndereco: json['desNumeroEndereco'] as String?,
      desComplemento: json['desComplemento'] as String?,
      desLatitudeEntrega: json['desLatitudeEntrega'] != null
          ? (json['desLatitudeEntrega'] as num).toDouble()
          : null,
      desLongitudeEntrega: json['desLongitudeEntrega'] != null
          ? (json['desLongitudeEntrega'] as num).toDouble()
          : null,
      desTelefone: json['desTelefone'] as String?,
      desObsEntrega: json['desObsEntrega'] as String?,
      ordem: json['ordem'] as int? ?? 1,
    );
  }

  /// Converte DestinoCorrida para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'desEnderecoEntrega': desEnderecoEntrega,
      'desNumeroEndereco': desNumeroEndereco,
      'desComplemento': desComplemento,
      'desLatitudeEntrega': desLatitudeEntrega,
      'desLongitudeEntrega': desLongitudeEntrega,
      'desTelefone': desTelefone,
      'desObsEntrega': desObsEntrega,
      'ordem': ordem,
    };
  }

  /// Cria uma cópia do destino com valores atualizados
  DestinoCorrida copyWith({
    String? id,
    String? desEnderecoEntrega,
    String? desNumeroEndereco,
    String? desComplemento,
    double? desLatitudeEntrega,
    double? desLongitudeEntrega,
    String? desTelefone,
    String? desObsEntrega,
    int? ordem,
  }) {
    return DestinoCorrida(
      id: id ?? this.id,
      desEnderecoEntrega: desEnderecoEntrega ?? this.desEnderecoEntrega,
      desNumeroEndereco: desNumeroEndereco ?? this.desNumeroEndereco,
      desComplemento: desComplemento ?? this.desComplemento,
      desLatitudeEntrega: desLatitudeEntrega ?? this.desLatitudeEntrega,
      desLongitudeEntrega: desLongitudeEntrega ?? this.desLongitudeEntrega,
      desTelefone: desTelefone ?? this.desTelefone,
      desObsEntrega: desObsEntrega ?? this.desObsEntrega,
      ordem: ordem ?? this.ordem,
    );
  }

  /// Retorna o endereço completo formatado
  String get enderecoCompleto {
    final parts = <String>[];
    if (desEnderecoEntrega != null && desEnderecoEntrega!.isNotEmpty) {
      parts.add(desEnderecoEntrega!);
    }
    if (desNumeroEndereco != null && desNumeroEndereco!.isNotEmpty) {
      parts.add(desNumeroEndereco!);
    }
    if (desComplemento != null && desComplemento!.isNotEmpty) {
      parts.add(desComplemento!);
    }
    return parts.join(', ');
  }

  /// Verifica se o destino está completo (tem endereço e coordenadas)
  bool get isCompleto {
    return desEnderecoEntrega != null &&
        desEnderecoEntrega!.isNotEmpty &&
        desLatitudeEntrega != null &&
        desLongitudeEntrega != null;
  }
}
