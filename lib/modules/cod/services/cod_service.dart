import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_front/modules/payments/services/empresa_payment_service.dart';
import '../models/cod_model.dart';

/// Serviço de Cobrança na Entrega (Cash on Delivery)
/// Toda persistência via Firestore — sem alteração no PostgreSQL
class CodService {
  static final _db = FirebaseFirestore.instance;
  static const _codCol = 'cod_deliveries';
  static const _pendCol = 'pendencias_motorista';

  // ─────────────────────────────────────────────────────────────────
  // COD DELIVERY
  // ─────────────────────────────────────────────────────────────────

  /// Cria registro CoD ao criar corrida (empresa)
  static Future<void> createCodDelivery(CodDelivery cod) async {
    await _db.collection(_codCol).doc('${cod.numSeq}').set(cod.toMap());
  }

  /// Busca CoD de uma corrida específica (null = não é CoD)
  static Future<CodDelivery?> getCodDelivery(int numSeq) async {
    final doc = await _db.collection(_codCol).doc('$numSeq').get();
    if (!doc.exists || doc.data() == null) return null;
    return CodDelivery.fromMap(doc.data()!);
  }

  static Stream<CodDelivery?> streamCodDelivery(int numSeq) {
    return _db.collection(_codCol).doc('$numSeq').snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return CodDelivery.fromMap(s.data()!);
    });
  }

  /// Atribui motorista quando ele aceita a corrida
  static Future<void> assignMotorista(int numSeq, int codMotorista) async {
    final doc = await _db.collection(_codCol).doc('$numSeq').get();
    if (!doc.exists) return;
    await _db.collection(_codCol).doc('$numSeq').update({
      'codMotorista': codMotorista,
    });
  }

  /// Motorista confirma que recebeu o valor do cliente
  /// Se recebeu valor total → status = collected
  /// Se recebeu valor parcial → status = pendency_open → cria pendência
  static Future<CodDelivery> confirmReceipt({
    required int numSeq,
    required int codMotorista,
    required double vlrRecebido,
    required TipoRecebimento tipoRecebimento,
  }) async {
    final doc = await _db.collection(_codCol).doc('$numSeq').get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('CoD não encontrado para corrida $numSeq');
    }
    final cod = CodDelivery.fromMap(doc.data()!);

    final isTotal = vlrRecebido >= cod.vlrCobranca - 0.01; // tolerância 1 centavo
    final newStatus = isTotal ? CodStatus.collected : CodStatus.pendencyOpen;

    await _db.collection(_codCol).doc('$numSeq').update({
      'status': newStatus.key,
      'vlrRecebido': vlrRecebido,
      'tipoRecebimento': tipoRecebimento.key,
      'dthColeta': FieldValue.serverTimestamp(),
    });

    if (!isTotal) {
      await _createPendency(
        cod: cod,
        codMotorista: codMotorista,
        vlrPendente: cod.vlrCobranca - vlrRecebido,
      );
    }

    return CodDelivery.fromMap({
      ...doc.data()!,
      'status': newStatus.key,
      'vlrRecebido': vlrRecebido,
      'tipoRecebimento': tipoRecebimento.key,
    });
  }

  /// Cancela CoD (corrida cancelada)
  static Future<void> cancelCod(int numSeq) async {
    final doc = await _db.collection(_codCol).doc('$numSeq').get();
    if (!doc.exists) return;
    await _db.collection(_codCol).doc('$numSeq').update({
      'status': CodStatus.cancelled.key,
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // PENDÊNCIAS DO MOTORISTA
  // ─────────────────────────────────────────────────────────────────

  static Future<void> _createPendency({
    required CodDelivery cod,
    required int codMotorista,
    required double vlrPendente,
  }) async {
    final prazo = DateTime.now().add(const Duration(minutes: 60));
    final ref = _db.collection(_pendCol).doc();
    final pendencia = PendenciaMotorista(
      id: ref.id,
      codMotorista: codMotorista,
      numSeq: cod.numSeq,
      codEmpresa: cod.codEmpresa,
      empresaName: cod.empresaName,
      vlrPendente: vlrPendente,
      dthPrazo: prazo,
      status: 'aberta',
      dthCriacao: DateTime.now(),
    );
    await ref.set(pendencia.toMap());
  }

  /// Pendências abertas de um motorista específico
  static Stream<List<PendenciaMotorista>> streamPendencias(int codMotorista) {
    return _db
        .collection(_pendCol)
        .where('codMotorista', isEqualTo: codMotorista)
        .where('status', isEqualTo: 'aberta')
        .orderBy('dthPrazo')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => PendenciaMotorista.fromMap(d.id, d.data())).toList());
  }

  /// Todas as pendências de uma empresa (para o admin/empresa confirmar)
  static Stream<List<PendenciaMotorista>> streamPendenciasEmpresa(int codEmpresa) {
    return _db
        .collection(_pendCol)
        .where('codEmpresa', isEqualTo: codEmpresa)
        .orderBy('dthCriacao', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => PendenciaMotorista.fromMap(d.id, d.data())).toList());
  }

  /// Todas as pendências abertas (admin)
  static Stream<List<PendenciaMotorista>> streamTodasPendenciasAbertas() {
    return _db
        .collection(_pendCol)
        .where('status', whereIn: ['aberta', 'vencida'])
        .orderBy('dthPrazo')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => PendenciaMotorista.fromMap(d.id, d.data())).toList());
  }

  /// Motorista devolve valor — empresa deve confirmar depois
  static Future<void> resolverPendencia({
    required String pendenciaId,
    required int numSeq,
    required double vlrDevolvido,
    required String adminOrEmpresaName,
  }) async {
    final batch = _db.batch();

    // Fecha a pendência
    batch.update(_db.collection(_pendCol).doc(pendenciaId), {
      'status': 'resolvida',
      'vlrDevolvido': vlrDevolvido,
      'dthResolucao': FieldValue.serverTimestamp(),
    });

    // Atualiza status do CoD
    batch.update(_db.collection(_codCol).doc('$numSeq'), {
      'status': CodStatus.pendencyResolved.key,
    });

    await batch.commit();
  }

  /// Verifica e vence pendências com prazo expirado (chamado ao abrir o app)
  static Future<int> checkExpiredPendencies(int codMotorista) async {
    final snap = await _db
        .collection(_pendCol)
        .where('codMotorista', isEqualTo: codMotorista)
        .where('status', isEqualTo: 'aberta')
        .get();

    int expired = 0;
    final now = DateTime.now();
    final batch = _db.batch();

    for (final doc in snap.docs) {
      final pend = PendenciaMotorista.fromMap(doc.id, doc.data());
      if (now.isAfter(pend.dthPrazo)) {
        batch.update(doc.reference, {'status': 'vencida'});
        expired++;
      }
    }

    if (expired > 0) {
      await batch.commit();
      // Bloqueia motorista no sistema
      await EmpresaPaymentService.blockEmpresa(
        codMotorista,
        'Pendência de cobrança na entrega vencida',
        'Sistema automático',
      );
    }

    return expired;
  }

  /// Conta pendências abertas de um motorista (para badge na home)
  static Future<int> countPendenciasAbertas(int codMotorista) async {
    final snap = await _db
        .collection(_pendCol)
        .where('codMotorista', isEqualTo: codMotorista)
        .where('status', whereIn: ['aberta', 'vencida'])
        .count()
        .get();
    return snap.count ?? 0;
  }
}
