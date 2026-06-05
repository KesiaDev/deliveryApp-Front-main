import 'package:cloud_firestore/cloud_firestore.dart';

/// Métodos de pagamento disponíveis na plataforma
enum EmpresaPayMethod {
  pix,
  cartao,
  dinheiro,
  boleto,
  carteira, // Carteira Fool
}

extension EmpresaPayMethodX on EmpresaPayMethod {
  String get key {
    switch (this) {
      case EmpresaPayMethod.pix: return 'pix';
      case EmpresaPayMethod.cartao: return 'cartao';
      case EmpresaPayMethod.dinheiro: return 'dinheiro';
      case EmpresaPayMethod.boleto: return 'boleto';
      case EmpresaPayMethod.carteira: return 'carteira';
    }
  }

  String get label {
    switch (this) {
      case EmpresaPayMethod.pix: return 'PIX';
      case EmpresaPayMethod.cartao: return 'Cartão de Crédito';
      case EmpresaPayMethod.dinheiro: return 'Dinheiro (ao entregador)';
      case EmpresaPayMethod.boleto: return 'Boleto Semanal';
      case EmpresaPayMethod.carteira: return 'Carteira Fool';
    }
  }

  String get icon {
    switch (this) {
      case EmpresaPayMethod.pix: return '⚡';
      case EmpresaPayMethod.cartao: return '💳';
      case EmpresaPayMethod.dinheiro: return '💵';
      case EmpresaPayMethod.boleto: return '📄';
      case EmpresaPayMethod.carteira: return '👛';
    }
  }

  static EmpresaPayMethod? fromKey(String key) {
    for (final m in EmpresaPayMethod.values) {
      if (m.key == key) return m;
    }
    return null;
  }
}

/// Configuração de pagamento por empresa (Firestore: empresa_configs/{codEmpresa})
class EmpresaPaymentConfig {
  final int codEmpresa;
  final List<EmpresaPayMethod> acceptedMethods;
  final bool isBlocked;
  final String? blockReason;
  final DateTime? blockedAt;
  final String? blockedBy;
  final DateTime updatedAt;
  final String? updatedBy;

  const EmpresaPaymentConfig({
    required this.codEmpresa,
    required this.acceptedMethods,
    this.isBlocked = false,
    this.blockReason,
    this.blockedAt,
    this.blockedBy,
    required this.updatedAt,
    this.updatedBy,
  });

  static EmpresaPaymentConfig defaultConfig(int codEmpresa) {
    return EmpresaPaymentConfig(
      codEmpresa: codEmpresa,
      acceptedMethods: [
        EmpresaPayMethod.pix,
        EmpresaPayMethod.cartao,
        EmpresaPayMethod.dinheiro,
      ],
      updatedAt: DateTime.now(),
    );
  }

  factory EmpresaPaymentConfig.fromMap(Map<String, dynamic> map) {
    final methods = (map['acceptedMethods'] as List<dynamic>? ?? [])
        .map((k) => EmpresaPayMethodX.fromKey(k.toString()))
        .whereType<EmpresaPayMethod>()
        .toList();

    return EmpresaPaymentConfig(
      codEmpresa: (map['codEmpresa'] as num?)?.toInt() ?? 0,
      acceptedMethods: methods.isEmpty
          ? [EmpresaPayMethod.pix, EmpresaPayMethod.cartao, EmpresaPayMethod.dinheiro]
          : methods,
      isBlocked: map['isBlocked'] as bool? ?? false,
      blockReason: map['blockReason'] as String?,
      blockedAt: (map['blockedAt'] as Timestamp?)?.toDate(),
      blockedBy: map['blockedBy'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: map['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'codEmpresa': codEmpresa,
        'acceptedMethods': acceptedMethods.map((m) => m.key).toList(),
        'isBlocked': isBlocked,
        'blockReason': blockReason,
        'blockedAt': blockedAt != null ? Timestamp.fromDate(blockedAt!) : null,
        'blockedBy': blockedBy,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      };

  EmpresaPaymentConfig copyWith({
    List<EmpresaPayMethod>? acceptedMethods,
    bool? isBlocked,
    String? blockReason,
    DateTime? blockedAt,
    String? blockedBy,
    String? updatedBy,
  }) =>
      EmpresaPaymentConfig(
        codEmpresa: codEmpresa,
        acceptedMethods: acceptedMethods ?? this.acceptedMethods,
        isBlocked: isBlocked ?? this.isBlocked,
        blockReason: blockReason ?? this.blockReason,
        blockedAt: blockedAt ?? this.blockedAt,
        blockedBy: blockedBy ?? this.blockedBy,
        updatedAt: DateTime.now(),
        updatedBy: updatedBy ?? this.updatedBy,
      );
}

/// Transação na Carteira Fool (Firestore: wallet_transactions/{txId})
class WalletTransaction {
  final String id;
  final int codEmpresa;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final String? corridaId;
  final DateTime createdAt;
  final String? createdBy;

  const WalletTransaction({
    required this.id,
    required this.codEmpresa,
    required this.type,
    required this.amount,
    required this.description,
    this.corridaId,
    required this.createdAt,
    this.createdBy,
  });

  factory WalletTransaction.fromMap(String id, Map<String, dynamic> map) {
    return WalletTransaction(
      id: id,
      codEmpresa: (map['codEmpresa'] as num?)?.toInt() ?? 0,
      type: map['type'] as String? ?? 'debit',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      corridaId: map['corridaId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'codEmpresa': codEmpresa,
        'type': type,
        'amount': amount,
        'description': description,
        'corridaId': corridaId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      };

  bool get isCredit => type == 'credit';
}

/// Boleto semanal (Firestore: weekly_invoices/{invoiceId})
class WeeklyInvoice {
  final String id;
  final int codEmpresa;
  final String empresaName;
  final DateTime weekStart;
  final DateTime weekEnd;
  final DateTime dueDate; // próximo dia útil após weekEnd
  final double totalValue;
  final int corridaCount;
  final List<int> corridaIds;
  final String status; // pending | paid | overdue | cancelled | unlocked
  final String? asaasBoletoId;
  final String? boletoUrl;
  final String? boletoBarCode;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? proofImageUrl;
  final DateTime? unlockedAt;
  final String? unlockedBy;

  const WeeklyInvoice({
    required this.id,
    required this.codEmpresa,
    required this.empresaName,
    required this.weekStart,
    required this.weekEnd,
    required this.dueDate,
    required this.totalValue,
    required this.corridaCount,
    required this.corridaIds,
    required this.status,
    this.asaasBoletoId,
    this.boletoUrl,
    this.boletoBarCode,
    required this.createdAt,
    this.paidAt,
    this.proofImageUrl,
    this.unlockedAt,
    this.unlockedBy,
  });

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isOverdue => status == 'overdue';
  bool get isUnlocked => status == 'unlocked';

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Aguardando pagamento';
      case 'paid': return 'Pago ✓';
      case 'overdue': return 'Vencido ⚠️';
      case 'cancelled': return 'Cancelado';
      case 'unlocked': return 'Desbloqueado (comprovante)';
      default: return status;
    }
  }

  factory WeeklyInvoice.fromMap(String id, Map<String, dynamic> map) {
    return WeeklyInvoice(
      id: id,
      codEmpresa: (map['codEmpresa'] as num?)?.toInt() ?? 0,
      empresaName: map['empresaName'] as String? ?? '',
      weekStart: (map['weekStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekEnd: (map['weekEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      corridaCount: (map['corridaCount'] as num?)?.toInt() ?? 0,
      corridaIds: (map['corridaIds'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toList(),
      status: map['status'] as String? ?? 'pending',
      asaasBoletoId: map['asaasBoletoId'] as String?,
      boletoUrl: map['boletoUrl'] as String?,
      boletoBarCode: map['boletoBarCode'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      proofImageUrl: map['proofImageUrl'] as String?,
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
      unlockedBy: map['unlockedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'codEmpresa': codEmpresa,
        'empresaName': empresaName,
        'weekStart': Timestamp.fromDate(weekStart),
        'weekEnd': Timestamp.fromDate(weekEnd),
        'dueDate': Timestamp.fromDate(dueDate),
        'totalValue': totalValue,
        'corridaCount': corridaCount,
        'corridaIds': corridaIds,
        'status': status,
        'asaasBoletoId': asaasBoletoId,
        'boletoUrl': boletoUrl,
        'boletoBarCode': boletoBarCode,
        'createdAt': FieldValue.serverTimestamp(),
        'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
        'proofImageUrl': proofImageUrl,
        'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
        'unlockedBy': unlockedBy,
      };
}
