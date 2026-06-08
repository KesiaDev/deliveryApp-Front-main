import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/live_ride_model.dart';

class LiveRideService {
  static const _col = 'live_rides';
  static final _db = FirebaseFirestore.instance;

  // Cria uma nova corrida — retorna o rideId gerado
  static Future<String> createRide({
    required String empresaId,
    required String empresaName,
    required String pickupName,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String deliveryAddress,
    required String deliveryClientName,
    required double deliveryLat,
    required double deliveryLng,
    String? notes,
    required String paymentType,
    required double price,
    required double distanceKm,
    int? numSeq,
  }) async {
    final ref = _db.collection(_col).doc();
    await ref.set({
      'status': 0,
      if (numSeq != null) 'numSeq': numSeq,
      'empresaId': empresaId,
      'empresaName': empresaName,
      'pickupName': pickupName,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'deliveryAddress': deliveryAddress,
      'deliveryClientName': deliveryClientName,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'notes': notes,
      'paymentType': paymentType,
      'price': price,
      'distanceKm': distanceKm,
      'createdAt': FieldValue.serverTimestamp(),
      'motoristaId': null,
      'motoristaName': null,
      'motoristaLat': null,
      'motoristaLng': null,
    });
    return ref.id;
  }

  // Atualiza apenas o status (com timestamp automático por fase)
  static Future<void> updateStatus(String rideId, int status) async {
    final updates = <String, dynamic>{'status': status};
    switch (status) {
      case 1:
        updates['acceptedAt'] = FieldValue.serverTimestamp();
        break;
      case 2:
        updates['arrivedAtPickupAt'] = FieldValue.serverTimestamp();
        break;
      case 3:
        updates['pickedUpAt'] = FieldValue.serverTimestamp();
        break;
      case 4:
        updates['deliveredAt'] = FieldValue.serverTimestamp();
        break;
    }
    await _db.collection(_col).doc(rideId).update(updates);
  }

  // Atribui motorista à corrida (status → 1)
  static Future<void> assignDriver(
    String rideId,
    String motoristaId,
    String motoristaName,
    double lat,
    double lng,
  ) async {
    await _db.collection(_col).doc(rideId).update({
      'status': 1,
      'motoristaId': motoristaId,
      'motoristaName': motoristaName,
      'motoristaLat': lat,
      'motoristaLng': lng,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // Atualiza posição do motorista em tempo real
  static Future<void> updateDriverLocation(
      String rideId, double lat, double lng) async {
    await _db.collection(_col).doc(rideId).update({
      'motoristaLat': lat,
      'motoristaLng': lng,
    });
  }

  // Stream em tempo real de uma corrida específica
  static Stream<LiveRideModel?> listenToRide(String rideId) {
    return _db.collection(_col).doc(rideId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return LiveRideModel.fromMap(snap.id, snap.data()!);
    });
  }

  // Stream de corridas disponíveis (status=0) para motoristas
  // Sem orderBy para não exigir índice composto — ordena em memória
  static Stream<List<LiveRideModel>> listenToAvailableRides() {
    return _db
        .collection(_col)
        .where('status', isEqualTo: 0)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LiveRideModel.fromMap(d.id, d.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Stream de corridas ativas de uma empresa (status 0-3)
  static Stream<List<LiveRideModel>> listenToEmpresaRides(String empresaId) {
    return _db
        .collection(_col)
        .where('empresaId', isEqualTo: empresaId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LiveRideModel.fromMap(d.id, d.data()))
              .where((r) => r.status >= 0 && r.status <= 3)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Stream de TODAS as corridas ativas (para admin) — sem índice composto
  static Stream<List<LiveRideModel>> listenToActiveRides() {
    return _db
        .collection(_col)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => LiveRideModel.fromMap(d.id, d.data()))
              .where((r) => r.status >= 0 && r.status <= 3)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}
