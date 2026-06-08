import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de corrida ao vivo (Firestore collection: live_rides)
class LiveRideModel {
  final String rideId;
  final int status;
  // 0=buscando_motorista, 1=motorista_a_caminho, 2=motorista_no_local,
  // 3=em_entrega, 4=entregue, 5=cancelada

  final String empresaId;
  final String empresaName;
  final String pickupName; // nome da loja/empresa
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String deliveryAddress;
  final String deliveryClientName;
  final double deliveryLat;
  final double deliveryLng;
  final String? notes;
  final String paymentType; // pix | cartao
  final double price;
  final double distanceKm;
  final DateTime createdAt;

  // Driver (null até ser aceita)
  final int? numSeq; // PostgreSQL primary key for syncing

  // Driver (null até ser aceita)
  final String? motoristaId;
  final String? motoristaName;
  final double? motoristaLat;
  final double? motoristaLng;

  // Timestamps de progresso
  final DateTime? acceptedAt;
  final DateTime? arrivedAtPickupAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;

  const LiveRideModel({
    required this.rideId,
    required this.status,
    required this.empresaId,
    required this.empresaName,
    required this.pickupName,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.deliveryAddress,
    required this.deliveryClientName,
    required this.deliveryLat,
    required this.deliveryLng,
    this.notes,
    required this.paymentType,
    required this.price,
    required this.distanceKm,
    required this.createdAt,
    this.numSeq,
    this.motoristaId,
    this.motoristaName,
    this.motoristaLat,
    this.motoristaLng,
    this.acceptedAt,
    this.arrivedAtPickupAt,
    this.pickedUpAt,
    this.deliveredAt,
  });

  factory LiveRideModel.fromMap(String id, Map<String, dynamic> map) {
    return LiveRideModel(
      rideId: id,
      status: (map['status'] as int?) ?? 0,
      empresaId: map['empresaId'] as String? ?? '',
      empresaName: map['empresaName'] as String? ?? '',
      pickupName: map['pickupName'] as String? ?? '',
      pickupAddress: map['pickupAddress'] as String? ?? '',
      pickupLat: (map['pickupLat'] as num?)?.toDouble() ?? 0.0,
      pickupLng: (map['pickupLng'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      deliveryClientName: map['deliveryClientName'] as String? ?? '',
      deliveryLat: (map['deliveryLat'] as num?)?.toDouble() ?? 0.0,
      deliveryLng: (map['deliveryLng'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      paymentType: map['paymentType'] as String? ?? 'pix',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numSeq: (map['numSeq'] as num?)?.toInt(),
      motoristaId: map['motoristaId'] as String?,
      motoristaName: map['motoristaName'] as String?,
      motoristaLat: (map['motoristaLat'] as num?)?.toDouble(),
      motoristaLng: (map['motoristaLng'] as num?)?.toDouble(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      arrivedAtPickupAt: (map['arrivedAtPickupAt'] as Timestamp?)?.toDate(),
      pickedUpAt: (map['pickedUpAt'] as Timestamp?)?.toDate(),
      deliveredAt: (map['deliveredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
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
      };

  LiveRideModel copyWith({
    int? status,
    String? motoristaId,
    String? motoristaName,
    double? motoristaLat,
    double? motoristaLng,
    DateTime? acceptedAt,
    DateTime? arrivedAtPickupAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) =>
      LiveRideModel(
        rideId: rideId,
        status: status ?? this.status,
        empresaId: empresaId,
        empresaName: empresaName,
        pickupName: pickupName,
        pickupAddress: pickupAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        deliveryAddress: deliveryAddress,
        deliveryClientName: deliveryClientName,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
        notes: notes,
        paymentType: paymentType,
        price: price,
        distanceKm: distanceKm,
        createdAt: createdAt,
        motoristaId: motoristaId ?? this.motoristaId,
        motoristaName: motoristaName ?? this.motoristaName,
        motoristaLat: motoristaLat ?? this.motoristaLat,
        motoristaLng: motoristaLng ?? this.motoristaLng,
        acceptedAt: acceptedAt ?? this.acceptedAt,
        arrivedAtPickupAt: arrivedAtPickupAt ?? this.arrivedAtPickupAt,
        pickedUpAt: pickedUpAt ?? this.pickedUpAt,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Buscando Motoboy';
      case 1:
        return 'A Caminho';
      case 2:
        return 'No Local';
      case 3:
        return 'Em Entrega';
      case 4:
        return 'Entregue!';
      case 5:
        return 'Cancelada';
      default:
        return 'Aguardando';
    }
  }

  bool get isActive => status >= 0 && status <= 3;
  bool get isCompleted => status == 4;
  bool get isCancelled => status == 5;
}
