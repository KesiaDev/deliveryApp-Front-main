import 'dart:io';
import 'package:dio/dio.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import '../models/payment_model.dart';

/// Modelo interno para dados da resposta PIX da API
class _PixApiResponse {
  final String paymentId;
  final String status;
  final String qrCodeImage;
  final String pixCopyPaste;
  final String expirationDate;
  final double value;

  _PixApiResponse({
    required this.paymentId,
    required this.status,
    required this.qrCodeImage,
    required this.pixCopyPaste,
    required this.expirationDate,
    required this.value,
  });

  factory _PixApiResponse.fromJson(Map<String, dynamic> json) {
    return _PixApiResponse(
      paymentId: json['paymentId'] ?? '',
      status: json['status'] ?? '',
      qrCodeImage: json['qrCodeImage'] ?? '',
      pixCopyPaste: json['pixCopyPaste'] ?? '',
      expirationDate: json['expirationDate'] ?? '',
      value: (json['value'] as num).toDouble(),
    );
  }
}

/// Serviço isolado para processamento de pagamentos
/// Preparado para integração com gateway real (Stripe, Mercado Pago, etc.)
class PaymentService {
  /// CNPJ padrão da empresa para pagamentos PIX
  static const String _pixCnpj = '40283635000168';
  static const String _pixName = 'Fool Entregas';

  /// Chama o endpoint real de PIX na API
  static Future<_PixApiResponse> _callPixApi({
    required double amount,
    required String description,
    required String corridaId,
  }) async {
    final jwt = ApiBaseHelper.userSessao?.jwt;

    final dio = Dio(BaseOptions(
      baseUrl: ApiBaseHelper.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: jwt != null ? 'Bearer $jwt' : '',
      },
    ));

    final body = {
      'cpfCnpj': _pixCnpj,
      'name': _pixName,
      'value': amount,
      'description': description,
      'corridaId': corridaId,
    };

    final response = await dio.post('/private/payment/pix', data: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _PixApiResponse.fromJson(response.data as Map<String, dynamic>);
    }

    throw Exception('Erro ao gerar PIX: status ${response.statusCode}');
  }

  /// Processa um pagamento PIX (retorna dados para exibir QR Code)
  static Future<PaymentResponse> processPayment(PaymentRequest request) async {
    if (request.method == PaymentMethod.pix) {
      try {
        final pixResp = await _callPixApi(
          amount: request.amount,
          description: request.description ?? 'Corrida #${request.corridaId}',
          corridaId: request.corridaId,
        );

        return PaymentResponse(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
          paymentId: request.id,
          success: true,
          transactionId: pixResp.paymentId,
          timestamp: DateTime.now(),
          method: request.method,
          amount: request.amount,
        );
      } catch (e) {
        return PaymentResponse(
          id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
          paymentId: request.id,
          success: false,
          errorMessage: 'Erro ao processar PIX: $e',
          timestamp: DateTime.now(),
          method: request.method,
          amount: request.amount,
        );
      }
    }

    // Dinheiro — sem processamento online
    return PaymentResponse(
      id: 'resp_${DateTime.now().millisecondsSinceEpoch}',
      paymentId: request.id,
      success: true,
      transactionId: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      method: request.method,
      amount: request.amount,
    );
  }

  /// Verifica se um pagamento PIX foi confirmado no Asaas
  static Future<bool> verifyPixPayment(String asaasPaymentId) async {
    final jwt = ApiBaseHelper.userSessao?.jwt;
    final dio = Dio(BaseOptions(
      baseUrl: ApiBaseHelper.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        HttpHeaders.authorizationHeader: jwt != null ? 'Bearer $jwt' : '',
      },
    ));
    try {
      final response =
          await dio.get('/private/payment/$asaasPaymentId/status');
      if (response.statusCode == 200) {
        final status =
            (response.data as Map<String, dynamic>)['status'] as String? ?? '';
        return status == 'RECEIVED' || status == 'CONFIRMED';
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Gera QR Code PIX real via API — retorna o pixCopyPaste
  static Future<PixQrCodeData> generatePixQrCode({
    required double amount,
    required String description,
    required String corridaId,
  }) async {
    final pixResp = await _callPixApi(
      amount: amount,
      description: description,
      corridaId: corridaId,
    );

    return PixQrCodeData(
      paymentId: pixResp.paymentId,
      pixCopyPaste: pixResp.pixCopyPaste,
      qrCodeImage: pixResp.qrCodeImage,
      expirationDate: pixResp.expirationDate,
      value: pixResp.value,
    );
  }

  /// Tokeniza cartão (mock)
  static Future<String> tokenizeCard(CardData cardData) async {
    // TODO: Em produção, tokenizar via gateway
    await Future.delayed(const Duration(seconds: 1));
    return 'tok_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Valida dados do cartão
  static bool validateCard(CardData cardData) {
    if (cardData.number.replaceAll(' ', '').length < 13) return false;
    if (cardData.holderName.trim().isEmpty) return false;
    if (cardData.expiryMonth.length != 2) return false;
    if (cardData.expiryYear.length != 4) return false;
    if (cardData.cvv.length < 3) return false;

    final now = DateTime.now();
    final expiryYear = int.tryParse(cardData.expiryYear);
    final expiryMonth = int.tryParse(cardData.expiryMonth);

    if (expiryYear == null || expiryMonth == null) return false;
    if (expiryYear < now.year) return false;
    if (expiryYear == now.year && expiryMonth < now.month) return false;

    return true;
  }
}

/// Dados retornados pela API PIX para exibição do QR Code
class PixQrCodeData {
  final String paymentId;
  final String pixCopyPaste;
  final String qrCodeImage;
  final String expirationDate;
  final double value;

  PixQrCodeData({
    required this.paymentId,
    required this.pixCopyPaste,
    required this.qrCodeImage,
    required this.expirationDate,
    required this.value,
  });
}
