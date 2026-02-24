/// Modelo de método de pagamento
enum PaymentMethod {
  pix,
  creditCard,
  debitCard,
  boleto,
  cash,
}

extension PaymentMethodExtension on PaymentMethod {
  String get name {
    switch (this) {
      case PaymentMethod.pix:
        return 'PIX';
      case PaymentMethod.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethod.debitCard:
        return 'Cartão de Débito';
      case PaymentMethod.boleto:
        return 'Boleto';
      case PaymentMethod.cash:
        return 'Dinheiro';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.pix:
        return '💳';
      case PaymentMethod.creditCard:
        return '💳';
      case PaymentMethod.debitCard:
        return '💳';
      case PaymentMethod.boleto:
        return '📄';
      case PaymentMethod.cash:
        return '💵';
    }
  }
}

/// Modelo de requisição de pagamento
class PaymentRequest {
  final String id;
  final String corridaId;
  final double amount;
  final PaymentMethod method;
  final Map<String, dynamic>? paymentData; // Dados específicos do método
  final String? description;

  PaymentRequest({
    required this.id,
    required this.corridaId,
    required this.amount,
    required this.method,
    this.paymentData,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'corridaId': corridaId,
      'amount': amount,
      'method': method.name,
      'paymentData': paymentData,
      'description': description,
    };
  }
}

/// Modelo de resposta de pagamento
class PaymentResponse {
  final String id;
  final String paymentId;
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final DateTime timestamp;
  final PaymentMethod method;
  final double amount;

  PaymentResponse({
    required this.id,
    required this.paymentId,
    required this.success,
    this.transactionId,
    this.errorMessage,
    required this.timestamp,
    required this.method,
    required this.amount,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      id: json['id'] ?? '',
      paymentId: json['paymentId'] ?? '',
      success: json['success'] ?? false,
      transactionId: json['transactionId'],
      errorMessage: json['errorMessage'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentId': paymentId,
      'success': success,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'method': method.name,
      'amount': amount,
    };
  }
}

/// Modelo de dados de cartão (para tokenização)
class CardData {
  final String number;
  final String holderName;
  final String expiryMonth;
  final String expiryYear;
  final String cvv;

  CardData({
    required this.number,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });

  Map<String, dynamic> toJson() {
    return {
      'number': number.replaceAll(' ', ''),
      'holderName': holderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
    };
  }
}





