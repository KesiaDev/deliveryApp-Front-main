/// Modelo de atualização de localização para rastreamento
class LocationUpdateModel {
  final String id;
  final String corridaId;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed; // km/h
  final double? heading; // graus (0-360)

  LocationUpdateModel({
    required this.id,
    required this.corridaId,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.heading,
  });

  factory LocationUpdateModel.fromJson(Map<String, dynamic> json) {
    return LocationUpdateModel(
      id: json['id'] ?? '',
      corridaId: json['corridaId'] ?? '',
      userId: json['userId'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading:
          json['heading'] != null ? (json['heading'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'corridaId': corridaId,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'speed': speed,
      'heading': heading,
    };
  }
}





