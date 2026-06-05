import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:delivery_front/bussiness/service/ApiBaseHelper.dart';
import '../models/empresa_payment_config.dart';

/// Serviço central de pagamentos por empresa
/// Gerencia: config, carteira Fool, boletos semanais
class EmpresaPaymentService {
  static final _db = FirebaseFirestore.instance;
  static const _configCol = 'empresa_configs';
  static const _walletTxCol = 'wallet_transactions';
  static const _invoiceCol = 'weekly_invoices';

  // ─────────────────────────────────────────────────────────────────
  // CONFIG DE MÉTODOS ACEITOS
  // ─────────────────────────────────────────────────────────────────

  static Future<EmpresaPaymentConfig> getConfig(int codEmpresa) async {
    final doc = await _db.collection(_configCol).doc('$codEmpresa').get();
    if (!doc.exists || doc.data() == null) {
      return EmpresaPaymentConfig.defaultConfig(codEmpresa);
    }
    return EmpresaPaymentConfig.fromMap(doc.data()!);
  }

  static Stream<EmpresaPaymentConfig> streamConfig(int codEmpresa) {
    return _db.collection(_configCol).doc('$codEmpresa').snapshots().map((s) {
      if (!s.exists || s.data() == null) {
        return EmpresaPaymentConfig.defaultConfig(codEmpresa);
      }
      return EmpresaPaymentConfig.fromMap(s.data()!);
    });
  }

  static Future<void> saveConfig(EmpresaPaymentConfig config) async {
    await _db
        .collection(_configCol)
        .doc('${config.codEmpresa}')
        .set(config.toMap(), SetOptions(merge: true));
  }

  /// Bloqueia empresa por boleto vencido
  static Future<void> blockEmpresa(int codEmpresa, String reason, String adminName) async {
    await _db.collection(_configCol).doc('$codEmpresa').set({
      'codEmpresa': codEmpresa,
      'isBlocked': true,
      'blockReason': reason,
      'blockedAt': FieldValue.serverTimestamp(),
      'blockedBy': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Desbloqueia empresa (admin verificou comprovante)
  static Future<void> unblockEmpresa(int codEmpresa, String adminName) async {
    await _db.collection(_configCol).doc('$codEmpresa').set({
      'isBlocked': false,
      'blockReason': null,
      'unblockedAt': FieldValue.serverTimestamp(),
      'unblockedBy': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─────────────────────────────────────────────────────────────────
  // CARTEIRA FOOL
  // ─────────────────────────────────────────────────────────────────

  static Future<double> getWalletBalance(int codEmpresa) async {
    final doc = await _db.collection(_configCol).doc('$codEmpresa').get();
    return (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
  }

  static Stream<double> streamWalletBalance(int codEmpresa) {
    return _db.collection(_configCol).doc('$codEmpresa').snapshots().map(
        (s) => (s.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0);
  }

  /// Adiciona crédito à carteira (admin)
  static Future<void> addWalletCredit({
    required int codEmpresa,
    required double amount,
    required String description,
    required String adminName,
  }) async {
    final batch = _db.batch();

    // Transação
    final txRef = _db.collection(_walletTxCol).doc();
    batch.set(txRef, {
      'codEmpresa': codEmpresa,
      'type': 'credit',
      'amount': amount,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': adminName,
    });

    // Atualiza saldo
    batch.set(
      _db.collection(_configCol).doc('$codEmpresa'),
      {
        'codEmpresa': codEmpresa,
        'walletBalance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Debita da carteira ao criar corrida
  static Future<bool> debitWallet({
    required int codEmpresa,
    required double amount,
    required String corridaId,
    required String description,
  }) async {
    final balance = await getWalletBalance(codEmpresa);
    if (balance < amount) return false;

    final batch = _db.batch();

    final txRef = _db.collection(_walletTxCol).doc();
    batch.set(txRef, {
      'codEmpresa': codEmpresa,
      'type': 'debit',
      'amount': amount,
      'description': description,
      'corridaId': corridaId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      _db.collection(_configCol).doc('$codEmpresa'),
      {
        'walletBalance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return true;
  }

  static Stream<List<WalletTransaction>> streamWalletTransactions(int codEmpresa) {
    return _db
        .collection(_walletTxCol)
        .where('codEmpresa', isEqualTo: codEmpresa)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WalletTransaction.fromMap(d.id, d.data()))
            .toList());
  }

  // ─────────────────────────────────────────────────────────────────
  // BOLETO SEMANAL
  // ─────────────────────────────────────────────────────────────────

  static Future<WeeklyInvoice?> getLatestInvoice(int codEmpresa) async {
    final snap = await _db
        .collection(_invoiceCol)
        .where('codEmpresa', isEqualTo: codEmpresa)
        .orderBy('weekEnd', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return WeeklyInvoice.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  static Stream<List<WeeklyInvoice>> streamInvoices(int codEmpresa) {
    return _db
        .collection(_invoiceCol)
        .where('codEmpresa', isEqualTo: codEmpresa)
        .orderBy('weekEnd', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WeeklyInvoice.fromMap(d.id, d.data()))
            .toList());
  }

  static Stream<List<WeeklyInvoice>> streamAllPendingInvoices() {
    return _db
        .collection(_invoiceCol)
        .where('status', whereIn: ['pending', 'overdue'])
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WeeklyInvoice.fromMap(d.id, d.data()))
            .toList());
  }

  /// Cria boleto semanal — chamado automaticamente ao fechar 7 dias
  static Future<WeeklyInvoice> createWeeklyInvoice({
    required int codEmpresa,
    required String empresaName,
    required DateTime weekStart,
    required DateTime weekEnd,
    required double totalValue,
    required int corridaCount,
    required List<int> corridaIds,
  }) async {
    final dueDate = _nextBusinessDay(weekEnd.add(const Duration(days: 1)));

    // Chama backend para gerar boleto Asaas
    String? asaasBoletoId;
    String? boletoUrl;
    String? boletoBarCode;

    try {
      final result = await _callBoletoApi(
        codEmpresa: codEmpresa,
        empresaName: empresaName,
        totalValue: totalValue,
        dueDate: dueDate,
        description: 'Corridas semana ${_dateStr(weekStart)} a ${_dateStr(weekEnd)}',
      );
      asaasBoletoId = result['paymentId'];
      boletoUrl = result['boletoUrl'];
      boletoBarCode = result['barCode'];
    } catch (_) {
      // Backend não disponível — cria fatura sem boleto Asaas (admin gera manualmente)
    }

    final ref = _db.collection(_invoiceCol).doc();
    final invoice = WeeklyInvoice(
      id: ref.id,
      codEmpresa: codEmpresa,
      empresaName: empresaName,
      weekStart: weekStart,
      weekEnd: weekEnd,
      dueDate: dueDate,
      totalValue: totalValue,
      corridaCount: corridaCount,
      corridaIds: corridaIds,
      status: 'pending',
      asaasBoletoId: asaasBoletoId,
      boletoUrl: boletoUrl,
      boletoBarCode: boletoBarCode,
      createdAt: DateTime.now(),
    );

    await ref.set(invoice.toMap());
    return invoice;
  }

  /// Marca boleto como pago (confirmação manual admin)
  static Future<void> markInvoicePaid(String invoiceId, {String? proofUrl}) async {
    await _db.collection(_invoiceCol).doc(invoiceId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      if (proofUrl != null) 'proofImageUrl': proofUrl,
    });
  }

  /// Desbloqueia empresa após comprovante (admin) — não precisa compensar boleto
  static Future<void> unlockAfterProof({
    required String invoiceId,
    required int codEmpresa,
    required String adminName,
    String? proofUrl,
  }) async {
    final batch = _db.batch();

    batch.update(_db.collection(_invoiceCol).doc(invoiceId), {
      'status': 'unlocked',
      'unlockedAt': FieldValue.serverTimestamp(),
      'unlockedBy': adminName,
      if (proofUrl != null) 'proofImageUrl': proofUrl,
    });

    batch.set(
      _db.collection(_configCol).doc('$codEmpresa'),
      {
        'isBlocked': false,
        'blockReason': null,
        'unblockedAt': FieldValue.serverTimestamp(),
        'unblockedBy': adminName,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Verifica se a empresa precisa de boleto novo (chamado ao abrir home empresa)
  static Future<void> checkAndGenerateInvoice({
    required int codEmpresa,
    required String empresaName,
    required List<int> corridaIdsSemana,
    required double totalSemana,
  }) async {
    final latest = await getLatestInvoice(codEmpresa);
    final now = DateTime.now();

    // Verifica se boleto anterior venceu e não foi pago
    if (latest != null && latest.isPending) {
      if (now.isAfter(latest.dueDate)) {
        await _db.collection(_invoiceCol).doc(latest.id).update({'status': 'overdue'});
        await blockEmpresa(codEmpresa, 'Boleto semanal vencido em ${_dateStr(latest.dueDate)}', 'Sistema');
      }
    }

    // Verifica se passou 7 dias desde último boleto (ou se não existe)
    final needsNew = latest == null ||
        now.difference(latest.weekEnd).inDays >= 7;

    if (needsNew && corridaIdsSemana.isNotEmpty && totalSemana > 0) {
      final weekEnd = now;
      final weekStart = latest != null
          ? latest.weekEnd.add(const Duration(days: 1))
          : now.subtract(const Duration(days: 7));

      await createWeeklyInvoice(
        codEmpresa: codEmpresa,
        empresaName: empresaName,
        weekStart: weekStart,
        weekEnd: weekEnd,
        totalValue: totalSemana,
        corridaCount: corridaIdsSemana.length,
        corridaIds: corridaIdsSemana,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS INTERNOS
  // ─────────────────────────────────────────────────────────────────

  /// Próximo dia útil (pula fim de semana)
  static DateTime _nextBusinessDay(DateTime date) {
    var d = date;
    while (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
      d = d.add(const Duration(days: 1));
    }
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  static String _dateStr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Chama backend EC2 para gerar boleto via Asaas
  static Future<Map<String, String?>> _callBoletoApi({
    required int codEmpresa,
    required String empresaName,
    required double totalValue,
    required DateTime dueDate,
    required String description,
  }) async {
    final jwt = ApiBaseHelper.userSessao?.jwt;
    final dio = Dio(BaseOptions(
      baseUrl: ApiBaseHelper.baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: jwt != null ? 'Bearer $jwt' : '',
      },
    ));

    final response = await dio.post('/private/payment/boleto', data: {
      'codEmpresa': codEmpresa,
      'name': empresaName,
      'value': totalValue,
      'dueDate': '${dueDate.year}-${dueDate.month.toString().padLeft(2,'0')}-${dueDate.day.toString().padLeft(2,'0')}',
      'description': description,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;
      return {
        'paymentId': data['paymentId'] as String?,
        'boletoUrl': data['boletoUrl'] as String?,
        'barCode': data['barCode'] as String?,
      };
    }
    throw Exception('Erro ao gerar boleto: ${response.statusCode}');
  }
}
