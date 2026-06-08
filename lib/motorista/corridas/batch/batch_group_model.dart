class BatchItemModel {
  final int? itemId;
  final int corridaId;
  final int ordemEntrega;
  final bool isPrincipal;
  final double fatorReducao;
  final double vlrFreteOriginal;
  final double vlrEntregador;
  final double vlrPlataforma;
  final double distanciaExtraKm;
  final int tempoExtraMin;
  final String? status;
  final String? desEnderecoEntrega;

  const BatchItemModel({
    this.itemId,
    required this.corridaId,
    required this.ordemEntrega,
    required this.isPrincipal,
    required this.fatorReducao,
    required this.vlrFreteOriginal,
    required this.vlrEntregador,
    required this.vlrPlataforma,
    required this.distanciaExtraKm,
    required this.tempoExtraMin,
    this.status,
    this.desEnderecoEntrega,
  });

  factory BatchItemModel.fromJson(Map<String, dynamic> j) => BatchItemModel(
        itemId: j['itemId'],
        corridaId: j['corridaId'] ?? 0,
        ordemEntrega: j['ordemEntrega'] ?? 1,
        isPrincipal: j['isPrincipal'] ?? false,
        fatorReducao: (j['fatorReducao'] ?? 1.0).toDouble(),
        vlrFreteOriginal: (j['vlrFreteOriginal'] ?? 0.0).toDouble(),
        vlrEntregador: (j['vlrEntregador'] ?? 0.0).toDouble(),
        vlrPlataforma: (j['vlrPlataforma'] ?? 0.0).toDouble(),
        distanciaExtraKm: (j['distanciaExtraKm'] ?? 0.0).toDouble(),
        tempoExtraMin: j['tempoExtraMin'] ?? 0,
        status: j['status'],
        desEnderecoEntrega: j['desEnderecoEntrega'],
      );
}

class BatchGroupModel {
  final int? groupId;
  final String? status;
  final int? tempoEstimado;
  final int? tempoExtraMin;
  final double? distanciaExtraKm;
  final double totalEntregador;
  final double totalPlataforma;
  final double? ganhoHoraEstimado;
  final List<BatchItemModel> items;

  const BatchGroupModel({
    this.groupId,
    this.status,
    this.tempoEstimado,
    this.tempoExtraMin,
    this.distanciaExtraKm,
    required this.totalEntregador,
    required this.totalPlataforma,
    this.ganhoHoraEstimado,
    required this.items,
  });

  factory BatchGroupModel.fromJson(Map<String, dynamic> j) => BatchGroupModel(
        groupId: j['groupId'],
        status: j['status'],
        tempoEstimado: j['tempoEstimado'],
        tempoExtraMin: j['tempoExtraMin'],
        distanciaExtraKm: j['distanciaExtraKm'] != null
            ? (j['distanciaExtraKm']).toDouble()
            : null,
        totalEntregador: (j['totalEntregador'] ?? 0.0).toDouble(),
        totalPlataforma: (j['totalPlataforma'] ?? 0.0).toDouble(),
        ganhoHoraEstimado: j['ganhoHoraEstimado'] != null
            ? (j['ganhoHoraEstimado']).toDouble()
            : null,
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => BatchItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
