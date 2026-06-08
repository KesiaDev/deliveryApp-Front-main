import 'package:cloud_firestore/cloud_firestore.dart';

/// Status da cobrança na entrega
enum CodStatus {
  /// Aguardando motorista cobrar
  pending,
  /// Motorista coletou o valor total — corrida encerrada OK
  collected,
  /// Motorista coletou parcial — pendência aberta
  pendencyOpen,
  /// Pendência foi resolvida (devolução confirmada pela empresa)
  pendencyResolved,
  /// Corrida cancelada — cobrança não realizada
  cancelled,
}

extension CodStatusX on CodStatus {
  String get key {
    switch (this) {
      case CodStatus.pending: return 'pending';
      case CodStatus.collected: return 'collected';
      case CodStatus.pendencyOpen: return 'pendency_open';
      case CodStatus.pendencyResolved: return 'pendency_resolved';
      case CodStatus.cancelled: return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case CodStatus.pending: return 'Aguardando cobrança';
      case CodStatus.collected: return 'Coletado ✓';
      case CodStatus.pendencyOpen: return 'Pendência aberta ⚠️';
      case CodStatus.pendencyResolved: return 'Pendência resolvida ✓';
      case CodStatus.cancelled: return 'Cancelado';
    }
  }

  static CodStatus fromKey(String key) {
    for (final s in CodStatus.values) {
      if (s.key == key) return s;
    }
    return CodStatus.pending;
  }
}

/// Tipo de recebimento pelo motorista
enum TipoRecebimento { dinheiro, maquininha, misto }

extension TipoRecebimentoX on TipoRecebimento {
  String get key {
    switch (this) {
      case TipoRecebimento.dinheiro: return 'dinheiro';
      case TipoRecebimento.maquininha: return 'maquininha';
      case TipoRecebimento.misto: return 'misto';
    }
  }

  String get label {
    switch (this) {
      case TipoRecebimento.dinheiro: return 'Dinheiro';
      case TipoRecebimento.maquininha: return 'Maquininha';
      case TipoRecebimento.misto: return 'Dinheiro + Maquininha';
    }
  }

  static TipoRecebimento? fromKey(String? key) {
    for (final t in TipoRecebimento.values) {
      if (t.key == key) return t;
    }
    return null;
  }
}

/// Cobrança na Entrega por corrida
/// Firestore: cod_deliveries/{numSeq}
class CodDelivery {
  final int numSeq;
  final int codEmpresa;
  final String empresaName;
  final int? codMotorista;

  /// Valor total a cobrar do cliente final
  final double vlrCobranca;

  /// Motorista levará maquininha para receber no cartão
  final bool indMaquininha;

  final CodStatus status;

  /// Quanto o motorista efetivamente recebeu
  final double? vlrRecebido;

  /// Tipo de recebimento confirmado
  final TipoRecebimento? tipoRecebimento;

  final DateTime createdAt;
  final DateTime? dthColeta;

  const CodDelivery({
    required this.numSeq,
    required this.codEmpresa,
    required this.empresaName,
    this.codMotorista,
    required this.vlrCobranca,
    this.indMaquininha = false,
    this.status = CodStatus.pending,
    this.vlrRecebido,
    this.tipoRecebimento,
    required this.createdAt,
    this.dthColeta,
  });

  bool get isCod => true;
  bool get hasPendency => status == CodStatus.pendencyOpen;
  double get vlrPendente => vlrCobranca - (vlrRecebido ?? 0);

  factory CodDelivery.fromMap(Map<String, dynamic> map) {
    return CodDelivery(
      numSeq: (map['numSeq'] as num?)?.toInt() ?? 0,
      codEmpresa: (map['codEmpresa'] as num?)?.toInt() ?? 0,
      empresaName: map['empresaName'] as String? ?? '',
      codMotorista: (map['codMotorista'] as num?)?.toInt(),
      vlrCobranca: (map['vlrCobranca'] as num?)?.toDouble() ?? 0.0,
      indMaquininha: map['indMaquininha'] as bool? ?? false,
      status: CodStatusX.fromKey(map['status'] as String? ?? 'pending'),
      vlrRecebido: (map['vlrRecebido'] as num?)?.toDouble(),
      tipoRecebimento: TipoRecebimentoX.fromKey(map['tipoRecebimento'] as String?),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dthColeta: (map['dthColeta'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'numSeq': numSeq,
        'codEmpresa': codEmpresa,
        'empresaName': empresaName,
        'codMotorista': codMotorista,
        'vlrCobranca': vlrCobranca,
        'indMaquininha': indMaquininha,
        'status': status.key,
        'vlrRecebido': vlrRecebido,
        'tipoRecebimento': tipoRecebimento?.key,
        'createdAt': FieldValue.serverTimestamp(),
        'dthColeta': dthColeta != null ? Timestamp.fromDate(dthColeta!) : null,
      };
}

/// Pendência financeira do motorista após cobrança parcial
/// Firestore: pendencias_motorista/{id}
class PendenciaMotorista {
  final String id;
  final int codMotorista;
  final int numSeq;
  final int codEmpresa;
  final String empresaName;

  /// Valor que precisa devolver
  final double vlrPendente;

  /// Prazo de 60 minutos para devolver
  final DateTime dthPrazo;

  /// 'aberta' | 'resolvida' | 'vencida'
  final String status;

  final DateTime dthCriacao;
  final DateTime? dthResolucao;
  final double? vlrDevolvido;

  const PendenciaMotorista({
    required this.id,
    required this.codMotorista,
    required this.numSeq,
    required this.codEmpresa,
    required this.empresaName,
    required this.vlrPendente,
    required this.dthPrazo,
    required this.status,
    required this.dthCriacao,
    this.dthResolucao,
    this.vlrDevolvido,
  });

  bool get isAberta => status == 'aberta';
  bool get isVencida => status == 'vencida';
  bool get isResolvida => status == 'resolvida';

  /// Minutos restantes para o prazo
  int get minutosRestantes {
    final diff = dthPrazo.difference(DateTime.now());
    return diff.inMinutes.clamp(0, 60);
  }

  bool get prazoVencido => DateTime.now().isAfter(dthPrazo);

  String get statusLabel {
    switch (status) {
      case 'aberta': return 'Pendente ⚠️';
      case 'vencida': return 'Vencida 🔴';
      case 'resolvida': return 'Resolvida ✓';
      default: return status;
    }
  }

  factory PendenciaMotorista.fromMap(String id, Map<String, dynamic> map) {
    return PendenciaMotorista(
      id: id,
      codMotorista: (map['codMotorista'] as num?)?.toInt() ?? 0,
      numSeq: (map['numSeq'] as num?)?.toInt() ?? 0,
      codEmpresa: (map['codEmpresa'] as num?)?.toInt() ?? 0,
      empresaName: map['empresaName'] as String? ?? '',
      vlrPendente: (map['vlrPendente'] as num?)?.toDouble() ?? 0.0,
      dthPrazo: (map['dthPrazo'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'aberta',
      dthCriacao: (map['dthCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dthResolucao: (map['dthResolucao'] as Timestamp?)?.toDate(),
      vlrDevolvido: (map['vlrDevolvido'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'codMotorista': codMotorista,
        'numSeq': numSeq,
        'codEmpresa': codEmpresa,
        'empresaName': empresaName,
        'vlrPendente': vlrPendente,
        'dthPrazo': Timestamp.fromDate(dthPrazo),
        'status': status,
        'dthCriacao': FieldValue.serverTimestamp(),
        'dthResolucao': dthResolucao != null
            ? Timestamp.fromDate(dthResolucao!)
            : null,
        'vlrDevolvido': vlrDevolvido,
      };
}
