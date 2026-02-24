import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/location_update_model.dart';

/// Serviço de rastreamento integrado com Firebase Firestore
class TrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _trackingCollection = _firestore.collection('tracking');
  
  static StreamSubscription<Position>? _positionStream;
  static final List<Function(LocationUpdateModel)> _locationListeners = [];
  static String? _currentCorridaId;
  static String? _currentUserId;
  static bool _isTracking = false;

  /// Inicia o rastreamento de localização em foreground
  static Future<void> startTracking({
    required String corridaId,
    required String userId,
    Duration updateInterval = const Duration(seconds: 5),
  }) async {
    if (_isTracking) {
      await stopTracking();
    }

    _currentCorridaId = corridaId;
    _currentUserId = userId;
    _isTracking = true;

    // Verifica permissões
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização desabilitado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente');
    }

    // Configura stream de localização
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // metros
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _onLocationUpdate(position);
      },
      onError: (error) {
        print('Erro no rastreamento: $error');
      },
    );
  }

  /// Para o rastreamento
  static Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    
    // Marca como inativo no Firestore
    if (_currentCorridaId != null) {
      try {
        await _trackingCollection.doc(_currentCorridaId!).set({
          'isActive': false,
          'stoppedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Erro ao marcar rastreamento como inativo: $e');
      }
    }
    
    _currentCorridaId = null;
    _currentUserId = null;
  }

  /// Callback quando há atualização de localização
  static void _onLocationUpdate(Position position) async {
    if (_currentCorridaId == null || _currentUserId == null) return;

    final update = LocationUpdateModel(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      corridaId: _currentCorridaId!,
      userId: _currentUserId!,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      speed: position.speed,
      heading: position.heading,
    );

    // Salva no Firestore
    await _saveLocationToFirestore(update);

    // Notifica listeners locais
    for (var listener in _locationListeners) {
      listener(update);
    }
  }

  /// Salva localização no Firestore
  static Future<void> _saveLocationToFirestore(LocationUpdateModel update) async {
    try {
      // Estrutura: /tracking/{corridaId}/locations/{locationId}
      await _trackingCollection
          .doc(update.corridaId)
          .collection('locations')
          .add({
        'userId': update.userId,
        'latitude': update.latitude,
        'longitude': update.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'speed': update.speed,
        'heading': update.heading,
      });

      // Atualiza última posição conhecida na corrida
      await _trackingCollection.doc(update.corridaId).set({
        'corridaId': update.corridaId,
        'userId': update.userId,
        'lastLatitude': update.latitude,
        'lastLongitude': update.longitude,
        'lastUpdate': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar localização no Firestore: $e');
    }
  }

  /// Busca última localização conhecida do Firestore
  static Future<LocationUpdateModel?> getLastLocationFromFirestore(String corridaId) async {
    try {
      final doc = await _trackingCollection.doc(corridaId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return null;

      return LocationUpdateModel(
        id: 'last_firestore',
        corridaId: corridaId,
        userId: data['userId'] as String? ?? '',
        latitude: (data['lastLatitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['lastLongitude'] as num?)?.toDouble() ?? 0.0,
        timestamp: (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        speed: null,
        heading: null,
      );
    } catch (e) {
      debugPrint('Erro ao buscar última localização: $e');
      return null;
    }
  }

  /// Escuta atualizações de localização em tempo real do Firestore
  static StreamSubscription? listenToLocationUpdates(
    String corridaId,
    Function(LocationUpdateModel) onUpdate,
  ) {
    try {
      return _trackingCollection
          .doc(corridaId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return;

        final update = LocationUpdateModel(
          id: 'firestore_${snapshot.id}',
          corridaId: corridaId,
          userId: data['userId'] as String? ?? '',
          latitude: (data['lastLatitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (data['lastLongitude'] as num?)?.toDouble() ?? 0.0,
          timestamp: (data['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          speed: null,
          heading: null,
        );

        onUpdate(update);
      });
    } catch (e) {
      debugPrint('Erro ao escutar atualizações: $e');
      return null;
    }
  }

  /// Adiciona listener para atualizações de localização
  static void addLocationListener(Function(LocationUpdateModel) listener) {
    _locationListeners.add(listener);
  }

  /// Remove listener
  static void removeLocationListener(Function(LocationUpdateModel) listener) {
    _locationListeners.remove(listener);
  }

  /// Verifica se está rastreando
  static bool get isTracking => _isTracking;

  /// Obtém última posição conhecida
  static Future<LocationUpdateModel?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null || _currentCorridaId == null || _currentUserId == null) {
        return null;
      }

      return LocationUpdateModel(
        id: 'last_known',
        corridaId: _currentCorridaId!,
        userId: _currentUserId!,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        speed: position.speed,
        heading: position.heading,
      );
    } catch (e) {
      return null;
    }
  }

  /// Limpa listeners (útil para testes)
  static void clear() {
    _locationListeners.clear();
  }
}





